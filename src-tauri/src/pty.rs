use parking_lot::Mutex;
use portable_pty::{native_pty_system, CommandBuilder, PtyPair, PtySize};
use std::collections::HashMap;
use std::io::{Read, Write};
use std::path::PathBuf;
use std::sync::Arc;
use std::thread;
use tauri::{AppHandle, Emitter, Manager};

pub struct PtyState {
    pub sessions: Mutex<HashMap<u32, PtySession>>,
    pub next_id: Mutex<u32>,
}

pub struct PtySession {
    pub writer: Box<dyn Write + Send>,
    pub pair: PtyPair,
}

impl Default for PtyState {
    fn default() -> Self {
        Self {
            sessions: Mutex::new(HashMap::new()),
            next_id: Mutex::new(1),
        }
    }
}

/// Get the path to bundled Node.js
fn get_bundled_node_path(app: &AppHandle) -> Option<PathBuf> {
    // Check relative to executable first (most reliable)
    if let Ok(exe_path) = std::env::current_exe() {
        if let Some(exe_dir) = exe_path.parent() {
            // macOS app bundle: Contents/MacOS/../Resources/resources/node/bin
            let macos_path = exe_dir.join("../Resources/resources/node/bin");
            if macos_path.exists() {
                return Some(macos_path.canonicalize().unwrap_or(macos_path));
            }

            // Alternative macOS path
            let macos_path2 = exe_dir.join("../Resources/node/bin");
            if macos_path2.exists() {
                return Some(macos_path2.canonicalize().unwrap_or(macos_path2));
            }

            // Direct path for dev (src-tauri/resources/node/bin)
            let dev_path = exe_dir.join("../../resources/node/bin");
            if dev_path.exists() {
                return Some(dev_path.canonicalize().unwrap_or(dev_path));
            }
        }
    }

    // Fallback: use Tauri's resource_dir
    if let Ok(resource_path) = app.path().resource_dir() {
        let node_bin = resource_path.join("resources/node/bin");
        if node_bin.exists() {
            return Some(node_bin);
        }
        let node_bin2 = resource_path.join("node/bin");
        if node_bin2.exists() {
            return Some(node_bin2);
        }
    }

    None
}

/// Get npm global prefix for bundled node
fn get_npm_prefix() -> PathBuf {
    dirs::data_local_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("codex-trainer")
        .join("npm-global")
}

