#!/usr/bin/env bash

set -e

BASE_URL="http://cli.sedstart.com/latest"
BINARY_NAME="sedstart"
INSTALL_DIR="/usr/local/bin"

OS="$(uname -s)"
ARCH="$(uname -m)"

echo "🔎 Detecting platform..."

# Detect OS
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="darwin"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

# Detect ARCH
case "$ARCH" in
    x86_64)
        if [[ "$PLATFORM" == "darwin" ]]; then
            FILE="cli_darwin_amd64_v1/sedstart"
        else
            FILE="cli_linux_amd64_v1/sedstart"
        fi
        ;;
    arm64|aarch64)
        if [[ "$PLATFORM" == "darwin" ]]; then
            FILE="cli_darwin_arm64_v8.0/sedstart"
        else
            FILE="cli_linux_arm64_v8.0/sedstart"
        fi
        ;;
    i386|i686)
        FILE="cli_linux_386_sse2/sedstart"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

URL="$BASE_URL/$FILE"

echo "⬇️ Downloading $URL..."
curl -fsSL "$URL" -o "$BINARY_NAME"

echo "🔐 Making executable..."
chmod +x "$BINARY_NAME"

echo "📦 Installing to $INSTALL_DIR (may require sudo)..."
sudo mv "$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"

# macOS quarantine fix
if [[ "$PLATFORM" == "darwin" ]]; then
    echo "🛡 Removing macOS quarantine flag..."
    sudo xattr -d com.apple.quarantine "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true
fi

echo ""
echo "✅ sedstart installed successfully!"
echo "Run: sedstart --help"
