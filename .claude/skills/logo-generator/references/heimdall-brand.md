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
- **Dot-matrix H monogram** — the dashboard already uses a dot-matrix motif (Doto font, `.dot-grid` background); a mark built of discrete dots plugs directly into that language.
- **Rate-window bar** — a horizontal segmented progress bar is the signature data-viz of the dashboard; a minimal 5-segment bar is a credible mark.
- **Radar / signal sweep** — circle + single arm at angle, suggesting polling/watching.

## Mark families (concept options)

Rank by how well they read at 16×16 (favicon size) — the hardest constraint.

### 1. Sentinel eye (Tier 1 — recommended default)
Ring + filled pupil. The simplest mark in the set. Optionally adds a 2-unit `#D71921` pip at the pupil center to signal "active watcher."

### 2. Monogram H (Tier 1)
A lowercase or uppercase H. The stroke can be two verticals + a crossbar, or a dot-matrix grid where negative space suggests the H. Dot-matrix variant is heimdall-native (echoes the dashboard's Doto hero type and `.dot-grid` background).

### 3. Watchtower (Tier 2)
Vertical rectangle with a short cap + a single horizontal ground line. Reads as industrial signage; pairs well with the "instrument panel in a dark room" mood in DESIGN.md §1.

### 4. Rate-window bar (Tier 2)
5 segmented squares with 2-unit gaps, one filled solid, the others hollow. Direct echo of `SegmentedProgressBar.tsx`. Works as a favicon if the segment count stays ≤5.

### 5. Radar sweep (Tier 3)
Concentric rings + a single radial arm. Good at 512×512 but the arm gets lost at 16px.

### 6. Gjallarhorn arc (Tier 3)
Three increasing arcs. Elegant at large sizes; fragile at favicon scale.

## Accent pip rules

When the user asks for the "active sentinel" variant, add a single `#D71921` element. Never more than one. Allowed placements:

- center of the sentinel-eye pupil (2-unit radius filled circle)
- terminal node of the radar sweep arm
- one segment of the rate-window bar (the rightmost / overflow segment)

Forbidden:
- red stroke on the outline of any shape
- red pair of elements (breaks the "one signal" rule)
- red in any mark intended for the menu-bar template (the menu-bar export strips all color anyway)

## Typography inside the mark

Heimdall fonts are Space Grotesk (UI), Space Mono (labels/numbers), Doto (hero display). Only use typography in the mark when:

- the user explicitly wants a wordmark (not an icon-only mark), or
- the monogram is dot-matrix (built from circles, not from a font)

If you ship `<text>` in the SVG, the consuming system needs the font. Safer: render the character to outlined `<path>` data before committing. For dot-matrix monograms, you are drawing the dots directly, so there is no font dependency.

## Connection to the dashboard

The dashboard UI already has these visual signatures — the logo should feel like they share a lineage:

- **`SegmentedProgressBar`** — discrete square segments with 2px gaps; filled/empty via opacity ladder
- **`.dot-grid`** — 16px-period radial-gradient dot grid (backgrounds)
- **Doto display type** — dot-matrix variable font, used only for hero numbers
- **`ActivityHeatmap`** — 7×24 CSS grid, monochrome opacity ladder

If the mark uses one of these languages, the rest of the brand snaps into place for free. The dot-matrix H monogram and the rate-window bar both do this. The sentinel-eye does not, but compensates with simpler silhouette.

## Anti-patterns

Do not ship any of these — they contradict DESIGN.md:

- A shield (cliché "security" icon; heimdall is observability, not security)
- An eye with eyelashes or pupils with highlight reflections (photorealistic drift)
- A norse rune or a beard (ethnic cosplay)
- Anything resembling the Claude / Anthropic marks (the product reads Claude logs but is not Anthropic-affiliated)
- A CRT/phosphor aesthetic — `DESIGN.md §7` hard-bans phosphor glow
- A gradient or chromatic accent on the mark
- A mark with more than 6 elements (complexity fails the 16×16 test)
