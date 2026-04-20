# Codex Trainer

A simple desktop terminal app for running OpenAI Codex CLI. Built with Tauri v2 + React + xterm.js.

## Features

- Full PTY terminal (not just command output)
- API key configuration (stored securely, injected as env var)
- Cross-platform: macOS, Windows, Linux
- Lightweight (~15MB app, no bundled Node.js or Codex)

## Prerequisites

Before using this app, trainees need to install:

1. **Node.js** (v18 or later)
   - Download from https://nodejs.org/ or use a version manager like nvm

2. **Codex CLI**
   ```bash
   npm install -g @openai/codex
   ```

3. **OpenAI API Key**
   - Get one from https://platform.openai.com/api-keys

## Quick Start

### Option 1: Download Pre-built Binary

1. Go to [Releases](https://github.com/allthingssecurity/codexsandbox/releases)
2. Download the binary for your platform:
   - macOS: `CodexTrainer_x.x.x_aarch64.dmg` (Apple Silicon) or `CodexTrainer_x.x.x_x64.dmg` (Intel)
   - Windows: `CodexTrainer_x.x.x_x64-setup.exe`
   - Linux: `CodexTrainer_x.x.x_amd64.deb` or `.AppImage`
3. Install and run
4. Click **Settings** to add your OpenAI API key
5. Run `codex "create a hello world html page"`

### Option 2: Build from Source

#### Requirements
- Node.js 18+
- Rust 1.70+
- Platform-specific dependencies (see Tauri prerequisites)

#### Steps

```bash
# Clone the repo
git clone https://github.com/allthingssecurity/codexsandbox.git
cd codexsandbox

# Install dependencies
npm install

# Run in dev mode
npm run tauri dev

# Build for production
npm run tauri build
```

The built app will be in `src-tauri/target/release/bundle/`.

## Usage

1. **Launch the app** - A terminal window opens
2. **Set API key** - Click Settings (gear icon) and enter your OpenAI API key
3. **Install Codex** (if not already):
   ```bash
   npm install -g @openai/codex
   ```
4. **Run Codex**:
   ```bash
   codex "create a simple todo app with React"
   ```
5. **View outputs** - Generated files appear in your working directory

## Configuration

Settings are stored in:
- macOS: `~/Library/Application Support/codex-trainer/config.toml`
- Windows: `%APPDATA%\codex-trainer\config.toml`
- Linux: `~/.config/codex-trainer/config.toml`

## Architecture

```
codex-trainer/
├── src/                    # React frontend
│   ├── App.tsx            # Main app component
│   ├── Terminal.tsx       # xterm.js terminal
│   └── Settings.tsx       # API key settings modal
├── src-tauri/             # Rust backend
│   ├── src/
│   │   ├── main.rs        # Tauri entry point
│   │   ├── pty.rs         # PTY handling
│   │   └── config.rs      # Config management
│   └── tauri.conf.json    # Tauri configuration
└── package.json
```

## Troubleshooting

### "codex: command not found"
Install Codex globally:
```bash
npm install -g @openai/codex
```

### Terminal not connecting
Check that the app has permissions to spawn processes. On macOS, you may need to allow it in System Preferences > Security & Privacy.

### API key not working
Ensure your OpenAI API key is valid and has credits. Test with:
```bash
export OPENAI_API_KEY=your-key-here
codex --version
```

## License

MIT
