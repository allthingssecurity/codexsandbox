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
        echo "This script is for macOS/Linux. Use setup-codex.bat for Windows."
        exit 1
        ;;
esac

echo "Platform: $PLATFORM"
echo "Install directory: $INSTALL_DIR"
echo ""

# Clean previous install if exists
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing previous installation..."
    rm -rf "$INSTALL_DIR"
fi

# Create install directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download Node.js
echo "[1/4] Downloading Node.js v${NODE_VERSION}..."
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${PLATFORM}.tar.gz"
curl -L "$NODE_URL" -o node.tar.gz
tar -xzf node.tar.gz --strip-components=1
rm node.tar.gz

# Remove unnecessary files to save space
rm -rf include share CHANGELOG.md README.md 2>/dev/null || true

echo "[2/4] Configuring environment..."

# The Node.js tarball already has working npm/npx in bin/
# We just need to set up the PATH and npm prefix correctly

# Set npm prefix to local directory for global installs
export PATH="$INSTALL_DIR/bin:$PATH"
mkdir -p "$INSTALL_DIR/global-packages"

# Install Codex using the bundled npm
echo "[3/4] Installing Codex CLI..."
"$INSTALL_DIR/bin/npm" install -g @openai/codex --prefix "$INSTALL_DIR/global-packages"

# Create launcher script
echo "[4/4] Creating launcher..."
cat > "$INSTALL_DIR/start-codex.sh" << 'LAUNCHER_START'
#!/bin/bash
INSTALL_DIR="$HOME/codex-env"
export PATH="$INSTALL_DIR/global-packages/bin:$INSTALL_DIR/bin:$PATH"

if [ -z "$OPENAI_API_KEY" ]; then
    echo ""
    echo "======================================"
    echo "  OpenAI API Key Required"
    echo "======================================"
    echo ""
    echo "Get your key at: https://platform.openai.com/api-keys"
    echo ""
    printf "Enter your API key: "
    read -s OPENAI_API_KEY
    export OPENAI_API_KEY
    echo ""
    echo ""
fi

echo "======================================"
echo "  Codex Environment Ready!"
echo "======================================"
echo ""
echo "Commands:"
echo "  codex \"create a hello world html page\""
echo "  codex \"build a todo app with html css js\""
echo ""
exec bash
LAUNCHER_START
chmod +x "$INSTALL_DIR/start-codex.sh"

# Create desktop shortcut for macOS
if [ "$(uname -s)" = "Darwin" ]; then
    SHORTCUT="$HOME/Desktop/Start Codex.command"
    cat > "$SHORTCUT" << 'SHORTCUT_CONTENT'
#!/bin/bash
osascript -e 'tell app "Terminal" to do script "~/codex-env/start-codex.sh"'
SHORTCUT_CONTENT
    chmod +x "$SHORTCUT"
    echo ""
    echo "Desktop shortcut created: $SHORTCUT"
fi

# Create desktop shortcut for Linux
if [ "$(uname -s)" = "Linux" ]; then
    SHORTCUT="$HOME/Desktop/start-codex.desktop"
    cat > "$SHORTCUT" << SHORTCUT_CONTENT
[Desktop Entry]
Name=Start Codex
Comment=Launch Codex CLI environment
Exec=gnome-terminal -- bash -c "$INSTALL_DIR/start-codex.sh"
Terminal=true
Type=Application
Icon=utilities-terminal
SHORTCUT_CONTENT
    chmod +x "$SHORTCUT"
    echo ""
    echo "Desktop shortcut created: $SHORTCUT"
fi

echo ""
echo "======================================"
echo "  Installation Complete!"
echo "======================================"
echo ""
echo "To start Codex, run:"
echo "  ~/codex-env/start-codex.sh"
echo ""
if [ "$(uname -s)" = "Darwin" ]; then
    echo "Or double-click 'Start Codex' on your Desktop"
fi
echo ""
