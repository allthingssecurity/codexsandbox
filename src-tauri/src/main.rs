#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod config;
mod pty;

use std::sync::Arc;
use pty::PtyState;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(Arc::new(PtyState::default()))
        .invoke_handler(tauri::generate_handler![
            pty::spawn_pty,
            pty::write_pty,
            pty::resize_pty,
            pty::close_pty,
            pty::get_node_info,
            config::get_config,
            config::save_config,
            config::get_home_dir,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
