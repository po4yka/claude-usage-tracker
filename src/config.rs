use std::collections::HashMap;
use std::path::{Path, PathBuf};

use serde::Deserialize;
use tracing::debug;

/// Configuration loaded from ~/.claude/usage-tracker.toml
#[derive(Debug, Default, Deserialize)]
#[serde(default)]
pub struct Config {
    pub projects_dirs: Vec<PathBuf>,
    pub db_path: Option<PathBuf>,
    pub host: Option<String>,
    pub port: Option<u16>,

    /// Custom pricing overrides. Keys are model names (e.g., "claude-opus-4-6"),
    /// values override the built-in rates.
    #[serde(default)]
    pub pricing: HashMap<String, PricingOverride>,

    /// OAuth settings for real-time rate window tracking.
    #[serde(default)]
    pub oauth: OAuthConfig,

    /// Webhook notification settings.
    #[serde(default)]
    pub webhooks: WebhookConfig,

    /// Optional OpenAI organization usage reconciliation for Codex API-backed usage.
    #[serde(default)]
    pub openai: OpenAiConfig,
}

#[derive(Debug, Deserialize)]
#[serde(default)]
pub struct OAuthConfig {
    /// Enable OAuth usage polling (default: true, auto-detects credentials).
    pub enabled: bool,
    /// Seconds between API polls (default: 60).
    pub refresh_interval: u64,
}

impl Default for OAuthConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            refresh_interval: 60,
        }
    }
}

#[derive(Debug, Deserialize)]
#[serde(default)]
pub struct OpenAiConfig {
    /// Enable OpenAI organization usage reconciliation (default: true if OPENAI_ADMIN_KEY exists).
    pub enabled: bool,
    /// Environment variable name that stores the OpenAI admin key.
    pub admin_key_env: String,
    /// Seconds between API refreshes.
    pub refresh_interval: u64,
    /// Number of trailing days to compare against local Codex estimates.
    pub lookback_days: i64,
}

impl Default for OpenAiConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            admin_key_env: "OPENAI_ADMIN_KEY".into(),
            refresh_interval: 300,
            lookback_days: 30,
        }
    }
}

#[derive(Debug, Default, Clone, Deserialize)]
#[serde(default)]
pub struct WebhookConfig {
    /// URL to POST webhook events to.
    pub url: Option<String>,
    /// Notify when daily cost exceeds this amount (USD).
    pub cost_threshold: Option<f64>,
    /// Notify on session depletion events.
    pub session_depleted: bool,
}

#[derive(Debug, Clone, Deserialize)]
pub struct PricingOverride {
    pub input: f64,
    pub output: f64,
    #[serde(default)]
    pub cache_write: Option<f64>,
    #[serde(default)]
    pub cache_read: Option<f64>,
}

fn config_path() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".claude")
        .join("usage-tracker.toml")
}

/// Load config from the default path, or return defaults if not found.
pub fn load_config() -> Config {
    load_config_from(&config_path())
}

