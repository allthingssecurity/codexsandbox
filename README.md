# Codex Trainer

A desktop terminal app for running OpenAI Codex CLI. **Zero setup for trainees** - Node.js is bundled, just install Codex and go.

## Features

- **Bundled Node.js** - No need to install Node.js separately
- Full PTY terminal with xterm.js
- API key management via Settings
- Cross-platform: macOS, Windows, Linux

## For Trainees (End Users)

### Download & Install

1. Go to [Releases](https://github.com/allthingssecurity/codexsandbox/releases)
2. Download for your platform:
   - **macOS (Apple Silicon)**: `CodexTrainer_x.x.x_aarch64.dmg`
   - **macOS (Intel)**: `CodexTrainer_x.x.x_x64.dmg`
   - **Windows**: `CodexTrainer_x.x.x_x64-setup.exe`
   - **Linux**: `CodexTrainer_x.x.x_amd64.AppImage`
3. Install and run

### Quick Start

1. **Launch** the app
2. **Click Settings** (gear icon) → Add your OpenAI API key
3. **Install Codex** (one-time, in the terminal):
   ```bash
   npm install -g @openai/codex
   ```
4. **Run Codex**:
   ```bash
   codex "create a todo app with html and css"
   ```
5. View generated files in your home directory

## For Developers (Building from Source)

### Prerequisites

- Node.js 18+ (for building, not bundled)
- Rust 1.70+
- Platform-specific Tauri dependencies:
  - **macOS**: Xcode Command Line Tools
  - **Windows**: Visual Studio Build Tools, WebView2
  - **Linux**: `libwebkit2gtk-4.0-dev`, `libappindicator3-dev`

### Build Steps

```bash
# Clone the repo
git clone https://github.com/allthingssecurity/codexsandbox.git
cd codexsandbox

# Install frontend dependencies
npm install

# Download Node.js for bundling (required before build)
./scripts/download-node.sh

# Build for production
npm run tauri build
```

The built app will be in `src-tauri/target/release/bundle/`.

### Cross-Platform Builds

To build for a different platform, run the download script on that platform first:

```bash
# On Windows (PowerShell)
.\scripts\download-node.ps1

# On Linux/macOS
./scripts/download-node.sh

# Then build
npm run tauri build
```

## Architecture

```
codex-trainer/
├── src/                          # React frontend
│   ├── App.tsx                   # Main app component
│   ├── Terminal.tsx              # xterm.js terminal
│   └── Settings.tsx              # API key settings
├── src-tauri/
│   ├── src/
│   │   ├── main.rs               # Tauri entry point
│   │   ├── pty.rs                # PTY + bundled Node path handling
│   │   └── config.rs             # Config management
│   ├── resources/node/           # Bundled Node.js (downloaded at build time)
│   └── tauri.conf.json
├── scripts/
│   └── download-node.sh          # Downloads Node.js for bundling
└── package.json
```

## How It Works

1. **Bundled Node.js**: The app bundles a complete Node.js runtime in `resources/node/`
2. **Isolated Environment**: The terminal uses the bundled Node, not any system Node/nvm
3. **npm Global Prefix**: Global npm installs go to `~/Library/Application Support/codex-trainer/npm-global/` (isolated from system)
4. **API Key Injection**: Your OpenAI key is injected as `OPENAI_API_KEY` env var

## Troubleshooting

### "npm: command not found"
The bundled Node.js path isn't being detected. Try restarting the app.

### nvm conflicts
The app disables nvm to avoid conflicts. This is intentional - it uses its own bundled Node.

### Codex errors
Make sure you've:
1. Added your API key in Settings
2. Installed Codex: `npm install -g @openai/codex`

## License

MIT
