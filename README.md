# Codex Trainer

A desktop terminal app for running OpenAI Codex CLI. **Zero setup for trainees** - Node.js is bundled, just install Codex and go.

## For Trainees (Download & Run)

### Step 1: Download

Go to [Releases](https://github.com/allthingssecurity/codexsandbox/releases/latest) and download for your platform:

| Platform | File |
|----------|------|
| macOS (Apple Silicon) | `CodexTrainer_x.x.x_aarch64.dmg` |
| macOS (Intel) | `CodexTrainer_x.x.x_x64.dmg` |
| Windows | `CodexTrainer_x.x.x_x64-setup.exe` |
| Linux | `CodexTrainer_x.x.x_amd64.AppImage` |

### Step 2: Install

- **macOS**: Open DMG, drag to Applications
- **Windows**: Run the installer
- **Linux**: Make AppImage executable and run

### Step 3: Configure & Use

1. **Launch** the app
2. **Click Settings** (gear icon) → Enter your OpenAI API key
3. **Install Codex** (one-time, type in the terminal):
   ```bash
   npm install -g @openai/codex
   ```
4. **Run Codex**:
   ```bash
   codex "create a todo app with html and css"
   ```

That's it! Generated files appear in your home directory.

---

## For Developers (Building from Source)

### Prerequisites

- Git
- Node.js 18+ (for building only, not bundled)
- Rust 1.70+ ([install](https://rustup.rs/))
- Platform build tools:
  - **macOS**: Xcode Command Line Tools (`xcode-select --install`)
  - **Windows**: [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) + [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
  - **Linux**: `sudo apt install libwebkit2gtk-4.0-dev libappindicator3-dev librsvg2-dev`

### Build Steps (All Platforms)

```bash
# 1. Clone the repo
git clone https://github.com/allthingssecurity/codexsandbox.git
cd codexsandbox

# 2. Install dependencies
npm install

# 3. Download Node.js for bundling (REQUIRED)
#    This downloads Node.js to bundle inside the app

# macOS / Linux:
./scripts/download-node.sh

# Windows (PowerShell):
.\scripts\download-node.ps1

# Windows (CMD, no PowerShell):
scripts\download-node.bat

# 4. Build the app
npm run tauri build
```

### Build Output

After build completes, find your installer in:

```
src-tauri/target/release/bundle/
├── macos/          # macOS: CodexTrainer.app
├── dmg/            # macOS: .dmg installer
├── msi/            # Windows: .msi installer  
├── nsis/           # Windows: .exe installer
├── deb/            # Linux: .deb package
└── appimage/       # Linux: .AppImage
```

### Development Mode

```bash
# Run in dev mode (hot reload)
npm run tauri dev
```

---

## How It Works

### Architecture

```
codex-trainer/
├── src/                          # React frontend (terminal UI)
│   ├── App.tsx                   # Main app + settings
│   ├── Terminal.tsx              # xterm.js terminal
│   └── Settings.tsx              # API key config modal
├── src-tauri/                    # Rust backend
│   ├── src/
│   │   ├── main.rs               # Tauri entry point
│   │   ├── pty.rs                # PTY + Node.js path handling
│   │   └── config.rs             # Config storage
│   ├── resources/node/           # Bundled Node.js (downloaded at build)
│   └── tauri.conf.json           # Tauri config
├── scripts/
│   ├── download-node.sh          # Download Node.js (macOS/Linux)
│   ├── download-node.ps1         # Download Node.js (Windows PowerShell)
│   └── download-node.bat         # Download Node.js (Windows CMD)
└── package.json
```

### Key Features

1. **Bundled Node.js**: App includes Node.js runtime (~100MB), no system install needed
2. **Isolated Environment**: Uses bundled Node, ignores system Node/nvm
3. **Isolated npm**: Global installs go to app-specific directory:
   - macOS: `~/Library/Application Support/codex-trainer/npm-global/`
   - Windows: `%LOCALAPPDATA%\codex-trainer\npm-global\`
   - Linux: `~/.local/share/codex-trainer/npm-global/`
4. **API Key Injection**: Your key is injected as `OPENAI_API_KEY` env var

---

## Troubleshooting

### "npm: command not found"
The bundled Node.js path isn't being detected. Restart the app.

### nvm warning about NPM_CONFIG_PREFIX
This is expected - the app disables nvm to use its bundled Node. Ignore the warning.

### Codex not working
1. Check API key is set (Settings → should show key)
2. Verify Codex installed: `codex --version`
3. Check you have API credits at https://platform.openai.com/

### Build fails on Windows
Make sure you have:
- Visual Studio Build Tools with "Desktop development with C++"
- WebView2 Runtime installed

### Build fails on Linux
Install dependencies:
```bash
sudo apt install libwebkit2gtk-4.0-dev libappindicator3-dev librsvg2-dev patchelf
```

---

## License

MIT
