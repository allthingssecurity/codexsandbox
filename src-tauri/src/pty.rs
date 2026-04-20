use parking_lot::Mutex;
use portable_pty::{native_pty_system, CommandBuilder, PtyPair, PtySize};
use std::collections::HashMap;
use std::io::{Read, Write};
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

    // Get the default shell
    #[cfg(target_os = "windows")]
    let shell = std::env::var("COMSPEC").unwrap_or_else(|_| "cmd.exe".to_string());

    #[cfg(not(target_os = "windows"))]
    let shell = std::env::var("SHELL").unwrap_or_else(|_| "/bin/zsh".to_string());

    let mut cmd = CommandBuilder::new(&shell);

    // Set working directory
    if let Some(dir) = cwd {
        cmd.cwd(dir);
    } else if let Some(home) = dirs::home_dir() {
        cmd.cwd(home);
    }

    // Set environment variables
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
