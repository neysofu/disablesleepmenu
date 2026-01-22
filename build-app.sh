#!/bin/bash
# Build DisableSleepMenu.app bundle

set -e

APP_NAME="DisableSleepMenu"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building $APP_NAME..."

# Build release binary
swift build -c release

echo "Creating app bundle..."

# Clean previous build
rm -rf "$APP_DIR"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/$APP_NAME" "$MACOS_DIR/"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS_DIR/"

echo "✓ Built $APP_DIR"
echo ""
echo "To install to Applications:"
echo "  cp -r $APP_DIR /Applications/"
echo ""
echo "To run:"
echo "  open $APP_DIR"
