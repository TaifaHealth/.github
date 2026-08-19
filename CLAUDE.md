# CLAUDE.md - Taifa Health

## Company

Taifa Health, under RCFI, based in Kenya. Sibling to Taifa Mail and
TaifaSupport, and it follows the same platform conventions. GitHub
organisation: `TaifaHealth`.

## Product

Hospital software for Kenyan facilities: the electronic medical record (EMR),
the hospital management information system (HMIS), pharmacy, laboratory,
radiology, revenue and claims, and the interoperability layer that connects
them to national health systems. Sold to and deployed for private hospitals,
mission hospitals, and county health departments.

## Hard rules

1. **No patient data outside the system.** Never in an issue, a pull request, a
   commit, a log, a screenshot, a test fixture, or a chat message. Use the
   synthetic dataset in `taifa-health-deploy/seed`.
2. **Clinical impact needs clinical safety review.** Anything touching dosing,
   allergies, results, identity matching, orders, alerts, or what a clinician
   reads to decide. See `docs/CLINICAL_SAFETY.md`.
3. **Every patient-scoped query is filtered by facility**, at the repository
   layer, not by remembering a `WHERE` clause.
4. **Every read and write of a patient record is audited.** The audit trail is
   append-only and is never bypassed for performance.
5. **No em dashes** in prose, code comments, or commit messages. Use commas,
   colons, parentheses, or separate sentences.

## Brand

Assets, palette, and logo animations live in `brand/` (see `brand/README.md`,
open `brand/preview.html` for a rendered view). TaifaHealth has its own
palette, brighter than the Taifa Mail flag palette:

- Brand red `#E02128` (icon field, red wordmark variant)
- Brand green `#0B8A44` (icon diagonal, capsule, "Health" in wordmarks, links)
- Brand blue `#1565C0` (cross-mark pill tip only, never text or UI accents)
- Ink `#1E1E1E`, canvas `#F4F2EE`, text greys `#3A3A3A` / `#6B6B6B` / `#9A9A9A`
- Wordmark: "Taifa" in ink (or red), "Health" always green, weight 700,
  tight letter-spacing
- Clinical severity colours stay separate from brand colours. Critical
  results and alerts own red in the UI; the brand red is for the mark
- Fonts: Google Sans (UI, wordmarks), JetBrains Mono (code, identifiers,
  dosages)
- Logo motion: the capsule mark swaps into the cross mark on a 6s
  ease-in-out loop (crossfade, rotate, flip, pop variants). Self-contained
  animated SVGs in `brand/svg/animated/`, keyframes in `brand/README.md`.
  Pick one variant per surface, never two side by side

## Frontend style (house rules, shared with TaifaSupport)

The house style is deliberately copied across Taifa products so they look
like one team built them. TaifaSupport (`../taifa-support`) is the
reference implementation.

- **Tailwind v4, CSS-only config**: no `tailwind.config.js`. Design tokens
  live in one `@theme` block in `app.css`
- **Tailwind utilities for layout, inline `style=` with `var(--color-*)`
  for colour**, so colours cannot be silently dropped by arbitrary-value
  extraction
- **Icons: local Iconsax pack only, two-tone variant by default**, vendored
  under `frontend/src/lib/icons/` behind an `Icon.svelte` wrapper. Never
  add lucide or another icon library, it would look like a different team
- **Arrows are chevrons only.** Any directional affordance (dropdowns,
  breadcrumbs, pagination, back, collapse, sort) uses the pure chevron
  glyphs: `arrow-down4`, `arrow-up3`, `arrow-left4`, `arrow-right4` in the
  Iconsax pack. Never the tailed arrow variants (`arrow-down`, `arrow-up2`,
  and friends), never circled or squared arrows for plain navigation
- **Radius ramp, three steps**: 6px (chips, tiles), 8px (buttons, inputs,
  menus), 14px (cards, modals). A child inside a rounded parent takes a
  strictly smaller radius, and nothing is rounder than the card
- **Shadows are layered** (contact + close + mid + wide soft), never a
  single hard drop shadow
- **Motion tokens**: 100ms press, 140ms hover, 220ms panels,
  ease-out `cubic-bezier(.2,.7,.2,1)` for entrances; loops use ease-in-out.
  Every animated node carries `data-anim`, and one global
  `prefers-reduced-motion` rule kills them all
- **Focus rings are ink-coloured**, never the accent, so keyboard focus
  survives any accent colour
- **Theme**: light default, dark via `[data-theme="dark"]` set by a
  pre-paint script. A brand mark keeps its colours in both themes
- Reuse the UI primitives directory before writing a new component

## Stack

- **Backend:** Python 3.12+ / FastAPI / SQLAlchemy 2.0 / PostgreSQL 16 / Redis / Celery
- **Frontend:** SvelteKit (TypeScript) / Tailwind CSS v4
- **Auth:** first-party sessions (password and passkey), JWT, role-based access
  scoped to facility. No third-party identity product on the critical path
- **Containerisation:** Docker and docker compose, Nginx reverse proxy
- **Interop:** HL7 FHIR R4 out, HL7 v2 for devices and legacy, DICOM for imaging

## Terminology

Patient (not user or customer). Facility (not tenant or workspace). Encounter
(not visit record). Clinician (not agent or operator). Order (not request).
Use the words clinicians use, in code and in the interface.

## Repository layout

This repository is `TaifaHealth/.github`: the org profile in `profile/`, the
community health files at root, platform documentation in `docs/`, and
`scripts/bootstrap-org.sh` to create the service repositories. Service code
lives in its own repository, see `docs/REPOSITORIES.md`.
