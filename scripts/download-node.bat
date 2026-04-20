@echo off
REM Download and setup Node.js for bundling with Tauri (Windows batch)
REM Run this before `npm run tauri build`

setlocal enabledelayedexpansion

set NODE_VERSION=22.15.0
set RESOURCES_DIR=src-tauri\resources\node
set PLATFORM=win-x64

if not exist "%RESOURCES_DIR%" mkdir "%RESOURCES_DIR%"

echo Downloading Node.js v%NODE_VERSION% for %PLATFORM%...

set URL=https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-%PLATFORM%.zip
set TEMP_ZIP=%TEMP%\node.zip
set TEMP_DIR=%TEMP%\node-extract

REM Download using curl (available on Windows 10+)
curl -L "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Node.js. Make sure curl is available.
    echo You can also manually download from: %URL%
    exit /b 1
)

REM Extract using tar (available on Windows 10+)
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
tar -xf "%TEMP_ZIP%" -C "%TEMP_DIR%"

REM Copy files
xcopy /s /e /y "%TEMP_DIR%\node-v%NODE_VERSION%-%PLATFORM%\*" "%RESOURCES_DIR%\"

REM Cleanup
del "%TEMP_ZIP%"
rmdir /s /q "%TEMP_DIR%"

REM Remove unnecessary files
if exist "%RESOURCES_DIR%\include" rmdir /s /q "%RESOURCES_DIR%\include"
if exist "%RESOURCES_DIR%\CHANGELOG.md" del "%RESOURCES_DIR%\CHANGELOG.md"
if exist "%RESOURCES_DIR%\README.md" del "%RESOURCES_DIR%\README.md"

REM Create npm.cmd wrapper
(
echo @echo off
echo set "basedir=%%~dp0"
echo set "node=%%basedir%%node.exe"
echo set "npm_cli=%%basedir%%..\node_modules\npm\bin\npm-cli.js"
echo "%%node%%" "%%npm_cli%%" %%*
) > "%RESOURCES_DIR%\npm.cmd"

REM Create npx.cmd wrapper
(
echo @echo off
echo set "basedir=%%~dp0"
echo set "node=%%basedir%%node.exe"
echo set "npx_cli=%%basedir%%..\node_modules\npm\bin\npx-cli.js"
echo "%%node%%" "%%npx_cli%%" %%*
) > "%RESOURCES_DIR%\npx.cmd"

echo.
echo Node.js v%NODE_VERSION% downloaded and configured in %RESOURCES_DIR%
echo.
echo Next steps:
echo   npm install
echo   npm run tauri build

endlocal
