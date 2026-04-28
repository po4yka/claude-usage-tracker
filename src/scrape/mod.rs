//! HTTP scrape clients for vendor private APIs (Tier 3a, cookie-paste).
//!
//! Each vendor module exposes a `Client` plus `list_conversations()` and
//! `fetch_conversation()` methods. The `scrape` CLI subcommand iterates
//! and writes via `archive::web::write_web_conversation`.

pub mod chatgpt;
pub mod claude;

#[derive(Debug, Clone)]
pub struct ScrapeReport {
    pub vendor: &'static str,
    pub listed: usize,
    pub written: usize,
    pub unchanged: usize,
    pub errors: Vec<String>,
}