/// Load config from a specific path, or return defaults if not found.
pub fn load_config_from(path: &Path) -> Config {
    match std::fs::read_to_string(path) {
        Ok(contents) => match toml::from_str::<Config>(&contents) {
            Ok(config) => {
                debug!("Loaded config from {}", path.display());
                config
            }
            Err(e) => {
                eprintln!(
                    "Warning: failed to parse {}: {}. Using defaults.",
                    path.display(),
                    e
                );
                Config::default()
            }
        },
        Err(_) => Config::default(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::TempDir;

    #[test]
    fn test_missing_file_returns_defaults() {
        let config = load_config_from(Path::new("/nonexistent/path/config.toml"));
        assert!(config.projects_dirs.is_empty());
        assert!(config.db_path.is_none());
        assert!(config.host.is_none());
        assert!(config.port.is_none());
        assert!(config.pricing.is_empty());
    }

    #[test]
    fn test_empty_file_returns_defaults() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        std::fs::File::create(&path).unwrap();
        let config = load_config_from(&path);
        assert!(config.projects_dirs.is_empty());
    }

    #[test]
    fn test_basic_config() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        let mut f = std::fs::File::create(&path).unwrap();
        write!(
            f,
            r#"
projects_dirs = ["/home/user/projects", "/opt/claude"]
db_path = "/tmp/usage.db"
host = "0.0.0.0"
port = 9090
"#
        )
        .unwrap();

        let config = load_config_from(&path);
        assert_eq!(config.projects_dirs.len(), 2);
        assert_eq!(
            config.projects_dirs[0],
            PathBuf::from("/home/user/projects")
        );
        assert_eq!(config.db_path.unwrap(), PathBuf::from("/tmp/usage.db"));
        assert_eq!(config.host.unwrap(), "0.0.0.0");
        assert_eq!(config.port.unwrap(), 9090);
    }

    #[test]
    fn test_pricing_overrides() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        let mut f = std::fs::File::create(&path).unwrap();
        write!(
            f,
            r#"
[pricing.claude-opus-4-6]
input = 10.0
output = 50.0
cache_write = 12.5
cache_read = 1.0

[pricing.my-custom-model]
input = 2.0
output = 8.0
"#
        )
        .unwrap();

        let config = load_config_from(&path);
        assert_eq!(config.pricing.len(), 2);

        let opus = &config.pricing["claude-opus-4-6"];
        assert_eq!(opus.input, 10.0);
        assert_eq!(opus.output, 50.0);
        assert_eq!(opus.cache_write, Some(12.5));
        assert_eq!(opus.cache_read, Some(1.0));

        let custom = &config.pricing["my-custom-model"];
        assert_eq!(custom.input, 2.0);
        assert_eq!(custom.output, 8.0);
        assert!(custom.cache_write.is_none());
        assert!(custom.cache_read.is_none());
    }

    #[test]
    fn test_partial_config() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        let mut f = std::fs::File::create(&path).unwrap();
        write!(f, "port = 3000\n").unwrap();

        let config = load_config_from(&path);
        assert!(config.projects_dirs.is_empty());
        assert!(config.db_path.is_none());
        assert!(config.host.is_none());
        assert_eq!(config.port.unwrap(), 3000);
    }

    #[test]
    fn test_invalid_toml_returns_defaults() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        let mut f = std::fs::File::create(&path).unwrap();
        write!(f, "this is not valid toml {{{{").unwrap();

        let config = load_config_from(&path);
        assert!(config.projects_dirs.is_empty());
    }

    #[test]
    fn test_oauth_config_defaults() {
        // Empty config should give OAuthConfig defaults: enabled=true, refresh_interval=60
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        std::fs::File::create(&path).unwrap();
        let config = load_config_from(&path);
        assert!(config.oauth.enabled);
        assert_eq!(config.oauth.refresh_interval, 60);
    }

    #[test]
    fn test_oauth_config_custom() {
        // Parse custom OAuth config
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        let mut f = std::fs::File::create(&path).unwrap();
        write!(f, "[oauth]\nenabled = false\nrefresh_interval = 120\n").unwrap();
        let config = load_config_from(&path);
        assert!(!config.oauth.enabled);
        assert_eq!(config.oauth.refresh_interval, 120);
    }

    #[test]
    fn test_webhook_config_full() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        let mut f = std::fs::File::create(&path).unwrap();
        write!(
            f,
            "[webhooks]\nurl = \"https://hooks.example.com\"\ncost_threshold = 50.0\nsession_depleted = true\n"
        )
        .unwrap();
        let config = load_config_from(&path);
        assert_eq!(config.webhooks.url.unwrap(), "https://hooks.example.com");
        assert!((config.webhooks.cost_threshold.unwrap() - 50.0).abs() < 0.01);
        assert!(config.webhooks.session_depleted);
    }

    #[test]
    fn test_webhook_config_defaults() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        std::fs::File::create(&path).unwrap();
        let config = load_config_from(&path);
        assert!(config.webhooks.url.is_none());
        assert!(config.webhooks.cost_threshold.is_none());
        assert!(!config.webhooks.session_depleted);
    }

    #[test]
    fn test_openai_config_defaults() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        std::fs::File::create(&path).unwrap();
        let config = load_config_from(&path);
        assert!(config.openai.enabled);
        assert_eq!(config.openai.admin_key_env, "OPENAI_ADMIN_KEY");
        assert_eq!(config.openai.refresh_interval, 300);
        assert_eq!(config.openai.lookback_days, 30);
    }

    #[test]
    fn test_openai_config_custom() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        let mut f = std::fs::File::create(&path).unwrap();
        write!(
            f,
            "[openai]\nenabled = false\nadmin_key_env = \"CUSTOM_OPENAI_KEY\"\nrefresh_interval = 600\nlookback_days = 14\n"
        )
        .unwrap();
        let config = load_config_from(&path);
        assert!(!config.openai.enabled);
        assert_eq!(config.openai.admin_key_env, "CUSTOM_OPENAI_KEY");
        assert_eq!(config.openai.refresh_interval, 600);
        assert_eq!(config.openai.lookback_days, 14);
    }

    #[test]
    fn test_config_type_mismatch() {
        // Wrong type should fall back to defaults (TOML parse error)
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("config.toml");
        let mut f = std::fs::File::create(&path).unwrap();
        write!(f, "port = \"not_a_number\"\n").unwrap();
        let config = load_config_from(&path);
        // Should return defaults since the file fails to parse
        assert!(config.port.is_none());
    }
}
