# Heimdall-specific brand motifs

This file supplements `design_patterns.md` (generic SVG pattern library) with motifs specific to heimdall. The *tokens* live in `DESIGN.md` and `.claude/skills/industrial-design/references/tokens.md` — do not fork them here. This file describes *ideas*, not colors.

## Name etymology — design signal

Heimdall is the Norse watchman who guards Bifröst and sees every rider, hears every blade of grass. The product watches AI sessions, renders a dashboard, and fires hooks on events. The brand mark should read as *perceptive attention*: something that watches without blinking.

Useful compressions of "Heimdall":
- **Sentinel eye** — ring + filled pupil + optional red signal pip
- **Gjallarhorn** — the horn he sounds when Ragnarök arrives — arc + mouth
- **Watchtower** — vertical bar with a cap, orthogonal to a horizon line
- **Bifröst** — multi-arc rainbow, but heimdall is monochrome, so reduce to 3 concentric arcs at decreasing stroke weights

The product reality ("local analytics CLI for AI sessions") layers these other directions:
- **Dot-matrix H monogram** — *retired*. The dashboard used to lean on Doto and `.dot-grid`; both have been removed during the Apple-Swiss refresh, so this direction no longer has an anchor in the product.
- **Rate-window bar** — a horizontal segmented progress bar is the signature data-viz of the dashboard; a minimal 5-segment bar is a credible mark.
- **Radar / signal sweep** — circle + single arm at angle, suggesting polling/watching.

## Mark families (concept options)

Rank by how well they read at 16×16 (favicon size) — the hardest constraint.

### 1. Sentinel eye (Tier 1 — recommended default)
Ring + filled pupil. The simplest mark in the set. Optionally adds a 2-unit `#D71921` pip at the pupil center to signal "active watcher."

### 2. Monogram H (Tier 2 — grotesque only)
A single-stroke uppercase H drawn in the Inter / Geist grotesque character: two verticals + a crossbar, sharp terminals, equal stroke weight. The stroke-constructed H is viable. The **dot-matrix H variant is explicitly discouraged** — the dashboard no longer uses Doto or dot-grid motifs, so a dot-matrix mark would reference nothing in the product. See "Anti-patterns" below.

### 3. Watchtower (Tier 2)
Vertical rectangle with a short cap + a single horizontal ground line. Reads as precise signage; pairs well with the "calm precision / refined tool" register defined in DESIGN.md §1.

### 4. Rate-window bar (Tier 2)
5 segmented squares with 2-unit gaps, one filled solid, the others hollow. Direct echo of `SegmentedProgressBar.tsx`. Works as a favicon if the segment count stays ≤5.

### 5. Radar sweep (Tier 3)
Concentric rings + a single radial arm. Good at 512×512 but the arm gets lost at 16px.

### 6. Gjallarhorn arc (Tier 3)
Three increasing arcs. Elegant at large sizes; fragile at favicon scale.

## Accent pip rules

Pick zero or one chromatic pip. If one, it's either red or blue-gray — never both.

**Red `#D71921` — "alert sounded" semantic.** Use when the mark encodes a fault / alarm / destructive moment. Allowed placements:
- bell mouth of the Gjallarhorn (alert fired)
- terminal node of an emission ray
- overflow segment of the rate-window bar

**Blue-gray `#4A7FA5` — "interactive / ready" semantic.** Use when the mark encodes readiness, signal-lock, or primary-interactive identity. Allowed placements:
- center of the sentinel-eye pupil (active watcher)
- origin emitter of the Signal Arc
- central dot of the Horizon Watcher

Either color: at most one per mark, always a small filled `<circle>` with `r` between 2 and 5 units.

Forbidden:
- using both red and blue-gray in the same mark (breaks the "one signal" rule — pick one hue)
- chromatic stroke on the outline of any shape (accents are fills only)
- accent pip on any mark intended for the menu-bar template (the menu-bar export strips all color via `strip_accent()`)

## Typography inside the mark

Heimdall fonts (web) are Inter (UI/headings/body) and Geist Mono (numbers/code/`<th>`). Only use typography in the mark when:

- the user explicitly wants a wordmark (not an icon-only mark), and
- the character is rendered as outlined `<path>` data in the Inter grotesque character

Never ship `<text>` elements — the consuming system needs the font installed. A stroke-constructed monogram (H drawn as two verticals + crossbar with sharp terminals and equal weight) is viable and doesn't require font outlines. Dot-matrix monograms are **not** viable (see anti-patterns below).

## Connection to the dashboard

The dashboard UI uses these visual signatures — the logo may echo them for coherence, but does not have to:

- **Smooth pill progress bars** — single-fill with 2px rounded ends, color-encoded by threshold (replaces the old segmented LED-meter geometry)
- **Concentric corner radii** — nested shapes share a center point; a mark that respects this feels native
- **Inter grotesque character** — sharp terminals, equal stroke weight, humanist but restrained — the mark's silhouette can echo these proportions
- **`ActivityHeatmap`** — monochrome opacity ladder (no color ramp) — a mark using opacity-only differentiation harmonizes

The Horn, Horizon Watcher, and Signal Arc directions all pair well with the current Apple-Swiss dashboard character. The old dot-matrix H and segmented rate-window bar directions are retired — they referenced dashboard signatures that no longer exist.

## Anti-patterns

Do not ship any of these — they contradict DESIGN.md or reference the retired Nothing/industrial aesthetic:

- **Dot-matrix / LED-grid typography of any kind** (the dashboard no longer uses Doto; a dot-matrix mark has no anchor in the product)
- **Segmented LED-meter progress-bar motifs** (the dashboard uses smooth pill bars now)
- **Dot-grid backgrounds** in showcase / presentation renders (retired)
- A shield (cliché "security" icon; heimdall is observability, not security)
- An eye with eyelashes or pupils with highlight reflections (photorealistic drift)
- A norse rune or a beard (ethnic cosplay)
- Anything resembling the Claude / Anthropic marks (the product reads Claude logs but is not Anthropic-affiliated)
- A CRT/phosphor aesthetic — DESIGN.md hard-bans phosphor glow
- A gradient on the mark
- More than one chromatic accent element (or any accent at all on menu-bar templates)
- A mark with more than 6 elements (complexity fails the 16×16 test)
