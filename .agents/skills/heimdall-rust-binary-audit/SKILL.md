---
name: heimdall-rust-binary-audit
description: Use when auditing Heimdall release binary size and Rust dependency bloat. Covers release builds, cargo-bloat analysis, dependency-tree inspection, and report-first size reduction guidance.
---

# Heimdall Rust Binary Audit

Use this skill when the task is to inspect binary size, release bloat, or likely heavy dependencies in Heimdall.

## Workflow

1. Build the release binary if needed.
2. Report the release binary size.
3. If `cargo bloat` is available, inspect crate and function contributors.
4. Inspect the dependency tree at a high level.
5. Summarize the largest contributors and concrete reduction options.

## Guardrails

- This is report-first.
- Do not change release profile settings or dependency features unless the user asks for implementation.
- Call out uncertainty when optional tooling such as `cargo bloat` is unavailable.

## Output expectations

- Include the binary path and reported size.
- Highlight any crate or feature that appears disproportionately expensive.
- Prefer concrete, repo-relevant reductions over generic advice.
