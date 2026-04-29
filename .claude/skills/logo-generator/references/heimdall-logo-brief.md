# Heimdall logo brief + execution plan

Creative brief and generation plan for heimdall's mark, synthesized from web research (2026-04). Read this file during Phase 1 of the `logo-generator` skill instead of re-asking the user — the concept direction, collision avoidance list, and 16×16 discipline are already settled here.

---

## Concept anchor

Heimdall is the Norse watchman at Bifröst. He needs less sleep than a bird; he hears wool grow on sheep; he will sound Gjallarhorn at Ragnarök. The product mirrors this: local observer of every AI coding session, fires webhooks when a rate window crosses threshold. **The mark should read as a silent horn waiting to sound**, not as a guard or shield.

Primary texts used (for brand narrative, not the mark itself):
- *Gylfaginning* ch. 27 — "He hears grass growing on the earth and wool on sheep"
- *Völuspá* st. 46 — "Heimdall blows — the horn is aloft"

---

## Must-avoid list (collision risks)

Direct collisions confirmed by research — do not ship any of these silhouettes:

1. **Red shield with "H" letterform** — linuxserver.io's *Heimdall Application Dashboard* owns this space completely. Direct domain overlap (self-hosted dashboards). Hard avoid.
2. **Orange flame / torch** — Grafana and Prometheus adjacency. Monitoring-tool cliché.
3. **Generic guard tower** — overused in security SaaS; reads as enterprise-stock.
4. **Full seven-color rainbow arc** — Bifröst temptation, but parses as pride flag before Norse bridge.
5. **Blue circle + eye** — Elastic, Splunk, Copilot adjacency. The "observability eye" trope is exhausted.
6. **Hexagon** — owned by Honeycomb.
7. **Spark / starburst** — severe OpenAI adjacency in 2026.
8. **Shield outline of any kind** — ecosystem noise.
9. **Ndot / Doto-style dot-matrix typography (any size)** — Nothing's signature. Our brand has moved away from that register; a dot-matrix mark reads as a Nothing Phone derivative.
10. **LED-strip / segmented-bar decorative motifs** — Nothing Glyph direct citation and Teenage Engineering OP-1 visual language. Both are aesthetics the product is deliberately leaving behind.
11. **Labeled-hardware simulacra** — virtual knob with rubberized highlight, simulated LCD segment display, silk-screened PCB label cosmetics. Teenage Engineering / Braun-panel cosplay.
12. **Orange-red Glyph tint (#E8410B–#FF6600) as a "live/active" indicator** — direct Nothing Glyph LED lit-state reference.

Also avoid the MCU-derived Heimdall imagery (helmet, eyes, sword) — not canonical to Norse tradition and would read as fan-art.

---

## Concept directions (ranked)

Three directions are viable. The skill should generate variants across all three in Phase 2, then narrow based on the 16×16 gate test.

### Direction A — **The Horn (Gjallarhorn)** — primary

A single crescent or flared-tube silhouette. Curves right, bell open at the wide end. Optional `#D71921` pip at the bell mouth signaling "the horn has sounded" — maps directly to heimdall's webhook-on-threshold feature. Hardest to confuse with any competitor; softest learning curve for brand narrative.

**Why it wins:**
- Mythologically specific. No current dev-tool owns the horn silhouette.
- Single continuous form — survives 16×16 trivially, same way Vercel's chevron does.
- Red pip is semantic, not decorative. The mark literally illustrates the product's alerting model.
- Rotates to ~45° for dynamic compositions without losing identity.

**Risks:**
- "Horn of plenty" (cornucopia) reading if bell is too wide and contents suggested.
- Party-horn / instrument-catalog reading if curvature is too ornate.

### Direction B — **The Horizon Watcher** — secondary

A flat horizontal rule (horizon) with a short vertical notch standing at one end (watchtower / Himinbjörg peak) and a small filled dot at the notch's tip (the watcher). Echoes the Apple-Swiss sense of "structure through space" and the Himinbjörg ("sky cliffs") attribute. Allowed accent: `#4A7FA5` blue-gray pip at the watcher dot (interactive-ready signal).

**Why it survives 16×16:** three geometric primitives (line, rectangle, dot), generous spacing, strong left-right asymmetry. Feels native to the Apple-Swiss dashboard character.

**Risks:** low distinctiveness — reads as generic dashboard UI at small scale.

### Direction C — **The Signal Arc** — tertiary / radar-sweep variant

A quarter-circle arc + small filled dot at the arc's origin. Reads as (a) reduced Bifröst bridge, (b) radar sweep arm. Allowed accent: `#4A7FA5` blue-gray pip at the origin dot (emitter-ready signal).

**Why it's tertiary:** competes with the radar/signal-sweep cliché (Section 1 of the observability research). Works as a supporting mark (email sigil, social avatar) more than a primary mark.

**Fail-case variant — Dot-matrix H monogram.** Generated **only to demonstrate why dot-matrix is wrong for this brand**. With the dashboard's retirement of Doto and dot-grid backgrounds, a dot-matrix mark now references the retired Nothing/industrial register and has no anchor in the product. Ship it in the gallery as v06 labeled "fail-case — do not ship" so reviewers see the failure visually. Never advance this variant to Phase 3.

---

## 16×16 gate (non-negotiable)

Every variant must be exported at 16×16 before the user sees it. Rules from the research:

- Strokes ≥ 1.5px at 1× (≈ 9 units in `viewBox="0 0 100 100"`). Below that, anti-aliasing swallows them.
- Interior gaps ≥ 2px at 1×. Concentric rings, adjacent strokes — enforce clearance.
- No text, no fine diagonals, no two enclosed fills closer than 2px.
- Apply a 50% opacity overlay at 16×16; the silhouette must still read (simulates macOS inactive-template tint).

Variants that fail the 16×16 gate do not advance to Phase 3. The showcase template (`assets/showcase_template.html`) already renders each variant at both 128px and 16px side-by-side for reviewer sanity.

---

## Variant generation plan (Phase 2)

Generate exactly 6 variants, allocated across the three directions:

| # | Direction | Concept | Fill | Accent pip |
|---|---|---|---|---|
| 01 | Horn | Clean crescent, 3-unit stroke, bell opens right | outlined | at bell mouth |
| 02 | Horn | Flared tube, solid fill, asymmetric mouth | filled | at bell |
| 03 | Horn | Horn + 3 short emission rays from bell | outlined | on one ray |
| 04 | Horizon | Hairline horizon + notch + dot (watcher) | mixed | omit |
| 05 | Arc | Quarter-circle + origin dot (signal sweep) | outlined stroke | at arc terminal |
| 06 | Fail-case | Dot-matrix H monogram (4×5 grid) — **demo only, do not ship** | dots only | omit |

Each variant ships with:
- 128×128 preview
- 16×16 preview (side-by-side in the HTML gallery)
- One-sentence rationale (e.g. "01: Horn — cleanest Gjallarhorn silhouette, single stroke survives at 16px, accent pip = sounded alert")
- Pattern-family label (Horn / Horizon / Arc / Monogram)

## Menu-bar discipline (two-variant system)

Research finding from Apple HIG + indie-app review: marks that serve both 1024×1024 dock and 16×16 menu-bar template succeed by sharing a skeleton, not by scaling the dock mark down. Heimdall's answer:

- **Master SVG** (dock + favicon + appiconset) — full mark with optional `#D71921` pip.
- **Template SVG** (menu-bar) — same skeleton with the pip stripped. Handled automatically by `render_icon_set.py strip_accent()` — no manual second master required.

Silhouette rule: the black-ink skeleton must read without the accent. If the mark needs the red to be identifiable, redesign.

## Dashboard-lineage considerations

The Preact dashboard now uses the Apple-Swiss refined register (Inter + Geist Mono, sentence-case, smooth progress bars, concentric radii, blue-gray `#4A7FA5` primary interactive). The mark can echo these properties for system coherence:

- Smooth pill progress bars (`ProgressBar` / `SegmentedProgressBar` smooth-fill variant) — continuous rounded geometry; the mark's silhouette can favour smooth curves / single forms
- Concentric corner radii — nested shapes share a conceptual center; the mark's nested elements (dot inside ring, pip inside bell) should respect this
- Inter grotesque character — sharp terminals, equal stroke weight, humanist but restrained
- `ActivityHeatmap` — monochrome opacity ladder (no color ramp)

The retired dashboard signatures (segmented LED-meter bars, `.dot-grid` backgrounds, Doto dot-matrix type) should **not** be echoed — they no longer exist in the product. Direction A (Horn) is mythology-first and intentionally doesn't reference the dashboard. Directions B (Horizon) and C (Arc) are naturally Apple-Swiss-compatible via their geometric simplicity.

## Execution checklist

Run the skill with this brief loaded. In order:

1. **Phase 1** — this file is the interview answer. Confirm with user: "Generating 6 variants across Horn / Horizon / Arc (+ one Monogram fail-case demo), optional chromatic pip (`#D71921` red = error/destructive, `#4A7FA5` blue-gray = interactive — pick one or neither), 16×16 gate + grammar-contract gate enforced. Proceed?"
2. **Phase 2a — spatial plan** — for each of the 6 variants, write the plan block (scene, element list in render order, anchor coordinates, arc-flag reasoning). Do not write SVG yet.
3. **Phase 2b — SVG generation** — produce the 6 SVGs per the table above, obeying `references/svg-contract.md`. Borrow coordinate anchors from `references/exemplar-library.md` rather than re-deriving.
4. **Phase 2c — validator gate** — `python scripts/validate_svg.py --strict <variant>.svg` for each. Any FAIL blocks the variant from the gallery. Fix the violation or drop the variant.
5. **Phase 2d — 16×16 gate + gallery** — render each surviving variant at 128px and 16px; build the HTML gallery. Anything illegible at actual 16px gets cut before the user reviews.
6. **Phase 3 — iteration** — narrow to 2–3 finalists with the user. On each refinement, return a complete replacement SVG (not a diff) and re-run the validator.
7. **Phase 4 — icon set export** — write the chosen final to `assets/icons/master.svg`. Run `python scripts/render_icon_set.py assets/icons/master.svg`. Verify the `.icns`, `.ico`, and favicon all produce.
8. **Phase 5 (optional)** — if `GEMINI_API_KEY` is set, render `void` + `clinical` + `swiss_flat` showcase images for press / README hero.
9. **Phase 6 — wiring handoff** — one-line notes for Heimdall xcassets, dashboard favicon, Linux packaging, Windows packaging. Do not auto-wire; hand off to the user.

## Success criteria

- The mark reads as heimdall at 16×16 with 50% opacity (template gate).
- A casual viewer does not confuse it with linuxserver.io's Heimdall Dashboard.
- The `strip_accent` template export is pure ink-on-transparent — zero red pixels.
- `iconutil -c icns` succeeds on the generated `.iconset`.
- The master SVG passes brand-compliance lint: `currentColor` + at most one `#D71921`, no gradients, no filters, no shadows.
