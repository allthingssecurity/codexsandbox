#!/bin/bash
# Codex Portable Setup for macOS/Linux
# Downloads Node.js and Codex to a local folder - no admin needed!

set -e

INSTALL_DIR="$HOME/codex-env"
NODE_VERSION="22.15.0"

echo "======================================"
echo "  Codex Portable Environment Setup"
echo "======================================"
echo ""

# Detect platform
case "$(uname -s)" in
    Darwin)
        case "$(uname -m)" in
            arm64) PLATFORM="darwin-arm64" ;;
            x86_64) PLATFORM="darwin-x64" ;;
            *) echo "Unsupported Mac architecture"; exit 1 ;;
        esac
        ;;
    Linux)
        case "$(uname -m)" in
            aarch64) PLATFORM="linux-arm64" ;;
            x86_64) PLATFORM="linux-x64" ;;
            *) echo "Unsupported Linux architecture"; exit 1 ;;
        esac
        ;;
    *)
        echo "This script is for macOS/Linux. Use setup-windows.bat for Windows."
        exit 1
        ;;
esac

echo "Platform: $PLATFORM"
echo "Install directory: $INSTALL_DIR"
echo ""

# Create install directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download Node.js
echo "[1/4] Downloading Node.js v${NODE_VERSION}..."
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${PLATFORM}.tar.gz"
curl -L "$NODE_URL" -o node.tar.gz
tar -xzf node.tar.gz --strip-components=1
rm node.tar.gz

# Remove unnecessary files
rm -rf include share CHANGELOG.md README.md 2>/dev/null || true

# Fix npm wrapper to use local node
echo "[2/4] Configuring npm..."
cat > bin/npm << 'NPMWRAPPER'
#!/bin/sh
basedir=$(cd "$(dirname "$0")" && pwd)
"$basedir/node" "$basedir/../lib/node_modules/npm/bin/npm-cli.js" "$@"
NPMWRAPPER
chmod +x bin/npm

cat > bin/npx << 'NPXWRAPPER'
#!/bin/sh
basedir=$(cd "$(dirname "$0")" && pwd)
"$basedir/node" "$basedir/../lib/node_modules/npm/bin/npx-cli.js" "$@"
NPXWRAPPER
chmod +x bin/npx

# Set npm prefix to local directory
export PATH="$INSTALL_DIR/bin:$PATH"
export NPM_CONFIG_PREFIX="$INSTALL_DIR"

# Install Codex
echo "[3/4] Installing Codex CLI..."
"$INSTALL_DIR/bin/npm" install -g @openai/codex

# Create launcher script
echo "[4/4] Creating launcher..."
cat > "$INSTALL_DIR/start-codex.sh" << LAUNCHER
#!/bin/bash
export PATH="$INSTALL_DIR/bin:$INSTALL_DIR/lib/node_modules/.bin:\$PATH"
export NPM_CONFIG_PREFIX="$INSTALL_DIR"

if [ -z "\$OPENAI_API_KEY" ]; then
    echo ""
    echo "Enter your OpenAI API key (get one at https://platform.openai.com/api-keys):"
    read -s OPENAI_API_KEY
    export OPENAI_API_KEY
    echo ""
fi

echo "======================================"
echo "  Codex Environment Ready!"
echo "======================================"
echo ""
echo "Try: codex \"create a hello world html page\""
echo ""
exec bash
LAUNCHER
chmod +x "$INSTALL_DIR/start-codex.sh"

# Create desktop shortcut for macOS
if [ "$(uname -s)" = "Darwin" ]; then
    cat > "$HOME/Desktop/Start Codex.command" << SHORTCUT
#!/bin/bash
cd ~
open -a Terminal "$INSTALL_DIR/start-codex.sh"
SHORTCUT
    chmod +x "$HOME/Desktop/Start Codex.command"
    echo ""
    echo "Desktop shortcut created: ~/Desktop/Start Codex.command"
fi

echo ""
echo "======================================"
echo "  Installation Complete!"
echo "======================================"
echo ""
echo "To start Codex environment:"
echo "  $INSTALL_DIR/start-codex.sh"
echo ""
echo "Or on macOS, double-click 'Start Codex' on your Desktop"
echo ""
