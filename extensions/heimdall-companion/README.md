# Heimdall Companion

Browser extension that captures your claude.ai and chatgpt.com chat history
and ships it to a local Heimdall instance for archival and analysis.

> Tasks 5-6 add the runtime code (background service worker, content scripts,
> popup and options UI). This task scaffolds the build tooling only.

## Requirements

- Node.js 20+ (build only)
- Heimdall >= the version that ships the `/api/companion/*` endpoints (Phase 3b)

## Sideload — Chrome

1. Run `npm install && npm run build:chrome` from this directory.
2. Open Chrome and navigate to `chrome://extensions`.
3. Enable **Developer mode** (toggle, top-right).
4. Click **Load unpacked** and select the `dist/chrome/` folder.
5. The Heimdall Companion icon appears in the toolbar.

## Sideload — Firefox

1. Run `npm install && npm run build:firefox` from this directory.
2. Open Firefox and navigate to `about:debugging#/runtime/this-firefox`.
3. Click **Load Temporary Add-on**.
4. Select `dist/firefox/manifest.json`.
5. The extension reloads on every browser restart; repeat step 3-4 each session
   (or use a signed build for permanent install).

## Pair with Heimdall

1. Start the Heimdall dashboard: `heimdall dashboard`.
2. Generate a companion token: `heimdall companion-token show`.
   Copy the hex string that is printed.
3. Click the extension icon and open **Options**.
4. Paste the token into the **Companion token** field and set the
   **Heimdall URL** (default `http://localhost:11434`).
5. Click **Save**. The status indicator should turn green.

## Privacy

- The extension reads claude.ai and chatgpt.com pages using the permissions
  declared in `manifest.json`.
- All captured data is sent only to your local Heimdall instance.
- Your session credentials (cookies, tokens) never leave your browser.
- You own your account data. Heimdall stores it in a local SQLite database
  under `~/.local/share/heimdall/` (or the path set by `$HEIMDALL_DATA_DIR`).

## Development

```bash
npm install          # install deps
npm run typecheck    # tsc --noEmit (no .ts sources yet until Tasks 5-6)
npm run build:chrome # esbuild -> dist/chrome/
npm run build:firefox
npm test             # vitest run (no tests yet until Tasks 5-6)
```
