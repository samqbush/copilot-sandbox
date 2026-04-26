#!/bin/bash
set -e

# Generate SSH host keys on first run (not baked into image)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Copy authorized keys if mounted
if [ -f /tmp/authorized_keys ]; then
    cp /tmp/authorized_keys /home/dev/.ssh/authorized_keys
    chown dev:dev /home/dev/.ssh/authorized_keys
    chmod 600 /home/dev/.ssh/authorized_keys
    echo "✓ SSH keys configured"
fi

echo "✓ SSH server starting on port 22"
echo "  Connect with: ssh -p 2222 dev@localhost"

# Run sshd in foreground
exec /usr/sbin/sshd -D
