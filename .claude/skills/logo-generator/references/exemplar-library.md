# Exemplar library

Five canonical mark shapes with inline annotation. Feed these into the context at Phase 2 to anchor the model's coordinate geometry — LLM4SVG research shows annotated exemplars directly compensate for coordinate-tokenization drift.

Each exemplar passes the grammar contract in `svg-contract.md`, survives the 16×16 gate numerically, and demonstrates a specific geometric pattern worth reusing.

---

## E1 — Solid crescent (the Gjallarhorn archetype)

Single closed filled path, tip lower-left, bell opens upper-right. Negative space is the "inside" of the horn. Heimdall's primary direction.

```svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <g>
    <title>exemplar-crescent</title>
    <!-- outer arc: tip (24,74) curves up-and-around to bell-outer (84,42), then bell-mouth (84,50)
         inner arc: from bell-mouth back down and around to tip
         WINDING: clockwise (outer) then counter-clockwise (inner) = even-odd "hole" at bell mouth -->
    <path d="M 24 74
             Q 18 50 30 32
             Q 48 16 68 20
             Q 84 24 84 42
             L 84 50
             Q 72 50 70 42
             Q 66 32 54 32
             Q 40 34 34 52
             Q 30 66 38 72 Z"
          fill="currentColor"/>
    <!-- accent pip at bell mouth: semantic "alert sounded" signal -->
    <circle cx="79" cy="45" r="3" fill="#D71921"/>
  </g>
</svg>
```

**Why it works:** Single continuous closed path = one silhouette = reads at any size. 11 commands, all integer coordinates, closed with `Z`. The accent is a small circle, positioned at the anchor semantically tied to the concept.

---

## E2 — Outlined crescent + solid terminus

Same silhouette as E1 but rendered as outline stroke. Terminus becomes a solid disk so there is always one high-contrast anchor pixel at 16×16. Accent pip sits inside the disk.

```svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <g fill="none" stroke="currentColor" stroke-width="10" stroke-linejoin="round" stroke-linecap="round">
    <title>exemplar-outline-terminus</title>
    <!-- stroke width 10 on viewBox 100 = 1.6px at 16x16 raster — just above AA floor -->
    <path d="M 28 74 Q 22 50 34 34 Q 52 20 68 26 Q 78 32 78 46"/>
  </g>
  <!-- solid disk anchors the bell; accent pip centered inside -->
  <circle cx="78" cy="46" r="6" fill="currentColor"/>
  <circle cx="78" cy="46" r="2.5" fill="#D71921"/>
</svg>
```

**Why it works:** Stroke width is calibrated for the 16px raster floor. The disk gives the mark a strong focal anchor even when the thin stroke softens at small scales.

---

## E3 — Horizon + notch + dot (dashboard-lineage direction)

Three rectangles / one circle. No paths, no arcs, no failure modes. Cleanest possible 16×16 survival.

```svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <g fill="currentColor">
    <title>exemplar-horizon-notch-dot</title>
    <!-- horizon rule: 80u wide, 8u tall = survives at 16px (8/100 * 16 = 1.28px) -->
    <rect x="10" y="66" width="80" height="8" rx="2"/>
    <!-- watchtower notch: asymmetric left-of-center, bold enough to survive -->
    <rect x="26" y="30" width="10" height="36"/>
    <!-- watcher dot above the notch: diameter 14u = 2.24px at 16x16 -->
    <circle cx="31" cy="22" r="7"/>
  </g>
</svg>
```

**Why it works:** Rectangle + rectangle + circle is the simplest possible geometry and has zero arc-flag / unclosed-path failure surface. Every element's minimum dimension is ≥ 7 units → ≥ 1.12px at 16×16. Asymmetry (notch on the left) gives the mark visual tension without complexity.

---

## E4 — Quarter-arc + origin + terminus

A single arc, two anchor circles. Tests correct arc-flag usage.

```svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <g>
    <title>exemplar-quarter-arc</title>
    <!-- Arc from (22,78) to (78,22): Δ=56 units horizontal AND vertical
         Radius 56 → exact quarter circle.
         large-arc-flag=0 (quarter-circle subtends exactly 90°, not >180°)
         sweep-flag=1   (sweeping clockwise from bottom-left to top-right)
         Stroke-width 10 = 1.6px at 16x16 -->
    <path d="M 22 78 A 56 56 0 0 1 78 22"
          fill="none" stroke="currentColor" stroke-width="10" stroke-linecap="round"/>
    <!-- emitter origin: 16-unit diameter disk anchors the low end -->
    <circle cx="22" cy="78" r="8" fill="currentColor"/>
    <!-- signal-terminus pip at arc tip -->
    <circle cx="78" cy="22" r="5" fill="#D71921"/>
  </g>
</svg>
```

**Why it works:** The comment block above the `<path>` is the pattern to echo in every arc-bearing generation. Enumerate the math before committing to flags. Two circle anchors mean the mark survives even if the arc stroke softens.

---

## E5 — Dot-matrix monogram (control / warning)

**Do not use as a primary mark.** Included so the reviewer sees why dot-matrix fails.

```svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <g fill="currentColor">
    <title>exemplar-dotmatrix-h-control</title>
    <!-- 13 dots forming a capital H in a 3x5 grid
         Each dot r=6 → diameter 12 → 1.92px at 16x16 — individually survives
         BUT: 13 dots in 16x16 = 1.2 pixels per dot of spacing after AA → blob -->
    <circle cx="28" cy="20" r="6"/><circle cx="28" cy="36" r="6"/>
    <circle cx="28" cy="52" r="6"/><circle cx="28" cy="68" r="6"/>
    <circle cx="28" cy="84" r="6"/>
    <circle cx="44" cy="52" r="6"/><circle cx="60" cy="52" r="6"/>
    <circle cx="76" cy="20" r="6"/><circle cx="76" cy="36" r="6"/>
    <circle cx="76" cy="52" r="6"/><circle cx="76" cy="68" r="6"/>
    <circle cx="76" cy="84" r="6"/>
  </g>
</svg>
```

**Why it fails:** Each individual dot survives. The H-shape arrangement does not — adjacent dots merge through anti-aliasing at 16×16. Research-confirmed failure mode: dot-matrix marks fail when the grid is decoration applied to a conventional shape. Use dot-matrix only when the grid *is* the mark's reason for existing.

---

## Usage in generation

When generating new variants in Phase 2:

1. Load this file into context.
2. Identify which exemplar's pattern your concept is closest to.
3. Use that exemplar's coordinate anchors as the starting frame — adjust, don't re-derive.
4. If using arcs, **copy the annotation comment format from E4** and fill in your arc's own flag-reasoning.
5. Run `scripts/validate_svg.py` before presenting the variant to the user.
