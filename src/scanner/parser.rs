use std::collections::HashMap;
use std::io::{BufRead, BufReader};
use std::path::Path;
use tracing::warn;

use crate::models::{Session, SessionMeta, Turn};

/// Derive a friendly project name from cwd (last 2 path components).
pub fn project_name_from_cwd(cwd: &str) -> String {
    if cwd.is_empty() {
        return "unknown".into();
    }
    let normalized = cwd.replace('\\', "/");
    let trimmed = normalized.trim_end_matches('/');
    let parts: Vec<&str> = trimmed.split('/').collect();
    match parts.len() {
        0 => "unknown".into(),
        1 => parts[0].to_string(),
        _ => format!("{}/{}", parts[parts.len() - 2], parts[parts.len() - 1]),
    }
}

pub struct ParseResult {
    pub session_metas: Vec<SessionMeta>,
    pub turns: Vec<Turn>,
    pub line_count: i64,
}

/// Parse a JSONL file, deduplicating streaming events by message.id.
/// If `skip_lines > 0`, skips that many lines from the start (for incremental updates).
pub fn parse_jsonl_file(filepath: &Path, skip_lines: i64) -> ParseResult {
    let mut seen_messages: HashMap<String, Turn> = HashMap::new();
    let mut turns_no_id: Vec<Turn> = Vec::new();
    let mut session_meta: HashMap<String, SessionMeta> = HashMap::new();
    let mut line_count: i64 = 0;

    let file = match std::fs::File::open(filepath) {
        Ok(f) => f,
        Err(e) => {
            warn!("Error opening {}: {}", filepath.display(), e);
            return ParseResult {
                session_metas: vec![],
                turns: vec![],
                line_count: 0,
            };
        }
    };

    let reader = BufReader::new(file);
    for line_result in reader.lines() {
        line_count += 1;
        if line_count <= skip_lines {
            continue;
        }

        let line = match line_result {
            Ok(l) => l,
            Err(_) => continue,
        };
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        let record: serde_json::Value = match serde_json::from_str(trimmed) {
            Ok(v) => v,
            Err(_) => continue,
        };

        let rtype = record.get("type").and_then(|v| v.as_str()).unwrap_or("");
        if rtype != "assistant" && rtype != "user" {
            continue;
        }

        let session_id = match record.get("sessionId").and_then(|v| v.as_str()) {
            Some(s) if !s.is_empty() => s.to_string(),
            _ => continue,
        };

        let timestamp = record
            .get("timestamp")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let cwd = record
            .get("cwd")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let git_branch = record
            .get("gitBranch")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let entrypoint = record
            .get("entrypoint")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let slug = record
            .get("slug")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let is_subagent = record
            .get("isSidechain")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        let agent_id = record
            .get("agentId")
            .and_then(|v| v.as_str())
            .map(String::from);

        // Update session metadata
        session_meta
            .entry(session_id.clone())
            .and_modify(|meta| {
                if !timestamp.is_empty() {
                    if meta.first_timestamp.is_empty() || timestamp < meta.first_timestamp {
                        meta.first_timestamp = timestamp.clone();
                    }
                    if meta.last_timestamp.is_empty() || timestamp > meta.last_timestamp {
                        meta.last_timestamp = timestamp.clone();
                    }
                }
                if !git_branch.is_empty() && meta.git_branch.is_empty() {
                    meta.git_branch.clone_from(&git_branch);
                }
            })
            .or_insert_with(|| SessionMeta {
                session_id: session_id.clone(),
                project_name: project_name_from_cwd(&cwd),
                project_slug: slug.clone(),
                first_timestamp: timestamp.clone(),
                last_timestamp: timestamp.clone(),
                git_branch: git_branch.clone(),
                model: None,
                entrypoint: entrypoint.clone(),
            });

        if rtype == "assistant" {
            let msg = match record.get("message") {
                Some(m) => m,
                None => continue,
            };
            let usage = msg
                .get("usage")
                .cloned()
                .unwrap_or(serde_json::Value::Object(Default::default()));
            let model = msg
                .get("model")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();
            let message_id = msg
                .get("id")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();

            let input_tokens = usage
                .get("input_tokens")
                .and_then(|v| v.as_i64())
                .unwrap_or(0);
            let output_tokens = usage
                .get("output_tokens")
                .and_then(|v| v.as_i64())
                .unwrap_or(0);
            let cache_read = usage
                .get("cache_read_input_tokens")
                .and_then(|v| v.as_i64())
                .unwrap_or(0);
            let cache_creation = usage
                .get("cache_creation_input_tokens")
                .and_then(|v| v.as_i64())
                .unwrap_or(0);

            // Skip zero-token records
            if input_tokens + output_tokens + cache_read + cache_creation == 0 {
                continue;
            }

            // Extract tool name
            let tool_name = msg
                .get("content")
                .and_then(|c| c.as_array())
                .and_then(|arr| {
                    arr.iter()
                        .find(|item| item.get("type").and_then(|t| t.as_str()) == Some("tool_use"))
                })
                .and_then(|item| item.get("name").and_then(|n| n.as_str()))
                .map(String::from);

            let service_tier = usage
                .get("service_tier")
                .and_then(|v| v.as_str())
                .map(String::from);
            let inference_geo = usage
                .get("inference_geo")
                .and_then(|v| v.as_str())
                .map(String::from);

            if !model.is_empty()
                && let Some(meta) = session_meta.get_mut(&session_id)
            {
                meta.model = Some(model.clone());
            }

            let turn = Turn {
                session_id: session_id.clone(),
                timestamp: timestamp.clone(),
                model,
                input_tokens,
                output_tokens,
                cache_read_tokens: cache_read,
                cache_creation_tokens: cache_creation,
                tool_name,
                cwd,
                message_id: message_id.clone(),
                service_tier,
                inference_geo,
                is_subagent,
                agent_id: agent_id.clone(),
            };

            if !message_id.is_empty() {
                seen_messages.insert(message_id, turn);
            } else {
                turns_no_id.push(turn);
            }
        }
    }

    let mut turns = turns_no_id;
    turns.extend(seen_messages.into_values());

    ParseResult {
        session_metas: session_meta.into_values().collect(),
        turns,
        line_count,
    }
}

