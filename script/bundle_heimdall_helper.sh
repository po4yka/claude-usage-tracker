#!/usr/bin/env bash
set -euo pipefail

# Xcode's PhaseScriptExecution sandbox starts with a minimal PATH that
# does not include ~/.cargo/bin or /opt/homebrew/bin, so cargo would not
# be found. Source the standard cargo env file if it exists, then fall
# back to common install locations.
if [[ -f "$HOME/.cargo/env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <app-bundle> [Debug|Release]" >&2
  exit 2
fi

APP_BUNDLE="$1"
CONFIGURATION="${2:-Debug}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPERS_DIR="$APP_BUNDLE/Contents/Helpers"

case "$CONFIGURATION" in
  Release)
    CARGO_ARGS=(build --release --bin heimdall)
    HELPER_SOURCE="$ROOT_DIR/target/release/heimdall"
    ;;
  *)
    CARGO_ARGS=(build --bin heimdall)
    HELPER_SOURCE="$ROOT_DIR/target/debug/heimdall"
    ;;
esac

cargo "${CARGO_ARGS[@]}" --manifest-path "$ROOT_DIR/Cargo.toml" >/dev/null

mkdir -p "$HELPERS_DIR"
# Bundled helper is named `heimdall` so macOS notifications attribute the
# background daemon to "heimdall" rather than the cargo crate name.
install -m 755 "$HELPER_SOURCE" "$HELPERS_DIR/heimdall"
