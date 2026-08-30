#!/usr/bin/env bash

set -e

DEFAULT_BASE_URL="http://cli.sedstart.com/latest"
BASE_URL="${BASE_URL:-$DEFAULT_BASE_URL}"
BINARY_NAME="sedstart"
INSTALL_DIR="/usr/local/bin"

# Chrome Web Store ID of the published sedstart-recorder extension (used for
# both QA and prod - see sedstart-fe's env.qa/env.prod NEXT_PUBLIC_EXTENSION_ID).
# Override with --extension-id for a dev/unpacked build's own id.
DEFAULT_EXTENSION_ID="ljijoleacnolmdmihndjdmfkfbdpkibf"
EXTENSION_ID="${EXTENSION_ID:-$DEFAULT_EXTENSION_ID}"
HOST_NAME="com.sedstart.cli"
SKIP_NATIVE_HOST=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        --extension-id)
            EXTENSION_ID="$2"
            shift 2
            ;;
        --skip-native-host)
            SKIP_NATIVE_HOST=1
            shift
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

# ---------------------------------------------------------------------------
# Chrome Native Messaging host registration
#
# Lets the sedstart-recorder extension launch this CLI directly via
# chrome.runtime.connectNative() for local runs (see sedstart-be:
# cmd/sedstart/cmd/native_messaging.go and sedstart-extension:
# background/recording/nativeHost.ts). Native messaging hosts are
# per-user, per-machine, per-browser installs with no Web Store
# equivalent, so every Chromium-based browser actually installed on this
# machine needs its own manifest - unlike register-native-host.sh (which
# targets one browser per invocation via -b), this registers all of them
# in one pass, since an end-user installer has no reason to ask which
# browser they use.
# ---------------------------------------------------------------------------

register_native_messaging_host() {
    local target_dir="$1"
    local browser_label="$2"
    local manifest_path="$target_dir/$HOST_NAME.json"

    mkdir -p "$target_dir"
    cat > "$manifest_path" <<JSON
{
  "name": "$HOST_NAME",
  "description": "Sedstart local runner native messaging host",
  "path": "$INSTALL_DIR/$BINARY_NAME",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://$EXTENSION_ID/"
  ]
}
JSON
    echo "  ✔ $browser_label ($manifest_path)"
}

register_native_messaging_hosts() {
    echo ""
    echo "🔌 Registering Chrome Native Messaging host for installed browsers..."

    local any_found=0

    if [[ "$PLATFORM" == "darwin" ]]; then
        local base_dir="$HOME/Library/Application Support"
        # label:AppBundleName:NativeMessagingHosts subdir, one per browser we
        # know how to detect - both the per-user (~/Applications) and
        # system-wide (/Applications) install locations count as "installed".
        local browsers=(
            "Google Chrome:Google Chrome.app:Google/Chrome"
            "Chromium:Chromium.app:Chromium"
            "Microsoft Edge:Microsoft Edge.app:Microsoft Edge"
            "Brave Browser:Brave Browser.app:BraveSoftware/Brave-Browser"
        )
        local entry label app_name subdir
        for entry in "${browsers[@]}"; do
            IFS=':' read -r label app_name subdir <<< "$entry"
            if [[ -d "/Applications/$app_name" || -d "$HOME/Applications/$app_name" ]]; then
                any_found=1
                register_native_messaging_host "$base_dir/$subdir/NativeMessagingHosts" "$label"
            fi
        done
    elif [[ "$PLATFORM" == "linux" ]]; then
        local base_dir="$HOME/.config"
        # label:binary-names-to-check(space separated):NativeMessagingHosts subdir
        local browsers=(
            "Google Chrome:google-chrome google-chrome-stable:google-chrome"
            "Chromium:chromium chromium-browser:chromium"
            "Microsoft Edge:microsoft-edge microsoft-edge-stable:microsoft-edge"
            "Brave Browser:brave-browser brave:BraveSoftware/Brave-Browser"
        )
        local entry label bins subdir bin found
        for entry in "${browsers[@]}"; do
            IFS=':' read -r label bins subdir <<< "$entry"
            found=0
            for bin in $bins; do
                if command -v "$bin" >/dev/null 2>&1; then
                    found=1
                    break
                fi
            done
            if [[ "$found" -eq 1 ]]; then
                any_found=1
                register_native_messaging_host "$base_dir/$subdir/NativeMessagingHosts" "$label"
            fi
        done
    fi

    if [[ "$any_found" -eq 0 ]]; then
        echo "  (no supported Chromium-based browser found - skipped)"
    else
        echo "  Allowed origin: chrome-extension://$EXTENSION_ID/"
    fi
}

if [[ "$SKIP_NATIVE_HOST" -eq 0 ]]; then
    register_native_messaging_hosts
fi