/// Aggregate turn data into session-level stats.
pub fn aggregate_sessions(metas: &[SessionMeta], turns: &[Turn]) -> Vec<Session> {
    struct Stats {
        total_input: i64,
        total_output: i64,
        total_cache_read: i64,
        total_cache_creation: i64,
        turn_count: i64,
        model: Option<String>,
    }

    let mut stats_map: HashMap<&str, Stats> = HashMap::new();
    for t in turns {
        let entry = stats_map.entry(&t.session_id).or_insert(Stats {
            total_input: 0,
            total_output: 0,
            total_cache_read: 0,
            total_cache_creation: 0,
            turn_count: 0,
            model: None,
        });
        entry.total_input += t.input_tokens;
        entry.total_output += t.output_tokens;
        entry.total_cache_read += t.cache_read_tokens;
        entry.total_cache_creation += t.cache_creation_tokens;
        entry.turn_count += 1;
        if !t.model.is_empty() {
            entry.model = Some(t.model.clone());
        }
    }

    metas
        .iter()
        .map(|meta| {
            let empty = Stats {
                total_input: 0,
                total_output: 0,
                total_cache_read: 0,
                total_cache_creation: 0,
                turn_count: 0,
                model: None,
            };
            let s = stats_map.get(meta.session_id.as_str()).unwrap_or(&empty);
            Session {
                session_id: meta.session_id.clone(),
                project_name: meta.project_name.clone(),
                project_slug: meta.project_slug.clone(),
                first_timestamp: meta.first_timestamp.clone(),
                last_timestamp: meta.last_timestamp.clone(),
                git_branch: meta.git_branch.clone(),
                model: s.model.clone().or_else(|| meta.model.clone()),
                entrypoint: meta.entrypoint.clone(),
                total_input_tokens: s.total_input,
                total_output_tokens: s.total_output,
                total_cache_read: s.total_cache_read,
                total_cache_creation: s.total_cache_creation,
                turn_count: s.turn_count,
            }
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::TempDir;

    fn make_assistant_record(
        session_id: &str,
        model: &str,
        input: i64,
        output: i64,
        message_id: &str,
    ) -> String {
        let mut msg = serde_json::json!({
            "model": model,
            "usage": {
                "input_tokens": input,
                "output_tokens": output,
                "cache_read_input_tokens": 0,
                "cache_creation_input_tokens": 0,
            },
            "content": [],
        });
        if !message_id.is_empty() {
            msg["id"] = serde_json::json!(message_id);
        }
        serde_json::json!({
            "type": "assistant",
            "sessionId": session_id,
            "timestamp": "2026-04-08T10:00:00Z",
            "cwd": "/home/user/project",
            "message": msg,
        })
        .to_string()
    }

    fn make_user_record(session_id: &str) -> String {
        serde_json::json!({
            "type": "user",
            "sessionId": session_id,
            "timestamp": "2026-04-08T09:59:00Z",
            "cwd": "/home/user/project",
        })
        .to_string()
    }

    fn write_jsonl(dir: &TempDir, name: &str, lines: &[String]) -> std::path::PathBuf {
        let path = dir.path().join(name);
        let mut f = std::fs::File::create(&path).unwrap();
        for line in lines {
            writeln!(f, "{}", line).unwrap();
        }
        path
    }

    #[test]
    fn test_project_name_from_cwd() {
        assert_eq!(project_name_from_cwd("/home/user/project"), "user/project");
        assert_eq!(project_name_from_cwd("C:\\Users\\me\\proj"), "me/proj");
        assert_eq!(project_name_from_cwd("/a/b/c/d"), "c/d");
        assert_eq!(project_name_from_cwd(""), "unknown");
        assert_eq!(project_name_from_cwd("/home/user/project/"), "user/project");
    }

    #[test]
    fn test_basic_parsing() {
        let dir = TempDir::new().unwrap();
        let path = write_jsonl(
            &dir,
            "test.jsonl",
            &[
                make_user_record("s1"),
                make_assistant_record("s1", "claude-sonnet-4-6", 100, 50, ""),
            ],
        );
        let result = parse_jsonl_file(&path, 0);
        assert_eq!(result.session_metas.len(), 1);
        assert_eq!(result.turns.len(), 1);
        assert_eq!(result.turns[0].input_tokens, 100);
        assert_eq!(result.line_count, 2);
    }

    #[test]
    fn test_skips_zero_tokens() {
        let dir = TempDir::new().unwrap();
        let path = write_jsonl(
            &dir,
            "test.jsonl",
            &[make_assistant_record("s1", "claude-sonnet-4-6", 0, 0, "")],
        );
        let result = parse_jsonl_file(&path, 0);
        assert_eq!(result.turns.len(), 0);
    }

    #[test]
    fn test_streaming_dedup() {
        let dir = TempDir::new().unwrap();
        let path = write_jsonl(
            &dir,
            "test.jsonl",
            &[
                make_assistant_record("s1", "claude-sonnet-4-6", 50, 10, "msg-1"),
                make_assistant_record("s1", "claude-sonnet-4-6", 100, 50, "msg-1"),
                make_assistant_record("s1", "claude-sonnet-4-6", 150, 80, "msg-1"),
            ],
        );
        let result = parse_jsonl_file(&path, 0);
        assert_eq!(result.turns.len(), 1);
        assert_eq!(result.turns[0].input_tokens, 150);
    }

    #[test]
    fn test_different_message_ids_kept() {
        let dir = TempDir::new().unwrap();
        let path = write_jsonl(
            &dir,
            "test.jsonl",
            &[
                make_assistant_record("s1", "claude-sonnet-4-6", 100, 50, "msg-1"),
                make_assistant_record("s1", "claude-sonnet-4-6", 200, 100, "msg-2"),
            ],
        );
        let result = parse_jsonl_file(&path, 0);
        assert_eq!(result.turns.len(), 2);
    }

    #[test]
    fn test_skip_lines() {
        let dir = TempDir::new().unwrap();
        let path = write_jsonl(
            &dir,
            "test.jsonl",
            &[
                make_assistant_record("s1", "claude-sonnet-4-6", 100, 50, "msg-1"),
                make_assistant_record("s1", "claude-sonnet-4-6", 200, 100, "msg-2"),
            ],
        );
        let result = parse_jsonl_file(&path, 1);
        assert_eq!(result.turns.len(), 1);
        assert_eq!(result.turns[0].input_tokens, 200);
        assert_eq!(result.line_count, 2);
    }

    #[test]
    fn test_malformed_json_skipped() {
        let dir = TempDir::new().unwrap();
        let path = write_jsonl(
            &dir,
            "test.jsonl",
            &[
                "not valid json".into(),
                make_assistant_record("s1", "claude-sonnet-4-6", 100, 50, ""),
            ],
        );
        let result = parse_jsonl_file(&path, 0);
        assert_eq!(result.turns.len(), 1);
    }

    #[test]
    fn test_aggregate_sessions() {
        let metas = vec![SessionMeta {
            session_id: "s1".into(),
            project_name: "test".into(),
            ..Default::default()
        }];
        let turns = vec![
            Turn {
                session_id: "s1".into(),
                input_tokens: 100,
                output_tokens: 50,
                model: "claude-sonnet-4-6".into(),
                ..Default::default()
            },
            Turn {
                session_id: "s1".into(),
                input_tokens: 200,
                output_tokens: 100,
                model: "claude-sonnet-4-6".into(),
                ..Default::default()
            },
        ];
        let sessions = aggregate_sessions(&metas, &turns);
        assert_eq!(sessions.len(), 1);
        assert_eq!(sessions[0].total_input_tokens, 300);
        assert_eq!(sessions[0].total_output_tokens, 150);
        assert_eq!(sessions[0].turn_count, 2);
    }

    #[test]
    fn test_subagent_record_parsed() {
        let dir = TempDir::new().unwrap();
        let record = serde_json::json!({
            "type": "assistant", "sessionId": "s1",
            "timestamp": "2026-04-08T10:00:00Z", "cwd": "/home/user/project",
            "isSidechain": true, "agentId": "agent-xyz",
            "message": {
                "model": "claude-sonnet-4-6", "id": "msg-sub1",
                "usage": { "input_tokens": 100, "output_tokens": 50, "cache_read_input_tokens": 0, "cache_creation_input_tokens": 0 },
                "content": [],
            },
        })
        .to_string();
        let path = write_jsonl(&dir, "test.jsonl", &[record]);
        let result = parse_jsonl_file(&path, 0);
        assert_eq!(result.turns.len(), 1);
        assert!(result.turns[0].is_subagent);
        assert_eq!(result.turns[0].agent_id.as_deref(), Some("agent-xyz"));
    }

    #[test]
    fn test_non_subagent_default() {
        let dir = TempDir::new().unwrap();
        let path = write_jsonl(
            &dir,
            "test.jsonl",
            &[make_assistant_record(
                "s1",
                "claude-sonnet-4-6",
                100,
                50,
                "msg-1",
            )],
        );
        let result = parse_jsonl_file(&path, 0);
        assert!(!result.turns[0].is_subagent);
        assert!(result.turns[0].agent_id.is_none());
    }

    #[test]
    fn test_service_tier_extracted() {
        let dir = TempDir::new().unwrap();
        let record = serde_json::json!({
            "type": "assistant", "sessionId": "s1",
            "timestamp": "2026-04-08T10:00:00Z", "cwd": "/tmp",
            "message": {
                "model": "claude-sonnet-4-6", "id": "msg-1",
                "usage": {
                    "input_tokens": 100, "output_tokens": 50,
                    "cache_read_input_tokens": 0, "cache_creation_input_tokens": 0,
                    "service_tier": "standard", "inference_geo": "us"
                },
                "content": [],
            },
        })
        .to_string();
        let path = write_jsonl(&dir, "test.jsonl", &[record]);
        let result = parse_jsonl_file(&path, 0);
        assert_eq!(result.turns[0].service_tier.as_deref(), Some("standard"));
        assert_eq!(result.turns[0].inference_geo.as_deref(), Some("us"));
    }

    #[test]
    fn test_tool_name_first_of_multiple() {
        let dir = TempDir::new().unwrap();
        let record = serde_json::json!({
            "type": "assistant", "sessionId": "s1",
            "timestamp": "2026-04-08T10:00:00Z", "cwd": "/tmp",
            "message": {
                "model": "claude-sonnet-4-6",
                "usage": { "input_tokens": 100, "output_tokens": 50, "cache_read_input_tokens": 0, "cache_creation_input_tokens": 0 },
                "content": [
                    { "type": "text", "text": "hello" },
                    { "type": "tool_use", "name": "Read" },
                    { "type": "tool_use", "name": "Write" }
                ],
            },
        })
        .to_string();
        let path = write_jsonl(&dir, "test.jsonl", &[record]);
        let result = parse_jsonl_file(&path, 0);
        assert_eq!(result.turns[0].tool_name.as_deref(), Some("Read"));
    }
}
