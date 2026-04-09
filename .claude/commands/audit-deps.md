Run a comprehensive dependency audit combining multiple tools.

## Steps

1. **Vulnerability scan** (`cargo audit`):
   - Run `cargo audit` to check for known RUSTSEC advisories
   - If not installed, note: `cargo install cargo-audit`

2. **Policy enforcement** (`cargo deny check`):
   - If `deny.toml` exists, run `cargo deny check`
   - If not installed, note: `cargo install cargo-deny`
   - If `deny.toml` doesn't exist, create one with this policy:
     - Licenses: allow MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, Zlib, Unicode-3.0
     - Advisories: deny all, no exemptions
     - Bans: warn on multiple versions, warn on wildcards
     - Sources: crates-io only

3. **Unused dependencies** (`cargo machete`):
   - Run `cargo machete` to find deps declared but not used
   - If not installed, note: `cargo install cargo-machete`

4. **Summary**: Report total vulnerabilities, license violations, unused deps, and actionable fixes.

## Notes
- Only report issues, don't auto-fix Cargo.toml without confirmation
- For vulnerabilities with patches available, suggest the version bump
- For license violations, explain which dep and which license
