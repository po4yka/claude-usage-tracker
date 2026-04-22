---
name: heimdall-rust-dependency-audit
description: Use when auditing Heimdall Rust dependencies for security advisories, policy violations, or unused dependencies. Covers cargo-audit, cargo-deny, cargo-machete, and report-first dependency analysis.
---

# Heimdall Rust Dependency Audit

Use this skill for dependency, security, license, or unused-dependency audit work in Heimdall.

## Workflow

1. Run `cargo audit` if available; otherwise note the missing tool.
2. If `deny.toml` exists and `cargo deny` is available, run `cargo deny check`.
3. If `cargo machete` is available, run it to find declared but unused dependencies.
4. Summarize the actionable findings.

## Guardrails

- This is report-first.
- Do not create or edit `deny.toml` in this v1 workflow unless the user explicitly asks.
- Do not auto-edit `Cargo.toml` or lockfiles as part of the audit pass.

## Output expectations

- Report which tools were available and which commands were run.
- Group findings into advisories, policy or license issues, and unused dependencies.
- If a fix is obvious, suggest the concrete version bump or cleanup target.
