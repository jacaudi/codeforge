# codeforge

Remote development container with [Claude Code](https://claude.com/product/claude-code) pre-installed. Multi-arch (amd64 + arm64), SSH-ready.

## Features

- **Claude Code** pre-installed and ready to use
- **Multi-arch** native amd64 and arm64 images
- **SSH access** with public key authentication (password auth disabled)
- **Dotfile management** with chezmoi
- **Shell** zsh with oh-my-zsh, plus bash
- **Editors** neovim, nano
- **Git tooling** git, GitHub CLI, GitLab CLI
- **Terminal multiplexers** tmux, screen
- **Productivity** nightshift, td
- **Data tools** jq, yq
- **Non-root** `coder` user with passwordless sudo

## Quick Start

```bash
docker run -d \
  -p 2222:22 \
  -e CLAUDE_OAUTH_TOKEN="your-token" \
  -v ~/.ssh/id_ed25519.pub:/etc/ssh-keys/authorized_keys:ro \
  ghcr.io/jacaudi/codeforge:latest

ssh -p 2222 coder@localhost
```

Or access without SSH:

```bash
docker exec -it -u coder <container> zsh
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `CLAUDE_OAUTH_TOKEN` | Claude Code authentication |

| Volume Mount | Purpose |
|-------------|---------|
| `/etc/ssh-keys/authorized_keys` | SSH public key (required for SSH access) |
| `/etc/ssh` | Persist host keys across restarts |

## Dotfiles

chezmoi is included for importing your dotfiles on first login. Bring your shell config, neovim setup, Claude Code settings (`CLAUDE.md`, `~/.claude/`), git config, and more from a dotfiles repo:

```bash
chezmoi init --apply <github-username>
```

This is useful for:
- Claude Code customizations (`CLAUDE.md`, settings, MCP servers)
- Neovim configuration
- zsh/bash aliases and functions
- Git configuration

See [docs/README.md](docs/README.md) for detailed configuration, building from source, and CI/CD information.
