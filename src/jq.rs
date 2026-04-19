//! Phase 9 — `--jq` post-processing for JSON-producing subcommands.
//!
//! Wraps the `jaq-core` / `jaq-std` / `jaq-json` pure-Rust jq engine so that
//! callers never need to interact with those crates directly.  The filter is
//! compiled once and reused across records in streaming mode.

use anyhow::{Context, Result, anyhow};
use jaq_core::data::JustLut;
use jaq_core::load::{Arena, File, Loader};
use jaq_core::{Compiler, Ctx, Filter, Vars, data, unwrap_valr};
use jaq_json::Val;
use serde_json::Value;

// ── compiled filter ──────────────────────────────────────────────────────────

/// A jq filter that has been parsed and compiled, ready for reuse.
///
/// `Filter<JustLut<Val>>` is the public type alias `jaq_core::Filter<D>` which
/// expands to `compile::Filter<Native<D>>`.
pub struct CompiledJqFilter {
    inner: Filter<JustLut<Val>>,
}

impl CompiledJqFilter {
    /// Parse and compile `filter_str`.  Returns `Err` on parse / compile errors.
    pub fn compile(filter_str: &str) -> Result<Self> {
        let defs = jaq_core::defs().chain(jaq_std::defs());
        let funs = jaq_core::funs::<JustLut<Val>>()
            .chain(jaq_std::funs())
            .chain(jaq_json::funs());

        let loader = Loader::new(defs);
        let arena = Arena::default();

        let program = File {
            code: filter_str,
            path: (),
        };

        let modules = loader.load(&arena, program).map_err(|errors| {
            let msgs: Vec<String> = errors.iter().map(|(_file, e)| format!("{e:?}")).collect();
            anyhow!("failed to parse jq filter: {}", msgs.join("; "))
        })?;

        let filter = Compiler::<_, JustLut<Val>>::default()
            .with_funs(funs)
            .compile(modules)
            .map_err(|errors| {
                let msgs: Vec<String> = errors.iter().map(|(_file, e)| format!("{e:?}")).collect();
                anyhow!("failed to compile jq filter: {}", msgs.join("; "))
            })?;

        Ok(Self { inner: filter })
    }

    /// Apply the compiled filter to a `serde_json::Value`.
    pub fn apply(&self, value: &Value) -> Result<JqResult> {
        let input = serde_to_jaq(value)?;
        let outputs = self.run(input)?;
        Ok(render_outputs(outputs))
    }

    /// Run the compiled filter against a single `Val` input, collecting all outputs.
    fn run(&self, input: Val) -> Result<Vec<Val>> {
        let ctx = Ctx::<data::JustLut<Val>>::new(&self.inner.lut, Vars::new([]));
        self.inner
            .id
            .run((ctx, input))
            .map(unwrap_valr)
            .map(|r| r.map_err(|e| anyhow!("jq runtime error: {e}")))
            .collect()
    }
}

// ── public API ───────────────────────────────────────────────────────────────

/// The result of applying a jq filter to a JSON value.
#[derive(Debug)]
pub enum JqResult {
    /// A single output value, rendered as JSON.
    Single(String),
    /// Multiple output values, one compact JSON line each.
    Multiple(Vec<String>),
    /// No output produced (filter returned nothing / null-only).
    Empty,
}

/// Convert a `serde_json::Value` to a `jaq_json::Val` by serialising to bytes
/// then parsing — guaranteed lossless for standard JSON.
fn serde_to_jaq(value: &Value) -> Result<Val> {
    let bytes = serde_json::to_vec(value).context("serialising value for jq")?;
    jaq_json::read::parse_single(&bytes).map_err(|e| anyhow!("internal jq conversion error: {e}"))
}

/// Render a `Vec<Val>` into a `JqResult`.
///
/// `null` is a printable value like any other — filters that produce `null`
/// (e.g. accessing a missing field) yield `Single("null")`.
/// `JqResult::Empty` is reserved for filters that produce ZERO values
/// (e.g. `empty`, `select` that never matches, iterating an empty array).
/// All outputs are rendered compact (`{}`) for scriptability.
fn render_outputs(outputs: Vec<Val>) -> JqResult {
    match outputs.len() {
        0 => JqResult::Empty,
        1 => JqResult::Single(format!("{}", outputs[0])),
        _ => JqResult::Multiple(outputs.iter().map(|v| format!("{v}")).collect()),
    }
}

