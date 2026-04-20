# Codex Sandbox

**One-click setup** to run OpenAI Codex CLI. No admin rights needed, no system install - everything runs from a local folder.

## Quick Start (For Trainees)

### macOS / Linux

Open Terminal and run:
```bash
curl -fsSL https://raw.githubusercontent.com/allthingssecurity/codexsandbox/v1.1.2/setup-codex.sh | bash
```

### Windows

1. Download [setup-codex.bat](https://raw.githubusercontent.com/allthingssecurity/codexsandbox/main/setup-codex.bat)
2. Double-click to run

---

## What Gets Installed

The script creates a `codex-env` folder in your home directory containing:
- Node.js (portable, no system install)
- npm (package manager)
- Codex CLI

**Total size**: ~200 MB

**Location**: 
- macOS/Linux: `~/codex-env/`
- Windows: `%USERPROFILE%\codex-env\`

---

## Using Codex

### Start the Environment

**macOS**: Double-click `Start Codex` on Desktop, or run:
```bash
~/codex-env/start-codex.sh
```

**Windows**: Double-click `Start Codex` on Desktop, or run:
```
%USERPROFILE%\codex-env\start-codex.bat
```

### Set Your API Key

On first run, you'll be prompted for your OpenAI API key.
Get one at: https://platform.openai.com/api-keys

### Run Codex

```bash
# Create a simple web page
codex "create a hello world html page"

# Create a todo app
codex "create a todo app with html, css, and javascript"

# Ask questions about code
codex "explain this code" < myfile.py
```

---

## Uninstall

Just delete the folder:

**macOS/Linux**:
```bash
rm -rf ~/codex-env
rm ~/Desktop/Start\ Codex.command
```

**Windows**:
```
rmdir /s %USERPROFILE%\codex-env
del "%USERPROFILE%\Desktop\Start Codex.lnk"
```

---

## Troubleshooting

### "curl: command not found" (Windows)
Windows 10/11 has curl built-in. If missing, download the .bat file manually from the link above.

### "OPENAI_API_KEY not set"
The launcher will prompt you. Or set it permanently:

**macOS/Linux** (add to ~/.bashrc or ~/.zshrc):
```bash
export OPENAI_API_KEY="sk-your-key-here"
```

**Windows** (run in CMD):
```
setx OPENAI_API_KEY "sk-your-key-here"
```

### Network issues
Make sure you can access:
- https://nodejs.org (for Node.js download)
- https://registry.npmjs.org (for Codex install)
- https://api.openai.com (for Codex to work)

---

## For Advanced Users

### Manual Installation

```bash
# Clone repo
git clone https://github.com/allthingssecurity/codexsandbox.git
cd codexsandbox

# Run setup
./setup-codex.sh        # macOS/Linux
setup-codex.bat         # Windows
```

### Desktop App (Tauri)

A desktop app version with built-in terminal is also available. See the `src-tauri/` folder for build instructions.

---

## License

MIT
