# Taifa Health

[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-860000?style=flat-square&labelColor=101010)](LICENSE)
[![© Taifa Health](https://img.shields.io/badge/%C2%A9-Taifa%20Health-006900?style=flat-square&labelColor=050100)](https://github.com/TaifaHealth)

Hospital software for Kenya. Taifa Health builds and maintains the clinical
and administrative systems a facility runs on: the electronic medical record
(EMR), the hospital management information system (HMIS), pharmacy, laboratory,
radiology, billing and claims, and the interoperability layer that connects all
of it to national health systems.

This repository is the organisation repository (`TaifaHealth/.github`). It holds
the public organisation profile, the community health files that every other
repository inherits (contributing guide, security policy, code of conduct,
issue and pull request templates), and the platform-wide documentation that is
not owned by any single service.

> **No patient data ever belongs in this repository**, in an issue, in a bug
> report, or in a screenshot attached to one. See [SECURITY.md](SECURITY.md)
> and [docs/COMPLIANCE.md](docs/COMPLIANCE.md).

## What we are building

A facility should be able to run the whole hospital on one platform, from the
registration desk to the discharge summary to the SHA claim, and a county
should be able to run many facilities on one deployment.

| Domain | What it covers |
|---|---|
| **EMR** | Patient registration and master patient index, encounters, clinical notes, problem list, allergies, vitals, orders, results, e-prescribing, referrals, discharge summaries |
| **HMIS** | Scheduling, queue and triage, admissions and ADT (admit, discharge, transfer), bed and ward management, theatre lists, staff rosters, facility reporting |
| **Pharmacy** | Dispensing, stock and expiry tracking, formulary, interaction and dose checking, procurement |
| **Laboratory** | Order entry, specimen tracking, analyzer interfacing, result validation and release |
| **Radiology** | Modality worklists, reporting, DICOM and PACS integration |
| **Revenue** | Cash, corporate and insurance billing, SHA (Social Health Authority) claims, M-Pesa, invoicing and receipting |
| **Interoperability** | HL7 FHIR R4 API, HL7 v2 interfaces, DHIS2 and KHIS reporting, KMHFL facility identity |
| **Patient access** | Appointment booking, results and visit history, consent management |

Details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and
[docs/STANDARDS.md](docs/STANDARDS.md). The full catalogue with difficulty
ratings, IG conformance obligations, and build order is
[docs/SOFTWARE.md](docs/SOFTWARE.md).

## Repositories

The org is multi-repo, one repository per deployable service, matching the
convention used across the Taifa family. See
[docs/REPOSITORIES.md](docs/REPOSITORIES.md) for the full map, ownership, and
what belongs in each.

| Repository | Purpose |
|---|---|
| [`.github`](https://github.com/TaifaHealth/.github) | This repository: org profile, shared policies, platform docs |
| `taifa-emr` | Clinical core and the patient record |
| `taifa-hmis` | Hospital operations: scheduling, ADT, wards, theatre |
| `taifa-pharmacy` | Dispensing, stock, formulary |
| `taifa-lab` | Laboratory information system |
| `taifa-radiology` | Radiology information system and imaging |
| `taifa-ems` | Emergency medical services: dispatch, ambulance, ED handover (Kenya Emergency Care IG) |
| `taifa-revenue` | Billing, insurance, SHA claims, payments |
| `taifa-interop` | FHIR facade, HL7 v2, DHIS2 and national registries |
| `taifa-portal` | Patient-facing portal |
| `taifa-health-design` | Shared design system and component library |
| `taifa-health-docs` | Documentation site |
| `taifa-health-deploy` | Infrastructure, containers, environments, backups |
| `taifa-health-sdks` | Client SDKs for the public APIs |

Nothing outside this list is created on a whim. Adding a repository is a
governance decision, see [GOVERNANCE.md](GOVERNANCE.md).

## Platform conventions

Every service in the org follows the same shape, so an engineer who has worked
in one repository can work in the next one.

- **Backend:** Python 3.12+ / FastAPI / SQLAlchemy 2.0 / PostgreSQL 16 / Redis / Celery
- **Frontend:** SvelteKit (TypeScript) / Tailwind CSS v4
- **Auth:** first-party sessions (password and passkey), JWT, role-based access control scoped to facility
- **Containerisation:** Docker and docker compose, Nginx reverse proxy
- **API style:** REST for the product surface, FHIR R4 for anything clinical that leaves the platform
- **Every repository ships:** `README.md`, `.env.example`, `Makefile` with `make dev`, `docker-compose.yml`, tests, and a migration path

## Getting started as a contributor

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) and
   [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
2. Read [docs/COMPLIANCE.md](docs/COMPLIANCE.md) before you touch anything that
   reads or writes a patient record. This is not optional reading in health
   software.
3. Pick up an issue in the relevant service repository, or open one using the
   templates.
4. If your change could affect patient care, raise it with the
   **clinical safety** template. See [docs/CLINICAL_SAFETY.md](docs/CLINICAL_SAFETY.md).

## Bootstrapping the org

`scripts/bootstrap-org.sh` creates the repositories above under the
organisation once it exists on GitHub, with sensible defaults (private,
protected `main`, no wiki, squash merges only). It is idempotent: it skips
repositories that already exist.

```bash
gh auth refresh -h github.com -s admin:org,delete_repo   # one time, needs org admin scope
./scripts/bootstrap-org.sh TaifaHealth --dry-run         # see what it would do
./scripts/bootstrap-org.sh TaifaHealth
```

## Contact

- Security and vulnerability reports: see [SECURITY.md](SECURITY.md)
- Everything else: see [SUPPORT.md](SUPPORT.md)

Taifa Health is a product of RCFI.