/// Apply a jq `filter` to a `serde_json::Value`.
///
/// - Zero outputs (e.g. `empty`, `select` that never matches) → [`JqResult::Empty`]
/// - One output (including `null`) → [`JqResult::Single`] (compact JSON)
/// - Multiple outputs → [`JqResult::Multiple`] (one compact JSON line each)
/// - Parse / compile / runtime errors → `Err`
pub fn apply(value: &Value, filter: &str) -> Result<JqResult> {
    let compiled = CompiledJqFilter::compile(filter)?;
    let input = serde_to_jaq(value)?;
    let outputs = compiled.run(input)?;
    Ok(render_outputs(outputs))
}

/// Streaming variant: apply `filter` to each JSONL line in `reader`, writing
/// results to `writer`.  The filter is compiled once before processing begins.
pub fn apply_stream<R: std::io::BufRead, W: std::io::Write>(
    reader: R,
    writer: &mut W,
    filter: &str,
) -> Result<()> {
    let compiled = CompiledJqFilter::compile(filter)?;

    for (line_no, line) in reader.lines().enumerate() {
        let line = line.with_context(|| format!("reading JSONL line {line_no}"))?;
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        let input = jaq_json::read::parse_single(trimmed.as_bytes())
            .map_err(|e| anyhow!("jq: JSONL line {line_no}: parse error: {e}"))?;

        let outputs = compiled.run(input)?;

        for v in &outputs {
            writeln!(writer, "{v}")
                .with_context(|| format!("writing jq output at line {line_no}"))?;
        }
    }

    Ok(())
}

// ── tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn apply_ok(value: &Value, filter: &str) -> JqResult {
        apply(value, filter).expect("apply should succeed")
    }

    fn jq_result_variant(r: &JqResult) -> &'static str {
        match r {
            JqResult::Single(_) => "Single",
            JqResult::Multiple(_) => "Multiple",
            JqResult::Empty => "Empty",
        }
    }

    // ── apply tests ──────────────────────────────────────────────────────────

    #[test]
    fn passthrough_object() {
        let v = json!({"a": 1, "b": "hello"});
        match apply_ok(&v, ".") {
            JqResult::Single(s) => {
                let reparsed: Value = serde_json::from_str(&s).unwrap();
                assert_eq!(reparsed, v);
            }
            other => panic!("expected Single, got {}", jq_result_variant(&other)),
        }
    }

    #[test]
    fn extract_number_field() {
        let v = json!({"total": 1.23, "other": "x"});
        match apply_ok(&v, ".total") {
            JqResult::Single(s) => {
                let n: f64 = serde_json::from_str(&s).unwrap();
                assert!((n - 1.23).abs() < 1e-9, "expected 1.23, got {s}");
            }
            other => panic!("expected Single, got {}", jq_result_variant(&other)),
        }
    }

    #[test]
    fn array_iteration_gives_multiple() {
        let v = json!({"models": ["a", "b", "c"]});
        match apply_ok(&v, ".models[]") {
            JqResult::Multiple(vs) => {
                assert_eq!(vs.len(), 3);
                assert_eq!(vs[0], "\"a\"");
                assert_eq!(vs[1], "\"b\"");
                assert_eq!(vs[2], "\"c\"");
            }
            other => panic!("expected Multiple, got {}", jq_result_variant(&other)),
        }
    }

    #[test]
    fn missing_field_returns_null() {
        // `.missing_field` on an object returns null — null is a printable value.
        let v = json!({"a": 1});
        match apply_ok(&v, ".missing_field") {
            JqResult::Single(s) => assert_eq!(s, "null"),
            other => panic!(
                "expected Single(\"null\"), got {}",
                jq_result_variant(&other)
            ),
        }
    }

    #[test]
    fn explicit_null_filter_returns_null() {
        let v = json!({"a": 1});
        match apply_ok(&v, "null") {
            JqResult::Single(s) => assert_eq!(s, "null"),
            other => panic!(
                "expected Single(\"null\"), got {}",
                jq_result_variant(&other)
            ),
        }
    }

    #[test]
    fn empty_filter_returns_empty() {
        let v = json!({"a": 1});
        match apply_ok(&v, "empty") {
            JqResult::Empty => {}
            other => panic!(
                "expected Empty for `empty` filter, got {}",
                jq_result_variant(&other)
            ),
        }
    }

    #[test]
    fn empty_array_iteration_returns_empty() {
        let v = json!({"arr": []});
        match apply_ok(&v, ".arr[]") {
            JqResult::Empty => {}
            other => panic!(
                "expected Empty for empty array iteration, got {}",
                jq_result_variant(&other)
            ),
        }
    }

    #[test]
    fn pipe_to_tostring() {
        let v = json!({"total": 1.23});
        match apply_ok(&v, ".total | tostring") {
            JqResult::Single(s) => {
                assert!(s.contains("1.23"), "expected 1.23 in output, got {s}");
            }
            other => panic!("expected Single, got {}", jq_result_variant(&other)),
        }
    }

    #[test]
    fn conditional_expression() {
        let yes = json!({"x": 5});
        let no = json!({"x": -1});
        match apply_ok(&yes, r#"if .x > 0 then "yes" else "no" end"#) {
            JqResult::Single(s) => assert_eq!(s, "\"yes\""),
            other => panic!("expected Single(yes), got {}", jq_result_variant(&other)),
        }
        match apply_ok(&no, r#"if .x > 0 then "yes" else "no" end"#) {
            JqResult::Single(s) => assert_eq!(s, "\"no\""),
            other => panic!("expected Single(no), got {}", jq_result_variant(&other)),
        }
    }

    #[test]
    fn invalid_filter_returns_error() {
        let v = json!({});
        let result = apply(&v, "{.");
        assert!(result.is_err(), "expected Err for invalid filter");
        let msg = format!("{}", result.unwrap_err());
        assert!(
            msg.contains("jq filter") || msg.contains("parse") || msg.contains("compile"),
            "error message should mention filter/parse/compile: {msg}"
        );
    }

    #[test]
    fn arithmetic_addition() {
        let v = json!({"a": 3, "b": 4});
        match apply_ok(&v, ".a + .b") {
            JqResult::Single(s) => {
                let n: i64 = serde_json::from_str(&s).unwrap();
                assert_eq!(n, 7);
            }
            other => panic!("expected Single, got {}", jq_result_variant(&other)),
        }
    }

    #[test]
    fn array_length() {
        let v = json!({"weeks": [1, 2, 3]});
        match apply_ok(&v, ".weeks | length") {
            JqResult::Single(s) => {
                let n: i64 = serde_json::from_str(&s).unwrap();
                assert_eq!(n, 3);
            }
            other => panic!("expected Single, got {}", jq_result_variant(&other)),
        }
    }

    // ── apply_stream tests ───────────────────────────────────────────────────

    #[test]
    fn stream_extracts_field_per_line() {
        let jsonl = b"{\"model\":\"A\"}\n{\"model\":\"B\"}\n{\"model\":\"C\"}\n" as &[u8];
        let mut out = Vec::new();
        apply_stream(jsonl, &mut out, ".model").unwrap();
        let s = String::from_utf8(out).unwrap();
        let lines: Vec<&str> = s.lines().collect();
        assert_eq!(lines.len(), 3);
        assert_eq!(lines[0], "\"A\"");
        assert_eq!(lines[1], "\"B\"");
        assert_eq!(lines[2], "\"C\"");
    }

    #[test]
    fn stream_empty_input_produces_no_output() {
        let jsonl = b"" as &[u8];
        let mut out = Vec::new();
        apply_stream(jsonl, &mut out, ".model").unwrap();
        assert!(out.is_empty());
    }

    #[test]
    fn stream_filter_error_propagates() {
        let jsonl = b"{\"x\":1}\n" as &[u8];
        let mut out = Vec::new();
        let result = apply_stream(jsonl, &mut out, "{.");
        assert!(
            result.is_err(),
            "expected Err for bad filter in stream mode"
        );
    }
}
