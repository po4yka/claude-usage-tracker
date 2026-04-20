# Background styles — on-brand subset for heimdall

Six showcase backgrounds for Gemini's Nano Banana renderer, tuned for heimdall. The same six keys appear in `scripts/generate_showcase.py` (`BACKGROUND_STYLES` dict). Keep both files in sync.

## Dark styles

### 1. THE VOID — key `void`  *(secondary dark — use for high-contrast editorial moments; no longer the default)*

**Concept**: Absolute minimalism. High-contrast editorial moment; not the everyday dark default (that role moved to `apple_chrome`).

**Visual characteristics**:
- Base: pure OLED black (`#000000`) — the same token as heimdall's `--black` dark canvas
- Noise: extremely fine silver/white high-contrast micro noise
- Texture: cold, sharp electronic film grain
- Atmosphere: minimal — only a faint icy white glow at one extreme corner
- Mood: infinite void, distant starlight at the universe's edge

**Suitable for**: the core product framing — `heimdall` is a quiet local observer.

**Saturation**: ≤ 5%.

---

### 2. FROSTED HORIZON — key `frosted`

**Concept**: Modern breathing space with physical thickness. Use when the user wants a softer, more ambient render than `void`.

**Visual characteristics**:
- Base: deep titanium gray or midnight slate gray (never pure black)
- Noise: organic film-like dust texture
- Texture: unpolished rough metal or stone surface
- Atmosphere: large neutral-grey halo, edges dissolved like mist (no blue cast — override from upstream)
- Mood: sophisticated, breathable, premium

**Suitable for**: marketing / release renders; less appropriate for the dashboard mood, more appropriate for press.

**Saturation**: ≤ 10%, neutral only.

---

### 3. STUDIO SPOTLIGHT — key `spotlight`

**Concept**: Physical studio lighting simulation.

**Visual characteristics**:
- Base: extremely dark warm carbon gray
- Noise: slightly larger grain simulating low-light photography
- Texture: paper print grain in weak light
- Atmosphere: single-side softbox creating natural vignette
- Mood: editorial magazine quality, professional photography

**Suitable for**: feature-story coverage, README hero images.

**Saturation**: 0%.

---

## Light styles

### 4. EDITORIAL PAPER — key `editorial`

**Concept**: High-end specialty paper with extreme whitespace.

**Visual characteristics**:
- Base: off-white, alabaster, or pearl white (never pure white)
- Noise: high-grade watercolor or rough art paper texture
- Texture: physical paper tactile suggestion
- Atmosphere: natural light diffuse reflection, slight warm gray vignette at corners
- Mood: humanistic, independent magazine aesthetic

**Suitable for**: long-form writing about heimdall, documentation hero images.

**Saturation**: ≤ 5%, warm neutral only.

---

### 5. CLINICAL STUDIO — key `clinical`  *(heimdall default — light; pairs with Apple Chrome for dark)*

**Concept**: Spatial order with high contrast. Matches DESIGN.md's "printed technical manual" light-mode mood exactly.

**Visual characteristics**:
- Base: pure white or extremely light cold gray — aligns with heimdall's `--black` light token (`#F5F5F5`)
- Noise: high-frequency sharp cold-toned digital micro noise
- Texture: enhanced sharpness
- Atmosphere: pure light/shadow structure — large softbox creating smooth gray-white gradient
- Mood: sterile space, geometric order, 3D depth in 2D

**Suitable for**: the core product framing on light surfaces.

**Saturation**: ≤ 2%.

---

### 6. APPLE CHROME — key `apple_chrome`  *(heimdall default — dark, replaces `void` as default)*

**Concept**: Apple keynote render. Refined charcoal surface with subtle vibrancy and gentle directional light — the Liquid Glass navigation-chrome feel applied at the macro scale.

**Visual characteristics**:
- Base: refined dark charcoal (`#0A0A0A` range — heimdall's canonical dark canvas, not OLED black)
- Subtle lensing / vibrancy gradient from one edge (simulates a softbox off-frame)
- Fine-grained film dust texture, neutral saturation
- Atmosphere: a very mild cool tint in the darker regions (≤ 5% saturation), suggestive of chrome / glass without being iridescent
- Mood: Apple product-page hero render; restrained, expensive, native

**Suitable for**: heimdall's canonical dark-mode hero renders. Product pages, release announcements, README hero images.

**Saturation**: ≤ 5%, neutral-cool only.

---

### 7. SWISS FLAT — key `swiss_flat`

**Concept**: Absolute flatness and timeless authority.

**Visual characteristics**:
- Base: 100% pure solid colour — pick ONE of heimdall's tokens: `#000000` (OLED black canvas), `#111111` (card surface dark), `#F5F5F5` (warm off-white canvas), `#FFFFFF` (card surface light). No vintage greens, burgundies, or navies.
- Noise: none
- Texture: none
- Atmosphere: zero gradients, zero effects — just colour + shape
- Mood: extreme confidence, classic authority

**Suitable for**: documentation, packaging artwork, anywhere you need a bulletproof render.

**Saturation**: 0%. Pure neutral only.

---

## Selection guide

### By use-case

| Use-case | Recommended styles |
| --- | --- |
| Default hero (dark) | VOID, SWISS FLAT (`#000000`) |
| Default hero (light) | CLINICAL STUDIO, SWISS FLAT (`#F5F5F5`) |
| Marketing render | FROSTED HORIZON, STUDIO SPOTLIGHT |
| Documentation | CLINICAL STUDIO, EDITORIAL PAPER |
| Press kit | SWISS FLAT, VOID |

### By mood (maps to DESIGN.md §1)

| Mood | Recommended styles |
| --- | --- |
| Instrument panel in a dark room | VOID, SPOTLIGHT |
| Printed technical manual | CLINICAL STUDIO, EDITORIAL PAPER |
| Timeless authority | SWISS FLAT |

### By contrast

| Contrast | Styles |
| --- | --- |
| High | VOID, CLINICAL STUDIO, SWISS FLAT |
| Medium | FROSTED HORIZON |
| Low | EDITORIAL PAPER |

## Implementation notes

All six styles:
1. **Strictly neutral.** Saturation ≤ 10%, no chromatic cast. No exceptions.
2. **Fine noise where applicable** — adds physical quality without decoration.
3. **Micro-typography.** Inter or Geist Mono only. Never decorative display faces. Tiny text (6–9pt) in corners.
4. **Breathing space.** Generous negative space around the mark (40%+ of canvas unused).
5. **Adaptive logo colour.** Dark backgrounds → white mark (`--text-display` / `#FFFFFF`); light backgrounds → black mark (`--text-display` / `#000000`). `swiss_flat` follows the luminance of the chosen token.

## Banned (do NOT re-add)

| Upstream key | Why banned in heimdall |
| --- | --- |
| `fluid` | Deep purple / Klein blue base — chromatic accent forbidden by DESIGN.md §2. |
| `analog_liquid` | Vivid orange / blue / green + iridescent metallic — double violation. |
| `led_matrix` | Glowing dot matrix, cyberpunk — glow + neon forbidden. DESIGN.md §7 hard-bans phosphor. |
| `iridescent` | Holographic light purple / light blue / soft pink — chromatic + iridescence. |
| `morning` | Pastel colour dissolve — chromatic. |
| `ui_container` | Gradient base + frosted glass + rounded corners — multi-violation. |

If a new background need arises, extend `DESIGN.md` first, then mirror the key here and in `scripts/generate_showcase.py`.