#[tauri::command]
pub fn spawn_pty(
    app: AppHandle,
    cwd: Option<String>,
    env: Option<HashMap<String, String>>,
    cols: u16,
    rows: u16,
) -> Result<u32, String> {
    let pty_system = native_pty_system();

    let pair = pty_system
        .openpty(PtySize {
            rows,
            cols,
            pixel_width: 0,
            pixel_height: 0,
        })
        .map_err(|e| e.to_string())?;

    // Get the default shell - use --no-rcs to skip loading .zshrc/.bashrc which may have nvm
    #[cfg(target_os = "windows")]
    let shell = std::env::var("COMSPEC").unwrap_or_else(|_| "cmd.exe".to_string());
    #[cfg(target_os = "windows")]
    let shell_args: Vec<&str> = vec![];

    #[cfg(not(target_os = "windows"))]
    let shell = "/bin/bash".to_string(); // Use bash for consistency
    #[cfg(not(target_os = "windows"))]
    let shell_args = vec!["--norc", "--noprofile"];

    let mut cmd = CommandBuilder::new(&shell);

    #[cfg(not(target_os = "windows"))]
    for arg in &shell_args {
        cmd.arg(*arg);
    }

    // Set working directory
    if let Some(dir) = cwd {
        cmd.cwd(dir);
    } else if let Some(home) = dirs::home_dir() {
        cmd.cwd(home);
    }

    // Build PATH with bundled Node.js first
    let mut path_parts: Vec<String> = Vec::new();

    // Add npm global bin directory (highest priority - where codex will be installed)
    let npm_prefix = get_npm_prefix();
    let npm_bin = npm_prefix.join("bin");
    std::fs::create_dir_all(&npm_bin).ok();
    path_parts.push(npm_bin.to_string_lossy().to_string());

    // Add bundled Node.js bin to PATH
    if let Some(node_bin) = get_bundled_node_path(&app) {
        path_parts.push(node_bin.to_string_lossy().to_string());
    }

    // Add existing PATH but filter out nvm paths to avoid conflicts
    #[cfg(target_os = "windows")]
    let path_sep = ";";
    #[cfg(not(target_os = "windows"))]
    let path_sep = ":";

    if let Ok(existing_path) = std::env::var("PATH") {
        for part in existing_path.split(path_sep) {
            // Skip nvm-managed paths since we're using bundled Node
            if !part.contains(".nvm") && !part.contains("nvm") {
                path_parts.push(part.to_string());
            }
        }
    }

    let new_path = path_parts.join(path_sep);
    cmd.env("PATH", &new_path);

    // Set npm prefix so global installs go to our directory
    cmd.env("NPM_CONFIG_PREFIX", npm_prefix.to_string_lossy().to_string());

    // Disable nvm initialization in the shell
    cmd.env("NVM_DIR", "");
    cmd.env("NVM_BIN", "");
    cmd.env("NVM_INC", "");

    // Set environment variables from config
    if let Some(env_vars) = env {
        for (key, value) in env_vars {
            cmd.env(key, value);
        }
    }

    // Ensure TERM is set
    cmd.env("TERM", "xterm-256color");

    let mut child = pair.slave.spawn_command(cmd).map_err(|e| e.to_string())?;

    let reader = pair.master.try_clone_reader().map_err(|e| e.to_string())?;
    let writer = pair.master.take_writer().map_err(|e| e.to_string())?;

    // Generate session ID
    let state = app.state::<Arc<PtyState>>();
    let session_id = {
        let mut id = state.next_id.lock();
        let current = *id;
        *id += 1;
        current
    };

    // Store session
    {
        let mut sessions = state.sessions.lock();
        sessions.insert(
            session_id,
            PtySession {
                writer,
                pair,
            },
        );
    }

    // Spawn thread to read PTY output and emit to frontend
    let app_clone = app.clone();
    let session_id_clone = session_id;
    thread::spawn(move || {
        let mut reader = reader;
        let mut buf = [0u8; 4096];
        loop {
            match reader.read(&mut buf) {
                Ok(0) => break, // EOF
                Ok(n) => {
                    let data = String::from_utf8_lossy(&buf[..n]).to_string();
                    let _ = app_clone.emit(&format!("pty-output-{}", session_id_clone), data);
                }
                Err(_) => break,
            }
        }
        // Notify frontend that PTY closed
        let _ = app_clone.emit(&format!("pty-exit-{}", session_id_clone), ());
    });

    // Spawn thread to wait for child process
    thread::spawn(move || {
        let _ = child.wait();
    });

    Ok(session_id)
}

#[tauri::command]
pub fn write_pty(app: AppHandle, session_id: u32, data: String) -> Result<(), String> {
    let state = app.state::<Arc<PtyState>>();
    let mut sessions = state.sessions.lock();

    if let Some(session) = sessions.get_mut(&session_id) {
        session
            .writer
            .write_all(data.as_bytes())
            .map_err(|e| e.to_string())?;
        session.writer.flush().map_err(|e| e.to_string())?;
        Ok(())
    } else {
        Err("Session not found".to_string())
    }
}

#[tauri::command]
pub fn resize_pty(app: AppHandle, session_id: u32, cols: u16, rows: u16) -> Result<(), String> {
    let state = app.state::<Arc<PtyState>>();
    let sessions = state.sessions.lock();

    if let Some(session) = sessions.get(&session_id) {
        session
            .pair
            .master
            .resize(PtySize {
                rows,
                cols,
                pixel_width: 0,
                pixel_height: 0,
            })
            .map_err(|e| e.to_string())?;
        Ok(())
    } else {
        Err("Session not found".to_string())
    }
}

#[tauri::command]
pub fn close_pty(app: AppHandle, session_id: u32) -> Result<(), String> {
    let state = app.state::<Arc<PtyState>>();
    let mut sessions = state.sessions.lock();
    sessions.remove(&session_id);
    Ok(())
}

#[tauri::command]
pub fn get_node_info(app: AppHandle) -> Result<HashMap<String, String>, String> {
    let mut info = HashMap::new();

    if let Some(node_bin) = get_bundled_node_path(&app) {
        info.insert("node_path".to_string(), node_bin.to_string_lossy().to_string());
        info.insert("bundled".to_string(), "true".to_string());
    } else {
        info.insert("bundled".to_string(), "false".to_string());
    }

    let npm_prefix = get_npm_prefix();
    info.insert("npm_prefix".to_string(), npm_prefix.to_string_lossy().to_string());

    Ok(info)
}
