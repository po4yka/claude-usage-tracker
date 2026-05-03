# Heimdall — native macOS menu-bar app

`Heimdall` is the native macOS companion app for Claude Code and Codex. It is different from the existing `statusline` and `menubar` surfaces:

- `statusline` is a single Claude Code hook-rendered line inside Claude Code itself.
- `menubar` is SwiftBar-formatted text for third-party menu-bar widgets.
- `Heimdall` is a standalone `LSUIElement` macOS app with native menu-bar UI, widgets, browser-session import, optional web extras, and the bundled `heimdall` parity CLI.

## Install

Install the prebuilt macOS app artifact from the [GitHub Releases](https://github.com/po4yka/heimdall/releases) page:

```bash
VERSION=$(curl -fsSL https://api.github.com/repos/po4yka/heimdall/releases/latest | jq -r '.tag_name')
curl -fL -o "/tmp/heimdall-${VERSION}.zip" \
  "https://github.com/po4yka/heimdall/releases/download/${VERSION}/heimdall-${VERSION}-macos-app.zip"
unzip -q "/tmp/heimdall-${VERSION}.zip" -d /tmp
open "/tmp/heimdall-${VERSION}-macos-app/Heimdall.app"
```

Recommended post-install layout:

```bash
mv "/tmp/heimdall-${VERSION}-macos-app/Heimdall.app" /Applications/
open /Applications/Heimdall.app
```

## What launches automatically

When `Heimdall.app` starts, it manages its own local helper:

- launches the bundled `heimdall` from `Contents/Helpers`
- keeps the helper bound to loopback only
- reuses a healthy existing loopback helper when possible
- restarts the owned helper when it becomes stale
- shuts the owned helper down on app exit

You do not need a separate `PATH` installation of `heimdall` for the app itself.

## App architecture

`Heimdall` is split into layered native modules:

- `HeimdallDomain` — pure shared models, source resolution, widget snapshot policy.
- `HeimdallServices` — refresh orchestration, repositories, auth coordination, snapshot writing.
- `HeimdallPlatformMac` — macOS-only adapters (helper process management, browser import, Keychain, WebKit scraping).
- `HeimdallAppUI`, `HeimdallWidgets`, `HeimdallCLI` — app, widget, and bundled-CLI surfaces on top of those layers.

This split is intentional preparation for a future iOS companion. The Rust helper remains a macOS-only local producer; a future iOS client is expected to consume synced/provider-backed data rather than launch the helper locally.

## Bundled CLI

The macOS app artifact also contains a bundled `heimdall` CLI plus its shared framework. Keep the artifact directory structure intact if you want to call the CLI directly:

```bash
export DYLD_FRAMEWORK_PATH="/tmp/heimdall-${VERSION}-macos-app/Frameworks"
"/tmp/heimdall-${VERSION}-macos-app/bin/heimdall" config dump
"/tmp/heimdall-${VERSION}-macos-app/bin/heimdall" usage --provider both --format json --pretty
```

## Widgets

`Heimdall` ships four widget families for Claude Code and Codex:

- Switcher
- Usage
- History
- Compact

After launching the app once, add them from the standard macOS widget gallery. Widget data is shared through the app group and refreshes after app-driven data updates.

## Enabling web extras

Web extras are optional and off by default. They are only needed when you want Codex dashboard-only fields that are not already available from local or OAuth-backed data.

To enable them:

1. Open `Heimdall` settings.
2. Turn on dashboard extras for the provider you want.
3. Import a browser session from Safari, Chrome, Arc, or Brave.
4. Refresh the provider from the menu-bar app.

If no imported session is available, the app remains fully usable and reports `login required` instead of failing.

## Privacy model

Browser session import and web extras follow a narrow local-only model:

- imported browser session material is stored in Keychain-backed secure storage, not plaintext repo files
- the app stores session metadata (provider, browser source, import time, cookie-domain presence) for state display
- hidden WebKit scraping is opt-in and only used for provider-specific dashboard extras
- helper traffic stays on loopback
- Heimdall does not require a remote Heimdall service

Practical implication: if you never enable web extras or import a browser session, Heimdall still works from Rust-backed local and OAuth-derived data only.

## Troubleshooting

**Helper not reachable**

- relaunch `Heimdall.app`; the app should restart its bundled helper automatically
- check whether another process is already bound to `127.0.0.1:8787`
- if you use a development build, make sure the helper was bundled or available in `PATH`

**Widget not appearing**

- launch `Heimdall.app` at least once before opening the widget gallery
- make sure both app and widget were embedded in the release artifact
- if you replaced the app bundle manually, remove the old copy and relaunch the new one so macOS registers the widget extension again

**Expired browser session**

- open settings in `Heimdall`
- inspect the provider session state
- re-import the browser session from the desired browser profile
- refresh the provider again after import

**Missing Codex auth.json**

- sign in with the Codex/OpenAI CLI first so `~/.codex/auth.json` or `$CODEX_HOME/auth.json` exists
- if you only want local app features, keep the provider enabled and use sources that do not require Codex OAuth
- the menu and CLI will show source fallback or unavailable-source warnings instead of silently pretending Codex OAuth is available

## Release artifact contents

The signed macOS app artifact contains:

- `Heimdall.app`
- `bin/heimdall`
- `Frameworks/HeimdallDomain.framework`
- `Frameworks/HeimdallServices.framework`
- `Frameworks/HeimdallPlatformMac.framework`
- `Frameworks/HeimdallAppUI.framework`
- `Frameworks/HeimdallWidgets.framework`
- `Frameworks/HeimdallCLI.framework`

Inside `Heimdall.app` itself you should also see:

- `Contents/Helpers/claude-usage-tracker`
- `Contents/PlugIns/HeimdallWidget.appex`

For release validation details, see [.github/RELEASING.md](../.github/RELEASING.md).
