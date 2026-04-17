#[cfg(test)]
mod tests {
    use std::io::Write;
    use tempfile::TempDir;

    use crate::scanner::{self, db};

    fn setup_test_db(tmp: &TempDir) -> (std::path::PathBuf, std::path::PathBuf) {
        let projects = tmp.path().join("projects").join("user").join("proj");
        std::fs::create_dir_all(&projects).unwrap();
        let filepath = projects.join("sess.jsonl");
        let mut f = std::fs::File::create(&filepath).unwrap();
        let today = chrono::Local::now()
            .format("%Y-%m-%dT10:00:00Z")
            .to_string();
        writeln!(
            f,
            "{}",
            serde_json::json!({
                "type": "user", "sessionId": "s1", "timestamp": &today, "cwd": "/home/user/project"
            })
        )
        .unwrap();
        writeln!(
            f,
            "{}",
            serde_json::json!({
                "type": "assistant", "sessionId": "s1", "timestamp": &today,
                "cwd": "/home/user/project",
                "message": {
                    "id": "msg-1", "model": "claude-sonnet-4-6",
                    "usage": { "input_tokens": 1000, "output_tokens": 500, "cache_read_input_tokens": 100, "cache_creation_input_tokens": 50 },
                    "content": []
                }
            })
        )
        .unwrap();

        let db_path = tmp.path().join("usage.db");
        let parent = tmp.path().join("projects");
        scanner::scan(Some(vec![parent.clone()]), &db_path, false).unwrap();
        (db_path, parent)
    }

    #[test]
    fn test_cmd_today_no_data() {
        let tmp = TempDir::new().unwrap();
        let db_path = tmp.path().join("usage.db");
        // Create empty DB
        let conn = db::open_db(&db_path).unwrap();
        db::init_db(&conn).unwrap();
        drop(conn);
        // Should not panic
        crate::cmd_today(&db_path, false).unwrap();
    }

    #[test]
    fn test_cmd_today_json() {
        let tmp = TempDir::new().unwrap();
        let (db_path, _) = setup_test_db(&tmp);
        // JSON mode should not panic (output goes to stdout)
        crate::cmd_today(&db_path, true).unwrap();
    }

    #[test]
    fn test_cmd_stats_empty_db() {
        let tmp = TempDir::new().unwrap();
        let db_path = tmp.path().join("usage.db");
        let conn = db::open_db(&db_path).unwrap();
        db::init_db(&conn).unwrap();
        drop(conn);
        // Should not panic on empty DB
        crate::cmd_stats(&db_path, false, "USD").unwrap();
    }

    #[test]
    fn test_cmd_stats_json() {
        let tmp = TempDir::new().unwrap();
        let (db_path, _) = setup_test_db(&tmp);
        crate::cmd_stats(&db_path, true, "USD").unwrap();
    }
}
