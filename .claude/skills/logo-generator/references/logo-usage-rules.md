# Logo usage rules — heimdall

Guidelines for shipping the heimdall mark consistently. Derived from `blog/.claude/skills/brand-system/references/logo-usage-rules.md` and trimmed to the subset that applies to a CLI + menu-bar app + dashboard.

## Clear space

Minimum clear space around the mark equals the height of the mark itself. For the `viewBox="0 0 100 100"` canvas, that is 100 units on each side — do not crowd the mark with text or container edges.

```
┌───────────────────────────────┐
│             [x]               │
│      ┌─────────────────┐      │
│      │                 │      │
│ [x]  │     MARK        │ [x]  │
│      │                 │      │
│      └─────────────────┘      │
│             [x]               │
└───────────────────────────────┘
```

## Minimum sizes

| Surface | Min size | Notes |
|---|---|---|
| Favicon | 16 × 16 | Primary readability constraint. If the mark fragments at 16, redesign. |
| Menu-bar template | 16 × 16 @1x | macOS draws at ~18pt. Keep silhouette simple. |
| Dashboard header | 24 × 24 | Pair with `.label-meta` wordmark "HEIMDALL" in Space Mono. |
| App icon in dock | 128 × 128 | Smallest dock size on macOS Ventura+. |
| Print / docs | 35 mm | Letterhead / business card baseline. |

## Color usage

Heimdall is strict monochrome:

| Background | Mark treatment |
|---|---|
| OLED black (`#000000`) | `--text-primary` dark (`#E8E8E8`) or `--text-display` (`#FFFFFF`) |
| Warm off-white (`#F5F5F5`) | `--text-primary` light (`#1A1A1A`) or `--text-display` (`#000000`) |
| Card surface dark (`#111111`) | Same as OLED black — the mark reads identically |
| Card surface light (`#FFFFFF`) | Same as warm off-white |
| Photography | Forbidden. Do not overlay the mark on photos. |

Rules:
1. Never change mark color outside the monochrome set.
2. Never add gradients, inner shadows, outer shadows, or strokes.
3. Never apply transparency < 100% to the mark as decoration. (Dashboard spacer animations may dim adjacent chrome elements, but not the mark itself.)
4. The optional `#D71921` active-sentinel pip is the *only* non-neutral element permitted, and only when semantically justified.

## Forbidden

- Stretch / compress
- Rotate at any angle
- Drop shadows, glow, phosphor effects
- Gradient fills
- Chromatic fills (purple, teal, amber, blue, green)
- Strokes / outlines on an otherwise-filled mark
- Placement on busy photographic backgrounds
- Cropping any portion
- Rearranging elements
- Adding additional elements (sparkles, arrows, motion lines)

## File organization

Under `assets/icons/` at the repo root (not inside `.claude/skills/`):

```
assets/icons/
├── master.svg                          # canonical source — commit this
├── macos/
│   ├── AppIcon.appiconset/             # Xcode-compatible bundle
│   ├── heimdall.icns                   # compiled bundle icon
│   └── menu-bar/                       # template images for NSImage.isTemplate
├── linux/hicolor/                      # freedesktop theme tree
├── windows/heimdall.ico                # multi-size container
└── web/
    ├── favicon.ico
    └── favicon.svg
```

## Naming conventions

- Master SVG: `master.svg` (not `logo.svg`, not `heimdall.svg` — the directory already names it).
- macOS bundle: `heimdall.icns` / `AppIcon.appiconset/`.
- Windows: `heimdall.ico`.
- Linux: `heimdall.png` under each hicolor size.
- Web: `favicon.ico` / `favicon.svg`.
- Menu-bar template: `icon_template.png` / `icon_template@2x.png` (the `Template` naming suffix is a macOS discoverability convention; the code sets `isTemplate = true` explicitly).

Do not introduce per-brand suffixes like `heimdall-light.png` / `heimdall-dark.png` — the mark is a single silhouette; light/dark adaptation is the consumer's job via `currentColor` (SVG) or the template-image system (menu-bar).

## Approval checklist

Before committing any icon update:

- [ ] Master SVG uses `viewBox="0 0 100 100"` and `currentColor`.
- [ ] Grep the SVG for `<linearGradient>`, `<radialGradient>`, `filter=`, `text-shadow`. All should return nothing.
- [ ] No fill values other than `none`, `currentColor`, `#000`, `#FFF`, `#E8E8E8`, `#1A1A1A`, `#D71921`.
- [ ] The 16×16 export is legible — open `web/favicon.ico` in a finder/preview that renders at actual size.
- [ ] `AppIcon.appiconset/` has exactly 10 PNGs and a `Contents.json`.
- [ ] `iconutil -c icns AppIcon.appiconset` succeeds on a Mac.
- [ ] `file heimdall.ico` reports a multi-image ICO.
- [ ] The menu-bar template has no color — verify by opening the PNG and confirming all non-transparent pixels are black.
