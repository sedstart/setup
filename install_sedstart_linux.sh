#!/usr/bin/env bash

set -e

BASE_URL="http://cli.sedstart.com/latest"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="sedstart"

OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$OS" != "Linux" ]]; then
  echo "❌ This script is for Linux only."
  exit 1
fi

if [[ "$ARCH" == "x86_64" ]]; then
  FILE="cli_linux_amd64_v1/sedstart"
elif [[ "$ARCH" == "aarch64" ]]; then
  FILE="cli_linux_arm64_v8.0/sedstart"
elif [[ "$ARCH" == "i386" || "$ARCH" == "i686" ]]; then
  FILE="cli_linux_386_sse2/sedstart"
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

echo "✅ Installed successfully!"
echo "Run: sedstart"
