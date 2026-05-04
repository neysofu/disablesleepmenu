#!/bin/bash
# Install sudoers rule to allow pmset disablesleep without password

set -e

SUDOERS_FILE="/etc/sudoers.d/disablesleep"
USERNAME=$(id -un)
TEMP_FILE=$(mktemp "${TMPDIR:-/tmp}/disablesleep-sudoers.XXXXXX")

cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

if [[ ! "$USERNAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Error: username '$USERNAME' contains characters this installer will not write to sudoers."
    exit 1
fi

echo "Installing sudoers rule for $USERNAME..."
echo "This will allow 'pmset disablesleep' to run without a password prompt."
echo ""

# Create and validate the sudoers rule before installing it.
cat > "$TEMP_FILE" << EOF
# Allow $USERNAME to toggle sleep without password
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/pmset disablesleep 0
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/pmset disablesleep 1
EOF

# Validate the sudoers file before copying it into /etc/sudoers.d.
if sudo visudo -c -f "$TEMP_FILE"; then
    sudo install -o root -g wheel -m 0440 "$TEMP_FILE" "$SUDOERS_FILE"
    echo ""
    echo "✓ Installed successfully!"
    echo "  You can now run 'sudo pmset disablesleep 1' without a password."
else
    echo "Error: Invalid sudoers syntax. Nothing was installed."
    exit 1
fi
