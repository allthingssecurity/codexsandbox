@echo off
REM Codex Portable Setup for Windows
REM Downloads Node.js and Codex to a local folder - no admin needed!

setlocal enabledelayedexpansion

set INSTALL_DIR=%USERPROFILE%\codex-env
set NODE_VERSION=22.15.0
set PLATFORM=win-x64

echo ======================================
echo   Codex Portable Environment Setup
echo ======================================
echo.

echo Platform: %PLATFORM%
echo Install directory: %INSTALL_DIR%
echo.

REM Create install directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
cd /d "%INSTALL_DIR%"

REM Download Node.js
echo [1/4] Downloading Node.js v%NODE_VERSION%...
set NODE_URL=https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-%PLATFORM%.zip
curl -L "%NODE_URL%" -o node.zip
if errorlevel 1 (
    echo Failed to download. Make sure you have internet connection.
    pause
    exit /b 1
)

REM Extract
echo [2/4] Extracting Node.js...
tar -xf node.zip
move node-v%NODE_VERSION%-%PLATFORM%\* . >nul 2>&1
rmdir node-v%NODE_VERSION%-%PLATFORM% 2>nul
del node.zip

REM Remove unnecessary files
rmdir /s /q include 2>nul
del CHANGELOG.md 2>nul
del README.md 2>nul

REM Install Codex
echo [3/4] Installing Codex CLI...
set PATH=%INSTALL_DIR%;%INSTALL_DIR%\node_modules\.bin;%PATH%
set NPM_CONFIG_PREFIX=%INSTALL_DIR%
call "%INSTALL_DIR%\npm.cmd" install -g @openai/codex

REM Create launcher batch file
echo [4/4] Creating launcher...
(
echo @echo off
echo set PATH=%INSTALL_DIR%;%INSTALL_DIR%\node_modules\.bin;%%PATH%%
echo set NPM_CONFIG_PREFIX=%INSTALL_DIR%
echo.
echo if "%%OPENAI_API_KEY%%"=="" ^(
echo     echo.
echo     echo Enter your OpenAI API key ^(get one at https://platform.openai.com/api-keys^):
echo     set /p OPENAI_API_KEY=
echo     echo.
echo ^)
echo.
echo echo ======================================
echo echo   Codex Environment Ready!
echo echo ======================================
echo echo.
echo echo Try: codex "create a hello world html page"
echo echo.
echo cmd /k
) > "%INSTALL_DIR%\start-codex.bat"

REM Create desktop shortcut
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\shortcut.vbs"
echo sLinkFile = oWS.ExpandEnvironmentStrings("%%USERPROFILE%%\Desktop\Start Codex.lnk") >> "%TEMP%\shortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\shortcut.vbs"
echo oLink.TargetPath = "%INSTALL_DIR%\start-codex.bat" >> "%TEMP%\shortcut.vbs"
echo oLink.WorkingDirectory = "%%USERPROFILE%%" >> "%TEMP%\shortcut.vbs"
echo oLink.Save >> "%TEMP%\shortcut.vbs"
cscript //nologo "%TEMP%\shortcut.vbs"
del "%TEMP%\shortcut.vbs"

echo.
echo ======================================
echo   Installation Complete!
echo ======================================
echo.
echo To start Codex environment:
echo   %INSTALL_DIR%\start-codex.bat
echo.
echo Or double-click 'Start Codex' on your Desktop
echo.
pause
