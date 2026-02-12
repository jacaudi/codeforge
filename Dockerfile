FROM public.ecr.aws/docker/library/alpine:3.23 AS go-builder
RUN apk add --no-cache go
RUN GOBIN=/go/bin go install github.com/marcus/nightshift/cmd/nightshift@v0.3.1
RUN GOBIN=/go/bin go install github.com/marcus/td@v0.34.0

FROM public.ecr.aws/docker/library/alpine:3.23

# --- Pinned versions ---
ARG CLAUDE_CODE_VERSION=2.1.38

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
    && echo 'AuthenticationMethods publickey' >> /etc/ssh/sshd_config

# --- Entrypoint ---
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
