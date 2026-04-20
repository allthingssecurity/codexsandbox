# Download and setup Node.js for bundling with Tauri (Windows)
# Run this before `npm run tauri build`

$ErrorActionPreference = "Stop"

$NODE_VERSION = "22.15.0"
$RESOURCES_DIR = "src-tauri\resources\node"

New-Item -ItemType Directory -Force -Path $RESOURCES_DIR | Out-Null

# Detect architecture
if ([Environment]::Is64BitOperatingSystem) {
    $PLATFORM = "win-x64"
} else {
    $PLATFORM = "win-x86"
}

Write-Host "Downloading Node.js v$NODE_VERSION for $PLATFORM..."

$URL = "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-$PLATFORM.zip"
$TempZip = "$env:TEMP\node.zip"
$TempDir = "$env:TEMP\node-extract"

Invoke-WebRequest -Uri $URL -OutFile $TempZip
Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force
Copy-Item -Path "$TempDir\node-v$NODE_VERSION-$PLATFORM\*" -Destination $RESOURCES_DIR -Recurse -Force

# Cleanup
Remove-Item $TempZip -Force
Remove-Item $TempDir -Recurse -Force

# Remove unnecessary files
Remove-Item "$RESOURCES_DIR\include" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$RESOURCES_DIR\CHANGELOG.md" -Force -ErrorAction SilentlyContinue
Remove-Item "$RESOURCES_DIR\README.md" -Force -ErrorAction SilentlyContinue

# Create npm.cmd wrapper for Windows
$npmCmd = @"
@echo off
set "basedir=%~dp0"
set "node=%basedir%node.exe"
set "npm_cli=%basedir%..\node_modules\npm\bin\npm-cli.js"
"%node%" "%npm_cli%" %*
"@
Set-Content -Path "$RESOURCES_DIR\npm.cmd" -Value $npmCmd

# Create npx.cmd wrapper
$npxCmd = @"
@echo off
set "basedir=%~dp0"
set "node=%basedir%node.exe"
set "npx_cli=%basedir%..\node_modules\npm\bin\npx-cli.js"
"%node%" "%npx_cli%" %*
"@
Set-Content -Path "$RESOURCES_DIR\npx.cmd" -Value $npxCmd

$size = (Get-ChildItem -Path $RESOURCES_DIR -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Node.js v$NODE_VERSION downloaded and configured in $RESOURCES_DIR"
Write-Host "Size: $([math]::Round($size, 1)) MB"
