# Repository Map

One repository per deployable service. Adding one is a governance decision, see
[../GOVERNANCE.md](../GOVERNANCE.md). `scripts/bootstrap-org.sh` creates them
with the standard settings.

| Repository | Deploys | Owns (data) | Depends on |
|---|---|---|---|
| `.github` | Nothing | Org policy and platform docs | Nothing |
| `taifa-emr` | API and clinical web app | Patient, Encounter, Observation, Condition, Order, MedicationRequest, AuditEvent | `taifa-interop`, `taifa-health-design` |
| `taifa-hmis` | API and operations web app | Appointment, Queue, Admission, Bed, Ward, Theatre list, Roster | `taifa-emr` |
| `taifa-pharmacy` | API and pharmacy web app | Stock, Batch, Dispense, Formulary | `taifa-emr` |
| `taifa-lab` | API, lab web app, analyzer bridge | Specimen, LabOrder, Result | `taifa-emr` |
| `taifa-radiology` | API, reporting app, DICOM bridge | Study, Report, worklist | `taifa-emr` |
| `taifa-revenue` | API and finance web app | Charge, Invoice, Payment, Claim, Coverage | `taifa-emr`, `taifa-interop` |
| `taifa-interop` | FHIR facade and integration workers | Terminology sets, mappings, outbound message log | Nothing internal |
| `taifa-portal` | Patient web app | Consent, portal identity | `taifa-emr`, `taifa-hmis` |
| `taifa-health-design` | npm package | Design tokens, components | Nothing |
| `taifa-health-docs` | Documentation site | Documentation | Nothing |
| `taifa-health-deploy` | Compose and infra definitions, seed data | Environment definitions, synthetic seed dataset | Everything |
| `taifa-health-sdks` | Published SDK packages | Generated clients | API schemas |

## Standard repository layout

```
<repo>/
├── README.md              what it is, how to run it, how to test it
├── CLAUDE.md              conventions specific to this service
├── LICENSE
├── Makefile               make dev, make test, make lint, make migrate
├── .env.example           every variable, documented, no real secrets
├── docker-compose.yml
├── backend/               FastAPI app: routers, services, repositories, models
├── frontend/              SvelteKit app
├── migrations/            forward-only
├── tests/
└── .github/
    ├── workflows/         lint, types, tests, migrations, build
    └── CODEOWNERS
```

## Settings applied to every repository

- Private by default. Making one public is a governance decision.
- `main` protected: pull request required, one approval, CI green, linear
  history, squash merge only, force push and deletion blocked.
- Wiki and projects off, discussions on where the repository has external
  consumers.
- Dependabot and secret scanning on. Push protection for secrets on.
- `CODEOWNERS` names a maintainer for every path.
- Community health files inherited from this repository, overridden locally
  only where a service genuinely differs.

## Naming

- Services that a clinician or a facility uses by name: `taifa-<domain>`
  (`taifa-emr`, `taifa-pharmacy`).
- Platform assets shared across services: `taifa-health-<thing>`
  (`taifa-health-design`, `taifa-health-docs`).
- Branches: `feat/`, `fix/`, `chore/`. Tags: `v<major>.<minor>.<patch>`.

## Plan limitations to know about

The organisation is on the GitHub Free plan. On that plan, branch protection
rules and rulesets do not apply to private repositories, and secret scanning
for private repositories needs GitHub Advanced Security. `bootstrap-org.sh`
attempts the settings and warns when they are refused rather than failing.

Until the plan changes, protection is a working agreement rather than an
enforced rule: pull requests and review are still required of everyone, and CI
still runs. Upgrade to Team before the first facility deployment, because "we
agreed not to push to main" is not an answer an auditor accepts for a system
holding patient records.
