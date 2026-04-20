use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct Config {
    pub openai_api_key: Option<String>,
    pub anthropic_api_key: Option<String>,
    pub working_directory: Option<String>,
}

fn config_path() -> PathBuf {
    let config_dir = dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("codex-trainer");

    fs::create_dir_all(&config_dir).ok();
    config_dir.join("config.toml")
}

#[tauri::command]
pub fn get_config() -> Result<Config, String> {
    let path = config_path();

    if path.exists() {
        let content = fs::read_to_string(&path).map_err(|e| e.to_string())?;
        toml::from_str(&content).map_err(|e| e.to_string())
    } else {
        Ok(Config::default())
    }
}

#[tauri::command]
pub fn save_config(config: Config) -> Result<(), String> {
    let path = config_path();
    let content = toml::to_string_pretty(&config).map_err(|e| e.to_string())?;
    fs::write(&path, content).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_home_dir() -> Option<String> {
    dirs::home_dir().map(|p| p.to_string_lossy().to_string())
}
