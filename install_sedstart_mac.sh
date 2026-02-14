#!/usr/bin/env bash

set -e

BASE_URL="http://cli.sedstart.com/latest"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="sedstart"

OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$OS" != "Darwin" ]]; then
  echo "❌ This script is for macOS only."
  exit 1
fi

if [[ "$ARCH" == "x86_64" ]]; then
  FILE="cli_darwin_amd64_v1/sedstart"
elif [[ "$ARCH" == "arm64" ]]; then
  FILE="cli_darwin_arm64_v8.0/sedstart"
else
  echo "❌ Unsupported architecture: $ARCH"
  exit 1
fi

URL="$BASE_URL/$FILE"

echo "⬇️ Downloading $URL..."
curl -L "$URL" -o "$BINARY_NAME"

echo "🔐 Making executable..."
chmod +x "$BINARY_NAME"

echo "📦 Installing to $INSTALL_DIR (may require sudo)..."
sudo mv "$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"

echo "🛡 Removing macOS quarantine flag..."
sudo xattr -d com.apple.quarantine "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true

echo "✅ Installed successfully!"
echo "Run: sedstart"
