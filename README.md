# codeforge

Remote development container with [Claude Code](https://claude.com/product/claude-code) pre-installed. Multi-arch (amd64 + arm64), SSH-ready, with automatic tmux session management.

## Features

| Category | Details |
|----------|---------|
| Claude Code | Pre-installed and ready to use |
| Multi-arch | Native amd64 and arm64 images |
| SSH access | Public key authentication (password auth disabled) |
| Terminal multiplexers | tmux (auto-attach on login), screen |
| Dotfile management | chezmoi |
| Shell | zsh with oh-my-zsh, bash |
| Editors | neovim, nano |
| Git tooling | git, GitHub CLI, GitLab CLI |
| Productivity | nightshift, td |
| Data tools | jq, yq |
| Non-root | `coder` user with passwordless sudo |

## Quick Start

```bash
docker run -d \
  -p 2222:22 \
  -e CLAUDE_CODE_OAUTH_TOKEN="your-token" \
  -v ~/.ssh/id_ed25519.pub:/etc/ssh-keys/authorized_keys:ro \
  ghcr.io/jacaudi/codeforge:latest

ssh -p 2222 coder@localhost
```

SSH sessions automatically attach to a tmux session. On first connect, a new session named `main` is created. Subsequent connections prompt to attach the shared session or start a new one.

Or access without SSH:

```bash
docker exec -it -u coder <container> zsh
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code authentication |

| Volume Mount | Purpose |
|-------------|---------|
| `/etc/ssh-keys/authorized_keys` | SSH public key (required for SSH access) |
| `/etc/ssh` | Persist host keys and SSH config across restarts |
| `/home/coder` | Persist home directory across restarts |

When a volume is mounted empty, the entrypoint automatically restores default files (`sshd_config`, `.ssh/`, oh-my-zsh, `.zshrc`). Existing data on subsequent restarts is preserved.

## Build Args

| Arg | Default | Purpose |
|-----|---------|---------|
| `CLAUDE_CODE_VERSION` | `2.1.39` | Claude Code binary version |
| `NIGHTSHIFT_VERSION` | `0.3.1` | nightshift version |
| `TD_VERSION` | `0.34.0` | td version |

## Dotfiles

chezmoi is included for importing your dotfiles on first login:

```bash
chezmoi init --apply <github-username>
```

This is useful for Claude Code settings (`CLAUDE.md`, `~/.claude/`), neovim config, shell aliases, and git config.

See [docs/README.md](docs/README.md) for detailed configuration, building from source, and CI/CD information.
