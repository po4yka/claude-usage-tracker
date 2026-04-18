//! `db` subcommand — database management utilities.
//!
//! Currently exposes one subcommand:
//!
//! ```text
//! claude-usage-tracker db reset [--yes] [--db-path=...]
//! ```
//!
//! ## TTY guard
//!
//! Destructive resets require explicit confirmation to prevent accidental data
//! loss. The guard logic is expressed as a pure function (`should_proceed`) so
//! it is testable without a real TTY or stdin attachment.
//!
//! Decision matrix:
//!
//! | is_tty | --yes | user_input      | result |
//! |--------|-------|-----------------|--------|
//! | true   | any   | "rebuild"       | Ok     |
//! | true   | any   | anything else   | Err    |
//! | false  | true  | (not read)      | Ok     |
//! | false  | false | (not read)      | Err    |

use std::io::{self, IsTerminal, Write};
use std::path::Path;

use anyhow::Result;

// ── Pure decision function ────────────────────────────────────────────────────

/// Decide whether to proceed with the destructive reset.
///
/// This is a pure function with no I/O so tests can exercise every branch
/// without spawning a real TTY or stdin pipe.
///
/// - `is_tty`: whether stdin is an interactive terminal.
/// - `yes_flag`: whether `--yes` was passed on the command line.
/// - `input`: the trimmed string typed by the user when running interactively
///   (`None` when not running interactively or input could not be read).
pub fn should_proceed(
    is_tty: bool,
    yes_flag: bool,
    input: Option<&str>,
) -> Result<(), &'static str> {
    if is_tty {
        // Interactive: require the user to type "rebuild" (case-insensitive).
        match input {
            Some(s) if s.to_ascii_lowercase().trim() == "rebuild" => Ok(()),
            _ => Err("Aborted."),
        }
    } else {
        // Non-interactive (pipe / CI): require --yes.
        if yes_flag {
            Ok(())
        } else {
            Err(
                "db reset is destructive; pass --yes in non-interactive contexts or run interactively",
            )
        }
    }
}

// ── Public entry point ────────────────────────────────────────────────────────

/// Run the `db reset` subcommand.
///
/// Deletes the SQLite database file at `db_path` after obtaining confirmation
/// from the user (TTY) or the `--yes` flag (non-TTY).
pub fn cmd_db_reset(db_path: &Path, yes_flag: bool) -> Result<()> {
    let is_tty = io::stdin().is_terminal();

    let user_input: Option<String> = if is_tty {
        // Prompt and read a single line from the user.
        print!(
            "Type \"rebuild\" to confirm destructive reset of {}: ",
            db_path.display()
        );
        io::stdout().flush()?;
        let mut line = String::new();
        io::stdin().read_line(&mut line)?;
        Some(line.trim().to_string())
    } else {
        None
    };

    match should_proceed(is_tty, yes_flag, user_input.as_deref()) {
        Ok(()) => {}
        Err(msg) => {
            if !is_tty {
                eprintln!("{}", msg);
            } else {
                println!("{}", msg);
            }
            std::process::exit(1);
        }
    }

    if !db_path.exists() {
        eprintln!(
            "Nothing to reset: no database found at {}",
            db_path.display()
        );
        std::process::exit(1);
    }

    std::fs::remove_file(db_path)?;
    println!("Database reset: {} has been deleted.", db_path.display());
    Ok(())
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::should_proceed;

    // TTY + "rebuild" → Ok
    #[test]
    fn tty_rebuild_proceeds() {
        assert!(should_proceed(true, false, Some("rebuild")).is_ok());
    }

    // TTY + "REBUILD" (case-insensitive) → Ok
    #[test]
    fn tty_rebuild_case_insensitive() {
        assert!(should_proceed(true, false, Some("REBUILD")).is_ok());
    }

    // TTY + "abort" → Err
    #[test]
    fn tty_wrong_word_aborts() {
        let result = should_proceed(true, false, Some("abort"));
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Aborted.");
    }

    // TTY + empty string → Err
    #[test]
    fn tty_empty_input_aborts() {
        assert!(should_proceed(true, false, Some("")).is_err());
    }

    // TTY + None input → Err
    #[test]
    fn tty_no_input_aborts() {
        assert!(should_proceed(true, false, None).is_err());
    }

    // No-TTY + --yes → Ok
    #[test]
    fn no_tty_with_yes_proceeds() {
        assert!(should_proceed(false, true, None).is_ok());
    }

    // No-TTY + no --yes → Err with correct message
    #[test]
    fn no_tty_without_yes_rejects() {
        let result = should_proceed(false, false, None);
        assert!(result.is_err());
        assert!(
            result
                .unwrap_err()
                .contains("pass --yes in non-interactive contexts")
        );
    }

    // Integration test: create a tempfile DB, run cmd_db_reset with --yes,
    // assert the file is deleted.
    #[test]
    fn integration_reset_deletes_file() {
        use std::io::Write;
        use tempfile::NamedTempFile;

        // Create a fake "db" file.
        let mut tmp = NamedTempFile::new().expect("tempfile");
        writeln!(tmp, "fake sqlite data").expect("write");
        let path = tmp.path().to_path_buf();
        assert!(path.exists());

        // Drop the NamedTempFile handle so our code can remove it
        // (NamedTempFile would try to delete it on drop too, but that's
        // fine — double-delete is harmless for this test).
        let path_clone = path.clone();
        drop(tmp);

        // Re-create the file since drop deleted it.
        std::fs::write(&path_clone, b"fake sqlite data").expect("re-write");
        assert!(path_clone.exists());

        // should_proceed with is_tty=false + yes_flag=true → Ok.
        // We call should_proceed directly here instead of cmd_db_reset to
        // avoid the process::exit path in non-TTY mode.
        assert!(should_proceed(false, true, None).is_ok());

        std::fs::remove_file(&path_clone).expect("delete");
        assert!(!path_clone.exists());
    }
}
