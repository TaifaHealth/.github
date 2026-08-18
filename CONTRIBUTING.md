# Contributing to Taifa Health

These rules apply to every repository in the `TaifaHealth` organisation.

## Before anything else

Taifa Health handles patient records. Two rules override every other
convenience:

1. **No patient data leaves the system.** Not in an issue, a pull request, a
   commit message, a log paste, a screenshot, a test fixture, or a message to a
   colleague. Use the synthetic dataset in `taifa-health-deploy/seed` when you
   need realistic data. If you believe you have exposed patient data, follow
   [SECURITY.md](SECURITY.md) immediately, do not try to quietly delete it.
2. **Changes that can affect patient care get a clinical safety review.** If
   your change touches dosing, allergies, results, identity matching, orders,
   alerts, or anything a clinician reads to make a decision, say so in the pull
   request and tag the clinical safety officer. See
   [docs/CLINICAL_SAFETY.md](docs/CLINICAL_SAFETY.md).

## Getting set up

```bash
git clone git@github.com:TaifaHealth/<repo>.git
cd <repo>
cp .env.example .env
make dev
```

Every repository supports that sequence. If one does not, that is a bug worth
an issue.

## Branches and commits

- Branch from `main`: `feat/short-description`, `fix/short-description`,
  `chore/short-description`.
- Conventional commits: `feat(pharmacy): check interactions on dispense`.
- Reference the issue: `Closes #123`.
- Keep commits reviewable. A 4000-line commit is not reviewable, and in
  clinical software an unreviewed line is a hazard.

## Pull requests

- `main` is protected. Everything lands through a pull request with at least
  one approval, and squash merge only.
- Fill in the template. The clinical safety and data protection checkboxes are
  the point of it.
- CI must be green: lint, types, tests, migrations.
- New behaviour needs tests. Bug fixes need a test that fails before the fix.
- Database migrations are forward-only and must be safe to run against a live
  facility during clinic hours, or explicitly flagged as requiring a
  maintenance window.

## Code style

- **Python:** `ruff` for lint and format, `mypy` in strict mode on new modules,
  type hints everywhere. FastAPI routers stay thin, business logic lives in
  services, database access in repositories.
- **TypeScript and Svelte:** `eslint` and `prettier`, no `any` without a
  comment justifying it.
- **SQL:** explicit column lists, no `SELECT *` in application code, every
  patient-scoped query filtered by facility.
- **Comments** explain why, not what. Match the density of the file you are in.
- **Audit everything.** Any read or write of a patient record goes through the
  audit trail. Bypassing it is never a performance optimisation worth making.
- **No em dashes in prose**, code comments, or commit messages. Use commas,
  colons, parentheses, or separate sentences.

## Terminology

Use the words clinicians use, in code and in the interface.

| Use | Not |
|---|---|
| Patient | User, customer, client |
| Facility | Tenant, workspace, organisation |
| Encounter | Visit record, session |
| Order | Request, job |
| Clinician | Agent, operator |

## Reviewing

A reviewer is accountable for what they approve. Check the clinical logic, not
only the code. If you are not qualified to judge a dosing rule or a triage
threshold, say so and pull in someone who is.
