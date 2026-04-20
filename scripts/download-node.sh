#!/bin/bash
# Download and setup Node.js for bundling with Tauri
# Run this before `npm run tauri build`

set -e

NODE_VERSION="22.15.0"
RESOURCES_DIR="src-tauri/resources/node"

mkdir -p "$RESOURCES_DIR"

# Detect platform
case "$(uname -s)" in
    Darwin)
        case "$(uname -m)" in
            arm64) PLATFORM="darwin-arm64" ;;
            x86_64) PLATFORM="darwin-x64" ;;
        esac
        ;;
    Linux)
        case "$(uname -m)" in
            aarch64) PLATFORM="linux-arm64" ;;
            x86_64) PLATFORM="linux-x64" ;;
        esac
        ;;
    MINGW*|MSYS*|CYGWIN*)
        case "$(uname -m)" in
            x86_64) PLATFORM="win-x64" ;;
        esac
        ;;
esac

if [ -z "$PLATFORM" ]; then
    echo "Unsupported platform: $(uname -s) $(uname -m)"
    exit 1
fi

echo "Downloading Node.js v${NODE_VERSION} for ${PLATFORM}..."

if [[ "$PLATFORM" == win-* ]]; then
    URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${PLATFORM}.zip"
    curl -L "$URL" -o /tmp/node.zip
    unzip -o /tmp/node.zip -d /tmp/
    cp -r /tmp/node-v${NODE_VERSION}-${PLATFORM}/* "$RESOURCES_DIR/"
    rm /tmp/node.zip
else
    URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${PLATFORM}.tar.gz"
    curl -L "$URL" -o /tmp/node.tar.gz
    tar -xzf /tmp/node.tar.gz -C /tmp/
    cp -r /tmp/node-v${NODE_VERSION}-${PLATFORM}/* "$RESOURCES_DIR/"
    rm /tmp/node.tar.gz
fi

# Remove unnecessary files to reduce size
rm -rf "$RESOURCES_DIR/include"
rm -rf "$RESOURCES_DIR/share"
rm -f "$RESOURCES_DIR/CHANGELOG.md"
rm -f "$RESOURCES_DIR/README.md"

# Fix npm/npx wrapper scripts for bundled use
cat > "$RESOURCES_DIR/bin/npm" << 'EOF'
#!/bin/sh
basedir=$(cd "$(dirname "$0")" && pwd)
node="$basedir/node"
npm_cli="$basedir/../lib/node_modules/npm/bin/npm-cli.js"
"$node" "$npm_cli" "$@"
EOF

cat > "$RESOURCES_DIR/bin/npx" << 'EOF'
#!/bin/sh
basedir=$(cd "$(dirname "$0")" && pwd)
node="$basedir/node"
npx_cli="$basedir/../lib/node_modules/npm/bin/npx-cli.js"
"$node" "$npx_cli" "$@"
EOF

chmod +x "$RESOURCES_DIR/bin/npm"
chmod +x "$RESOURCES_DIR/bin/npx"

echo "Node.js v${NODE_VERSION} downloaded and configured in ${RESOURCES_DIR}"
echo "Size: $(du -sh "$RESOURCES_DIR" | cut -f1)"
