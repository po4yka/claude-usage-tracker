# Heimdall SVG grammar contract

Hard rules for every SVG produced by the logo-generator skill. Derived from 2025–2026 research on LLM SVG failure modes (LLM4SVG, Chat2SVG, SVGenius) and from DESIGN.md's monochrome constraints. **The validator (`scripts/validate_svg.py`) enforces every rule with a parser check; a violation blocks the generated SVG from advancing to the icon-set export.**

Treat this file as authoritative. If something here conflicts with upstream skill documentation, this file wins.

## 1. Document shape

- Root element **MUST** be `<svg>` in the SVG namespace.
- Root **MUST** have `viewBox="0 0 100 100"`. No other viewBox. No `width` / `height` on the root (scale-free).
- Wrap the mark in a single `<g>` with a meaningful `<title>` child. The title is load-bearing for accessibility and for CI diff tooling.

## 2. Element vocabulary

**Allowed:** `svg`, `g`, `title`, `desc`, `defs`, `clipPath`, `path`, `rect`, `circle`, `ellipse`, `line`, `polygon`, `polyline`.

**Forbidden:**
- `<linearGradient>`, `<radialGradient>` — DESIGN.md §2 bans gradients.
- `<filter>`, `<feGaussianBlur>`, `<feDropShadow>`, `<feOffset>`, `<feMerge>`, `<feColorMatrix>` — DESIGN.md bans shadows, blur, phosphor.
- `<text>`, `<tspan>`, `<textPath>`, `<font>`, `<font-face>` — typography must be converted to `<path>` at export; `<text>` depends on a font being installed in the consuming system.
- `<use>` — references introduce ambiguity at export; inline all geometry.
- `<image>`, `<foreignObject>` — mark must be self-contained vector.
- `<mask>`, `<pattern>` — not needed for flat monochrome marks.

## 3. Color discipline

Fill and stroke attributes **MUST** be one of:

- `none`
- `currentColor` *(preferred — inherits from the consuming CSS)*
- `#000` / `#000000` *(pure black)*
- `#fff` / `#FFFFFF` *(pure white)*
- `#E8E8E8` *(--text-primary dark)*
- `#1A1A1A` *(--text-primary light)*
- `#D71921` *(the accent pip — at most **one** element in the whole mark)*

Forbidden:
- Any other hex color (chromatic drift).
- `url(#...)` references to gradients or filters.
- Named CSS colors (`red`, `blue`, `orange`).
- `rgba(...)` or `hsla(...)` — opacity belongs on a dedicated `opacity=` attribute, not baked into the fill.

The validator catches all of these. The `#D71921` appearance is counted; more than one is a hard fail.

## 4. Path discipline (the high-failure zone)

LLMs fail most often on `<path>` elements. These rules target the 2025–2026 documented failure modes:

### 4.1 Path command vocabulary

Use only: `M`, `L`, `H`, `V`, `C`, `S`, `Q`, `T`, `A`, `Z` (and lowercase relative variants). Keep path `d` strings under 10 commands per path for reviewability.

### 4.2 Closed fills

Every `<path>` with `fill` set to anything other than `none` **MUST** end its `d` string with `Z` or `z`. Browsers auto-close but the geometry is ambiguous without explicit closure, and different renderers disagree on where the closing edge sits.

### 4.3 Arc commands — the #1 failure mode

LLMs confuse `large-arc-flag` and `sweep-flag` in `A rx ry x-rotation large-arc-flag sweep-flag x y` constantly. Every `A` command must:

- Have `large-arc-flag` and `sweep-flag` as literal `0` or `1` (never decimals, never strings).
- Be self-critiqued before submission: *"Does this arc subtend more than 180°? If yes, `large-arc-flag=1`; if no, `large-arc-flag=0`. Is the sweep clockwise (as viewed) or counter-clockwise? Clockwise → `sweep-flag=1`, counter-clockwise → `sweep-flag=0`."*

The validator catches decimal-flag drift and counts arcs (flagging them for human visual verification). It cannot catch semantically-wrong flags — that's on the generation step.

### 4.4 Coordinate range

All coordinates in the `d` attribute must fall within `[-10, 110]` on the `viewBox="0 0 100 100"` canvas. Anything outside that range is almost certainly **coordinate tokenization drift** — LLMs treat numbers as character sequences and occasionally produce `50` as `500` or `5.0`. The validator warns on any out-of-range value.

### 4.5 Empty `d`

A `<path>` with empty `d=""` is a hard fail — usually a model truncation artifact.

## 5. Transforms

Transforms (`transform="rotate(...)"`, `transform="translate(...)"`) belong on `<g>` groups only. Transforms on individual `<path>`, `<rect>`, etc. break cumulative-transform reasoning and are forbidden. The validator emits a warning; promote to error in `--strict` mode.

## 6. Stroke width (16×16 gate)

If the mark ships at 16×16 (favicon, menu-bar template), every `stroke-width` **MUST** be ≥ 8 units in the 0–100 viewBox. 8 units → 1.28px at 16×16 raster — just above the anti-aliasing floor. Below that, strokes disappear into haze at favicon scale. The validator does not enforce this (size intent is not declared in the file) — the skill workflow enforces it via the 16×16 render gate.

## 7. Accent pip (semantic)

The single `#D71921` element must be a small signal element — typically a filled `<circle>` with `r` between 2 and 5 units, placed at a semantic anchor (bell mouth of a horn, terminus of an arc, etc.). Never as a stroke color, never as a fill on the primary silhouette. The validator counts occurrences; semantics are on the reviewer.

## 8. Metadata / decoration

Do not ship `<desc>`, `<metadata>` (the RDF kind), or XML processing instructions beyond the default declaration. Keep files small; every extra kilobyte is wasted on a 100-unit-canvas mark.

## 9. What the validator does not check

These rules are real but not mechanically enforceable; enforce them in review:

- Visual legibility at 16×16 (render-and-inspect).
- Semantic correctness of arc flags (render-and-inspect).
- Negative-space ratio ≥ 40% (render-and-measure).
- Cultural / trademark collision (human judgment — see `heimdall-logo-brief.md` collision list).
- Whether the mark actually looks like the concept it claims to represent (human judgment).

## 10. How to invoke

```bash
# Single file, warnings allowed
python .claude/skills/logo-generator/scripts/validate_svg.py assets/icons/master.svg

# Strict mode — promote warnings to errors (use in CI)
python .claude/skills/logo-generator/scripts/validate_svg.py --strict \
  assets/icons/master.svg assets/icons/variants/*.svg
```

The skill workflow runs this automatically after Phase 2 generation; any variant that fails the contract is rejected before the user sees it.
