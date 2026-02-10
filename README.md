# claude-container

Minimal remote development container with [Claude Code](https://claude.com/product/claude-code) pre-installed. Alpine-based, multi-arch (amd64 + arm64), SSH-ready.

## What's Included

| Category | Tools |
|----------|-------|
| AI | Claude Code |
| Editors | neovim, nano |
| Shell | zsh, oh-my-zsh, bash |
| VCS | git, gh (GitHub CLI), glab (GitLab CLI) |
| Utilities | curl, jq, yq, chezmoi, sudo |

## Quick Start

```bash
# Pull the image
docker pull ghcr.io/jacaudi/claude-container:latest

# Run with SSH access
docker run -d \
  -p 2222:22 \
  -e CLAUDE_OAUTH_TOKEN="your-token" \
  -v ~/.ssh/id_ed25519.pub:/etc/ssh-keys/authorized_keys:ro \
  ghcr.io/jacaudi/claude-container:latest

# Connect
ssh -p 2222 dev@localhost
```

## Configuration

### SSH Keys

Mount your public key to `/etc/ssh-keys/authorized_keys`:

```bash
-v ~/.ssh/id_ed25519.pub:/etc/ssh-keys/authorized_keys:ro
```

Password authentication is disabled. Only public key auth is accepted.

### Claude Code Authentication

Pass your OAuth token as an environment variable:

```bash
-e CLAUDE_OAUTH_TOKEN="your-token"
```

The token is written to `/home/dev/.zshenv` with `600` permissions so it's available in SSH sessions.

### Docker Exec

You can also access the container without SSH:

```bash
docker exec -it -u dev <container> zsh
```

## User Setup

- **Username:** `dev` (UID 1000)
- **Shell:** zsh with oh-my-zsh
- **Sudo:** passwordless via wheel group
- **Home:** `/home/dev`

## SSH Hardening

- Public key authentication only
- Password and keyboard-interactive authentication disabled
- Root login disabled
- Only `dev` user allowed

## Building Locally

```bash
docker build -t claude-container .
```

Override the Claude Code version at build time:

```bash
docker build --build-arg CLAUDE_CODE_VERSION=2.1.38 -t claude-container .
```

## Persistent Host Keys

Mount a volume to `/etc/ssh` to persist SSH host keys across container restarts:

```bash
-v ssh-host-keys:/etc/ssh
```

## Architecture

Multi-arch images are published for `linux/amd64` and `linux/arm64`. The correct Claude Code binary is selected automatically at build time.

## CI/CD

Pushes to `main` trigger: lint, multi-arch build, image scan (Trivy), image validation, and semantic release. Tags trigger: build and scan.
