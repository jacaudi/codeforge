FROM public.ecr.aws/docker/library/alpine:3.23 AS go-builder
ARG NIGHTSHIFT_VERSION=0.3.1
ARG TD_VERSION=0.34.0
RUN apk add --no-cache go
RUN GOBIN=/go/bin go install github.com/marcus/nightshift/cmd/nightshift@v${NIGHTSHIFT_VERSION}
RUN GOBIN=/go/bin go install github.com/marcus/td@v${TD_VERSION}

FROM public.ecr.aws/docker/library/alpine:3.23

# --- Pinned versions ---
ARG CLAUDE_CODE_VERSION=2.1.39
ARG NIGHTSHIFT_VERSION=0.3.1
ARG TD_VERSION=0.34.0

# --- System packages ---
RUN apk add --no-cache \
        openssh \
        neovim \
        nano \
        zsh \
        git \
        curl \
        sudo \
        bash \
        shadow \
        libgcc \
        libstdc++

# --- CLI tools ---
RUN apk add --no-cache \
        chezmoi \
        github-cli \
        glab \
        yq \
        jq \
        tmux \
        screen

# --- Create coder user ---
RUN addgroup coder \
    && adduser -D -s /bin/zsh -G coder coder \
    && addgroup coder wheel \
    && sed -i 's/^coder:!/coder:*/' /etc/shadow \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# --- oh-my-zsh ---
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /home/coder/.oh-my-zsh \
    && cp /home/coder/.oh-my-zsh/templates/zshrc.zsh-template /home/coder/.zshrc \
    && chown -R coder:coder /home/coder/.oh-my-zsh /home/coder/.zshrc

# --- Claude Code (direct binary, pinned version, musl for Alpine) ---
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
        amd64) ARCH_PATH="linux-x64-musl" ;; \
        arm64) ARCH_PATH="linux-arm64-musl" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -fsSL --retry 3 --retry-delay 5 \
        "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${CLAUDE_CODE_VERSION}/${ARCH_PATH}/claude" \
        -o /usr/local/bin/claude \
    && chmod +x /usr/local/bin/claude

# --- Go binaries ---
COPY --from=go-builder /go/bin/nightshift /usr/local/bin/nightshift
COPY --from=go-builder /go/bin/td /usr/local/bin/td

# --- SSH configuration ---
RUN mkdir -p /home/coder/.ssh \
    && chmod 700 /home/coder/.ssh \
    && chown coder:coder /home/coder/.ssh

RUN sed -i \
        -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
        -e 's/^#PasswordAuthentication yes/PasswordAuthentication no/' \
        -e 's/^#PermitRootLogin .*/PermitRootLogin no/' \
        -e 's/^#KbdInteractiveAuthentication yes/KbdInteractiveAuthentication no/' \
        /etc/ssh/sshd_config \
    && echo 'AllowUsers coder' >> /etc/ssh/sshd_config \
    && echo 'AuthenticationMethods publickey' >> /etc/ssh/sshd_config \
    && echo 'PrintMotd no' >> /etc/ssh/sshd_config

# --- tmux auto-attach on SSH login ---
COPY src/zprofile /etc/zsh/zprofile

# --- Backup defaults for volume mount initialization ---
RUN mkdir -p /opt/codeforge/defaults/etc/ssh \
    && cp /etc/ssh/sshd_config /opt/codeforge/defaults/etc/ssh/sshd_config \
    && cp -a /home/coder /opt/codeforge/defaults/home-coder

# --- MOTD ---
RUN NVIM_VER=$(nvim --version | head -1 | awk '{print $2}') \
    && TMUX_VER=$(tmux -V | awk '{print $2}') \
    && CHEZMOI_VER=$(chezmoi --version | awk '{print $3}' | sed 's/,//') \
    && printf '%s\n' \
    '' \
    '   ██████╗ ██████╗ ██████╗ ███████╗███████╗ ██████╗ ██████╗  ██████╗ ███████╗' \
    '  ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝' \
    '  ██║     ██║   ██║██║  ██║█████╗  █████╗  ██║   ██║██████╔╝██║  ███╗█████╗  ' \
    '  ██║     ██║   ██║██║  ██║██╔══╝  ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  ' \
    '  ╚██████╗╚██████╔╝██████╔╝███████╗██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗' \
    '   ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝' \
    '' \
    '  Remote Development Container' \
    "  claude ${CLAUDE_CODE_VERSION}  neovim ${NVIM_VER}  tmux ${TMUX_VER}  chezmoi ${CHEZMOI_VER}" \
    '' \
    '  tmux: Ctrl-b d detach | Ctrl-b c new window | Ctrl-b n/p next/prev window' \
    '' > /etc/motd

# --- Entrypoint ---
COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
