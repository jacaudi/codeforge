# claude-container - Detailed Documentation

## SSH Keys

Mount your public key to `/etc/ssh-keys/authorized_keys`:

```bash
-v ~/.ssh/id_ed25519.pub:/etc/ssh-keys/authorized_keys:ro
```

SSH is hardened:
- Public key authentication only
- Password and keyboard-interactive authentication disabled
- Root login disabled
- Only `dev` user allowed

## Claude Code Authentication

Pass your OAuth token as an environment variable:

```bash
-e CLAUDE_OAUTH_TOKEN="your-token"
```

The token is written to `/home/dev/.zshenv` with `600` permissions so it's available in SSH sessions.

## User Setup

- **Username:** `dev` (UID 1000)
- **Shell:** zsh with oh-my-zsh
- **Sudo:** passwordless via wheel group
- **Home:** `/home/dev`

## Persistent Host Keys

Mount a volume to `/etc/ssh` to persist SSH host keys across container restarts:

```bash
-v ssh-host-keys:/etc/ssh
```

## Building Locally

```bash
docker build -t claude-container .
```

Override the Claude Code version at build time:

```bash
docker build --build-arg CLAUDE_CODE_VERSION=2.1.38 -t claude-container .
```

## Architecture

Multi-arch images are published for `linux/amd64` and `linux/arm64`. The correct Claude Code musl binary is selected automatically at build time via `TARGETARCH`.

## CI/CD

Pushes to `main` trigger: lint, multi-arch build, image scan (Trivy), image validation, and semantic release.

Tags trigger: build and scan.

PRs trigger: lint, multi-arch build, scan, and validation.
