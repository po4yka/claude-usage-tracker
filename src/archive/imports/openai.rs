//! OpenAI ChatGPT export parser.
//!
//! Reads `conversations.json` from a ChatGPT data export ZIP. Schema is
//! the publicly-observed mapping/messages tree; unknown fields are
//! preserved via `#[serde(flatten)] extras: HashMap<String, Value>` so a
//! schema bump doesn't drop user data.

use std::collections::HashMap;
use std::io::Read;

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Conversation {
    pub id: Option<String>,
    pub conversation_id: Option<String>,
    pub title: Option<String>,
    pub create_time: Option<f64>,
    pub update_time: Option<f64>,
    pub current_node: Option<String>,
    pub is_archived: Option<bool>,
    #[serde(default)]
    pub mapping: HashMap<String, Node>,
    #[serde(flatten)]
    pub extras: HashMap<String, Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Node {
    pub id: String,
    pub message: Option<Message>,
    pub parent: Option<String>,
    #[serde(default)]
    pub children: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub id: String,
    pub author: Option<Author>,
    pub create_time: Option<f64>,
    pub update_time: Option<f64>,
    pub content: Option<Content>,
    pub status: Option<String>,
    #[serde(flatten)]
    pub extras: HashMap<String, Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Author {
    pub role: Option<String>,
    pub name: Option<String>,
    #[serde(flatten)]
    pub extras: HashMap<String, Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Content {
    pub content_type: Option<String>,
    #[serde(default)]
    pub parts: Vec<Value>,
    #[serde(flatten)]
    pub extras: HashMap<String, Value>,
}

/// Parse `conversations.json` bytes from an OpenAI export.
pub fn parse_conversations(bytes: &[u8]) -> Result<Vec<Conversation>> {
    serde_json::from_slice(bytes).context("parsing OpenAI conversations.json")
}

/// Resolve the canonical conversation id (prefers `conversation_id`, falls back to `id`).
pub fn conversation_key(conv: &Conversation) -> Option<String> {
    conv.conversation_id.clone().or_else(|| conv.id.clone())
}

/// Read `conversations.json` out of a ZIP archive.
pub fn read_conversations_from_zip<R: Read + std::io::Seek>(
    zip: &mut zip::ZipArchive<R>,
) -> Result<Vec<Conversation>> {
    let mut entry = zip
        .by_name("conversations.json")
        .context("zip missing conversations.json")?;
    let mut buf = Vec::with_capacity(entry.size() as usize);
    entry.read_to_end(&mut buf)?;
    parse_conversations(&buf)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_minimal_conversation() {
        let json = serde_json::json!([{
            "id": "conv-1",
            "title": "Hello",
            "create_time": 1_700_000_000.0,
            "mapping": {
                "n1": { "id": "n1", "parent": null, "children": ["n2"], "message": null },
                "n2": { "id": "n2", "parent": "n1", "children": [],
                        "message": { "id": "m1", "author": { "role": "user" },
                                     "content": { "content_type": "text", "parts": ["hi"] } } }
            }
        }]);
        let convs: Vec<Conversation> = serde_json::from_value(json).unwrap();
        assert_eq!(convs.len(), 1);
        assert_eq!(convs[0].mapping.len(), 2);
        assert_eq!(conversation_key(&convs[0]).as_deref(), Some("conv-1"));
    }

    #[test]
    fn unknown_top_level_fields_round_trip_via_extras() {
        let json = serde_json::json!([{
            "id": "c", "mapping": {}, "tomorrows_field": { "x": 1 }
        }]);
        let convs: Vec<Conversation> = serde_json::from_value(json).unwrap();
        assert!(convs[0].extras.contains_key("tomorrows_field"));
    }

    #[test]
    fn empty_array_parses() {
        let convs = parse_conversations(b"[]").unwrap();
        assert!(convs.is_empty());
    }
}
