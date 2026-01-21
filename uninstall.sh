#!/bin/bash
# Remove sudoers rule for pmset disablesleep

set -e

SUDOERS_FILE="/etc/sudoers.d/disablesleep"

if [ -f "$SUDOERS_FILE" ]; then
    echo "Removing sudoers rule..."
    sudo rm -f "$SUDOERS_FILE"
    echo "✓ Removed successfully!"
else
    echo "No sudoers rule found at $SUDOERS_FILE"
fi
