#!/usr/bin/env bash

set -e

DEFAULT_BASE_URL="http://cli.sedstart.com/latest"
BASE_URL="${BASE_URL:-$DEFAULT_BASE_URL}"
BINARY_NAME="sedstart"
INSTALL_DIR="/usr/local/bin"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🌍 Using base URL: $BASE_URL"
echo "🔎 Detecting platform..."

OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="darwin"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

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

chmod +x "$BINARY_NAME"
sudo mv "$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"

if [[ "$PLATFORM" == "darwin" ]]; then
    sudo xattr -d com.apple.quarantine "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true
fi

echo ""
echo "✅ sedstart installed successfully!"
echo "Run: sedstart --help"
