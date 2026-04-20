# Platform icon requirements

Authoritative size/format matrix for every heimdall surface that consumes an icon. `scripts/render_icon_set.py` implements this matrix — if you change the numbers here, update the script at the same time.

## macOS — AppIcon.appiconset (HeimdallBar)

Apple requires a specific set of sizes in an `.appiconset` bundle. Xcode validates on drag-in and flags anything missing.

| Filename | Pixels | `Contents.json` entry |
|---|---|---|
| `icon_16x16.png` | 16 × 16 | size `16x16`, scale `1x`, idiom `mac` |
| `icon_16x16@2x.png` | 32 × 32 | size `16x16`, scale `2x`, idiom `mac` |
| `icon_32x32.png` | 32 × 32 | size `32x32`, scale `1x`, idiom `mac` |
| `icon_32x32@2x.png` | 64 × 64 | size `32x32`, scale `2x`, idiom `mac` |
| `icon_128x128.png` | 128 × 128 | size `128x128`, scale `1x`, idiom `mac` |
| `icon_128x128@2x.png` | 256 × 256 | size `128x128`, scale `2x`, idiom `mac` |
| `icon_256x256.png` | 256 × 256 | size `256x256`, scale `1x`, idiom `mac` |
| `icon_256x256@2x.png` | 512 × 512 | size `256x256`, scale `2x`, idiom `mac` |
| `icon_512x512.png` | 512 × 512 | size `512x512`, scale `1x`, idiom `mac` |
| `icon_512x512@2x.png` | 1024 × 1024 | size `512x512`, scale `2x`, idiom `mac` |

Ten PNGs + `Contents.json`. Color space: sRGB. Transparency: required (PNG with alpha). The master SVG is rendered at the target pixel size directly; no upscaling.

### Compiling `.icns`

After the `.appiconset` is populated:

```bash
iconutil -c icns assets/icons/macos/AppIcon.appiconset -o assets/icons/macos/heimdall.icns
```

`iconutil` is a macOS-only built-in (`/usr/bin/iconutil`). On Linux/Windows the script emits the `.appiconset` directory but skips the compilation step. Run `iconutil` later on a Mac or in a macOS CI job.

## macOS — menu-bar template icon (HeimdallBar status item)

Menu-bar icons use the **template image** convention: grayscale PNG on transparent background, where black pixels become the current foreground color (macOS inverts them when the menu extra is selected or when dark mode is active). The logo's optional `#D71921` pip MUST be stripped for this export.

| Filename | Pixels |
|---|---|
| `icon_template.png` | 16 × 16 |
| `icon_template@2x.png` | 32 × 32 |

Convention: the file must be named with the `Template` suffix *or* the Swift code must set `NSImage.isTemplate = true`. HeimdallBar currently uses the latter, so the filename suffix is for our own discoverability.

Rules:
- Single color (black ink on transparent), no gradients, no anti-aliased color.
- Keep the silhouette simple — the OS draws it at ~18pt in the menu bar.
- No accent pip. The `--template` flag on `render_icon_set.py` enforces this.

## Linux — freedesktop hicolor theme

The freedesktop icon theme spec uses a directory-per-size layout. Sizes to ship:

| Directory | Pixels |
|---|---|
| `hicolor/16x16/apps/heimdall.png` | 16 × 16 |
| `hicolor/32x32/apps/heimdall.png` | 32 × 32 |
| `hicolor/48x48/apps/heimdall.png` | 48 × 48 |
| `hicolor/64x64/apps/heimdall.png` | 64 × 64 |
| `hicolor/128x128/apps/heimdall.png` | 128 × 128 |
| `hicolor/256x256/apps/heimdall.png` | 256 × 256 |
| `hicolor/512x512/apps/heimdall.png` | 512 × 512 |

Distro packages install to `$prefix/share/icons/hicolor/`. A `.desktop` file with `Icon=heimdall` finds the right size automatically.

Optional but cheap: ship `hicolor/scalable/apps/heimdall.svg` (the master SVG) for themes that prefer vectors.

## Windows — multi-size .ico

A Windows `.ico` is a container holding multiple bitmap sizes. Ship:

| Size |
|---|
| 16 × 16 |
| 32 × 32 |
| 48 × 48 |
| 64 × 64 |
| 128 × 128 |
| 256 × 256 |

Pillow writes a multi-size `.ico` in one call:

```python
sizes = [(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)]
base_png.save("heimdall.ico", format="ICO", sizes=sizes)
```

Windows 10+ prefers 256×256 for high-DPI file-type glyphs; keep it included.

## Web — favicon

Dashboard favicon needs both ICO (legacy browsers + IE) and SVG (modern browsers):

| Filename | Format | Sizes |
|---|---|---|
| `favicon.ico` | ICO | 16 × 16 + 32 × 32 |
| `favicon.svg` | SVG | master (scale-free) |

Dashboard HTML wiring (for `src/ui/index.html`):

```html
<link rel="icon" type="image/svg+xml" href="/favicon.svg">
<link rel="alternate icon" type="image/x-icon" href="/favicon.ico">
```

SVG favicon must use `currentColor` or fixed black — browsers do not respect CSS variables on favicons.

## Cross-cutting rules

1. **Render direct at target size.** Do not rasterize at 1024 and downscale to 16 — cairosvg produces crisper edges when rendering straight to the target resolution. The script enforces this.
2. **sRGB only.** All PNGs. Do not ship P3 or Display-P3 from the generator; color-management variance across platforms is not worth it for a monochrome mark.
3. **No EXIF, no metadata.** Strip during export to reduce asset size.
4. **No DPI flag.** PNGs are pixel-based; leave the physical DPI unset.
5. **Test at 16×16 before anything else.** If it does not read at favicon size, it does not ship.

## Asset tree reference

```
assets/icons/
├── master.svg
├── macos/
│   ├── AppIcon.appiconset/
│   │   ├── Contents.json
│   │   ├── icon_16x16.png .. icon_512x512@2x.png  (10 files)
│   ├── heimdall.icns
│   └── menu-bar/
│       ├── icon_template.png
│       └── icon_template@2x.png
├── linux/
│   └── hicolor/
│       ├── 16x16/apps/heimdall.png
│       ├── 32x32/apps/heimdall.png
│       ├── 48x48/apps/heimdall.png
│       ├── 64x64/apps/heimdall.png
│       ├── 128x128/apps/heimdall.png
│       ├── 256x256/apps/heimdall.png
│       └── 512x512/apps/heimdall.png
├── windows/
│   └── heimdall.ico
└── web/
    ├── favicon.ico
    └── favicon.svg
```
