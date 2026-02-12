#!/bin/sh
set -euo pipefail

# Initialize /etc/ssh if volume mount wiped sshd_config
if [ ! -f /etc/ssh/sshd_config ]; then
    echo "Initializing /etc/ssh from defaults..."
    cp /opt/codeforge/defaults/etc/ssh/sshd_config /etc/ssh/sshd_config
fi

# Generate SSH host keys if missing (supports persistent volumes)
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -A
fi

# Initialize /home/coder if volume mount wiped home directory
if [ ! -d /home/coder/.oh-my-zsh ]; then
    echo "Initializing /home/coder from defaults..."
    cp -a /opt/codeforge/defaults/home-coder/. /home/coder/
    chown -R coder:coder /home/coder
fi

# Copy SSH public keys from mount
if [ -f /etc/ssh-keys/authorized_keys ]; then
    cp /etc/ssh-keys/authorized_keys /home/coder/.ssh/authorized_keys
    chmod 600 /home/coder/.ssh/authorized_keys
    chown coder:coder /home/coder/.ssh/authorized_keys
else
    echo "WARNING: No SSH keys found at /etc/ssh-keys/authorized_keys"
fi

# Write CLAUDE_CODE_OAUTH_TOKEN to coder user's environment if set
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    printf 'export CLAUDE_CODE_OAUTH_TOKEN="%s"\n' "${CLAUDE_CODE_OAUTH_TOKEN}" > /home/coder/.zshenv
    chown coder:coder /home/coder/.zshenv
    chmod 600 /home/coder/.zshenv
fi

# Set hasCompletedOnboarding for headless Claude Code sessions
CLAUDE_JSON="/home/coder/.claude.json"
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    if [ -f "$CLAUDE_JSON" ]; then
        jq '. + {"hasCompletedOnboarding": true}' "$CLAUDE_JSON" > "${CLAUDE_JSON}.tmp" \
            && mv "${CLAUDE_JSON}.tmp" "$CLAUDE_JSON"
    else
        echo '{"hasCompletedOnboarding": true}' > "$CLAUDE_JSON"
    fi
    chown coder:coder "$CLAUDE_JSON"
    chmod 600 "$CLAUDE_JSON"
fi

# Start sshd in foreground
exec /usr/sbin/sshd -D -e
