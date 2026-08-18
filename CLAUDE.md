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

Kenyan flag palette, shared with the rest of the Taifa platform:

- Black: `#050100` (text, dark surfaces, dark-theme background)
- Red: `#860000` (danger, secondary emphasis)
- Green: `#006900` (primary accent, brightened to `#1ea94e` in dark theme)
- Ink on the green accent is always white
- Warnings use neutral amber tokens, never brand colours
- Clinical severity colours are separate from brand colours and are never
  reused for decoration. Critical results and alerts own red
- Fonts: Google Sans (UI), JetBrains Mono (code, identifiers, dosages)

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
