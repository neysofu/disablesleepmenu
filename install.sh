#!/bin/bash
# Install sudoers rule to allow pmset disablesleep without password

set -e

SUDOERS_FILE="/etc/sudoers.d/disablesleep"
USERNAME=$(whoami)

echo "Installing sudoers rule for $USERNAME..."
echo "This will allow 'pmset disablesleep' to run without a password prompt."
echo ""

# Create the sudoers rule
sudo tee "$SUDOERS_FILE" > /dev/null << EOF
# Allow $USERNAME to toggle sleep without password
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/pmset disablesleep 0
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/pmset disablesleep 1
EOF

# Set correct permissions
sudo chmod 0440 "$SUDOERS_FILE"

# Validate the sudoers file
if sudo visudo -c -f "$SUDOERS_FILE"; then
    echo ""
    echo "✓ Installed successfully!"
    echo "  You can now run 'sudo pmset disablesleep 1' without a password."
else
    echo "Error: Invalid sudoers syntax. Removing file."
    sudo rm -f "$SUDOERS_FILE"
    exit 1
fi
