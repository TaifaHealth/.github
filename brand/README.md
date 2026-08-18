# TaifaHealth Brand Assets

Source of truth for the TaifaHealth logo, palette, and logo animations.
Imported from the Logo Preview design project (claude.ai/design,
`f287224e-f2eb-434d-a8b6-24541533d8a2`). Open `preview.html` in a browser to
see everything below rendered.

## Palette

| Token | Hex | Used for |
|---|---|---|
| Brand red | `#E02128` | Icon field, "Taifa" in the red wordmark, link hover |
| Brand green | `#0B8A44` | Icon diagonal, capsule fill, "Health" in wordmarks, links |
| Brand blue | `#1565C0` | Cross-mark vertical capsule tip, blue outline variant |
| Ink | `#1E1E1E` | "Taifa" in standard wordmarks, headings |
| Text strong | `#3A3A3A` | Section labels |
| Text muted | `#6B6B6B` | Captions |
| Text faint | `#9A9A9A` | Fine print under lockups |
| Canvas | `#F4F2EE` | Page background behind the brand |
| White | `#FFFFFF` | Capsule bodies, strokes on the icon field |

This is TaifaHealth's own palette: brighter red and green than the Taifa Mail
flag palette (`#860000` / `#006900`), plus a blue that no sibling brand uses.
The blue is reserved for the pill tip and the blue outline mark, never for
text or UI accents.

Fonts: Google Sans (UI and wordmarks), loaded from Google Fonts in the
preview. Wordmark weight 700 with tight letter-spacing (-0.3 to -0.5px),
"Taifa" in ink (or red in the red variant), "Health" always green.

## Files

All SVGs share one geometry: a 1024x1024 viewBox, an 800x800 rounded square
(`rx=180`) at 112,112 for the icon field, and true-capsule pills (`rx` = half
the short side).

| File | What it is |
|---|---|
| `svg/logo.svg` | Primary app icon: red field, green diagonal, white/green capsule at 45 degrees |
| `svg/logo-code.svg` | Same as `logo.svg` (kept because the design project ships both names) |
| `svg/logo-plus.svg` | Cross variant: horizontal green/white capsule crossed by a vertical white/blue capsule |
| `svg/bg.svg` | Icon field only (red square + green diagonal), the backdrop layer for animations |
| `svg/pill-capsule.svg` | Capsule mark alone, white stroke, for layering over `bg.svg` |
| `svg/pill-cross.svg` | Cross mark alone, white stroke, for layering over `bg.svg` |
| `svg/pill-capsule-outline.svg` | Capsule mark with green outline, standalone on light backgrounds |
| `svg/pill-cross-outline.svg` | Cross mark with green outline, used in the horizontal and stacked lockups |
| `svg/pill-cross-outline-blue.svg` | Cross mark with blue outline, alternate |
| `png/*` | 1024px raster exports of the eight marks (use `png/logo.png` for the GitHub org avatar) |

## Lockups

- **Horizontal:** green cross outline + `Taifa`(ink)`Health`(green), 44px/700, gap 4px.
- **Stacked:** mark above the wordmark, 30px/700.
- **App-icon:** `logo-plus.svg` beside the wordmark, 32px/600.
- **Wordmark only:** `Taifa` red, `Health` green, 40px/700.

## Logo animations

The brand motion is one idea: the capsule mark swaps into the cross mark and
back, on a 6s ease-in-out loop over the static `bg.svg` field. Timeline: mark
A holds 0-40%, transition 40-50%, mark B holds 50-90%, transition back
90-100%.

Two ways to use it:

1. **Self-contained SVGs** in `svg/animated/`: `logo-crossfade.svg`,
   `logo-rotate.svg`, `logo-flip.svg`, `logo-pop.svg`. CSS keyframes are
   embedded, so they animate even as a plain `<img src>` or CSS background,
   and they freeze on the capsule under `prefers-reduced-motion`. Regenerate
   with `python3 scripts/build_animated_logos.py`.
2. **CSS layering** for app code: stack `pill-capsule.svg` and
   `pill-cross.svg` over `bg.svg` and apply the keyframes below (these are
   verbatim from the design file, also in `preview.html`):

```css
@keyframes showA {0%,40%{opacity:1}50%,90%{opacity:0}100%{opacity:1}}
@keyframes showB {0%,40%{opacity:0}50%,90%{opacity:1}100%{opacity:0}}
@keyframes rotA  {0%,40%{transform:rotate(0deg);opacity:1}50%,90%{transform:rotate(90deg);opacity:0}100%{transform:rotate(0deg);opacity:1}}
@keyframes rotB  {0%,40%{transform:rotate(-90deg);opacity:0}50%,90%{transform:rotate(0deg);opacity:1}100%{transform:rotate(-90deg);opacity:0}}
@keyframes flipA {0%,44%{transform:rotateY(0deg);opacity:1}46%,89%{opacity:0}50%,90%{transform:rotateY(180deg)}100%{transform:rotateY(360deg);opacity:1}}
@keyframes flipB {0%,44%{transform:rotateY(-180deg);opacity:0}46%,89%{opacity:1}50%,90%{transform:rotateY(0deg)}94%{opacity:0}100%{transform:rotateY(180deg);opacity:0}}
@keyframes popA  {0%,40%{transform:scale(1);opacity:1}50%,90%{transform:scale(0);opacity:0}100%{transform:scale(1);opacity:1}}
@keyframes popB  {0%,40%{transform:scale(0);opacity:0}52%{transform:scale(1.08);opacity:1}56%,90%{transform:scale(1);opacity:1}100%{transform:scale(0);opacity:0}}
/* each layer: animation: <name> 6s ease-in-out infinite; flip needs perspective: 800px on the parent */
```

One deviation in the standalone SVGs: the flip variant uses `scaleX()` to
emulate `rotateY()`, because Safari flattens 3D transforms on SVG elements.
In HTML (the CSS layering route) use the real `rotateY` keyframes above.

Pick one variant per surface and keep it: crossfade for calm surfaces
(loading states, the docs site), pop for onboarding or success moments.
Never run two variants side by side in product UI.
