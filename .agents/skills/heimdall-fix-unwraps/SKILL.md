---
name: heimdall-fix-unwraps
description: Use when removing `.unwrap()` calls from Heimdall production Rust code. Covers non-test library code in scanner, server, oauth, pricing, config, webhooks, and models, with replacement strategies and verification expectations.
---

# Heimdall Fix Unwraps

Use this skill when the task is to remove panic-prone `.unwrap()` calls from production Rust code.

## Scope

- Search `src/` for `.unwrap()`.
- Exclude tests, `main.rs`, and other entry-point-only unwraps unless the user asks otherwise.
- Focus on library code in `scanner/`, `server/`, `oauth/`, `pricing.rs`, `config.rs`, `webhooks.rs`, and `models.rs`.

## Replacement rules

1. In a function returning `Result`, prefer `?`.
2. In a non-`Result` function, decide whether to:
   - change the signature and propagate the error
   - use an explicit fallback such as `unwrap_or_default` or `unwrap_or_else`
   - keep an actually infallible path only with a concise justification comment
3. Leave `.expect(...)` only when the message clearly explains the invariant.

## Workflow

1. Enumerate the remaining production `.unwrap()` sites in scope.
2. Replace each one with the narrowest safe alternative.
3. Avoid drive-by refactors outside the touched failure path.
4. Run the relevant Rust tests after the edits.

## Output expectations

- Report how many `.unwrap()` sites were found in scope.
- State which ones were fixed.
- If any were intentionally left, justify each one.
