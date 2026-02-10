#!/bin/sh
set -euo pipefail

# Generate SSH host keys if missing (supports persistent volumes)
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -A
fi

# Copy SSH public keys from mount
if [ -f /etc/ssh-keys/authorized_keys ]; then
    cp /etc/ssh-keys/authorized_keys /home/dev/.ssh/authorized_keys
    chmod 600 /home/dev/.ssh/authorized_keys
    chown dev:dev /home/dev/.ssh/authorized_keys
else
    echo "WARNING: No SSH keys found at /etc/ssh-keys/authorized_keys"
fi

# Write CLAUDE_OAUTH_TOKEN to dev user's environment if set
if [ -n "${CLAUDE_OAUTH_TOKEN:-}" ]; then
    echo "export CLAUDE_OAUTH_TOKEN=\"${CLAUDE_OAUTH_TOKEN}\"" > /home/dev/.zshenv
    chown dev:dev /home/dev/.zshenv
    chmod 600 /home/dev/.zshenv
fi

# Start sshd in foreground
exec /usr/sbin/sshd -D -e
