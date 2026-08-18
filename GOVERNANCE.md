# Governance

Taifa Health is developed and maintained by RCFI. This document says who
decides what, so that decisions are made by someone rather than by nobody.

## Roles

| Role | Responsibility |
|---|---|
| **Maintainer** | Owns one or more repositories, reviews and merges, decides technical direction within the repository |
| **Platform lead** | Owns decisions that cross repositories: the data model, the API contract, authentication, the release train |
| **Clinical safety officer** | A clinically qualified person who owns the hazard log, signs off changes affecting patient care, and can block a release |
| **Data protection officer** | Owns the ODPC relationship, data protection impact assessments, and breach notification |
| **Contributor** | Anyone opening an issue or a pull request |

Every repository names its maintainers in `CODEOWNERS`. A repository without an
owner does not get created.

## How decisions are made

- **Within a repository:** the maintainer decides. Disagreements escalate to the
  platform lead.
- **Across repositories** (data model, shared API contract, a new dependency
  every service will carry, a new repository): written proposal, at least three
  working days for comment, platform lead decides.
- **Anything affecting patient care:** the clinical safety officer has a veto.
  It cannot be overridden by the platform lead, and it does not need a majority.
- **Anything affecting personal data processing:** the data protection officer
  must sign off, and a data protection impact assessment may be required before
  work starts, not after it ships.

## Architecture decisions

Cross-cutting technical decisions are recorded as ADRs in
`docs/adr/NNNN-title.md`, using the standard form: context, decision,
consequences. An ADR is never edited once accepted, it is superseded by a new
one. If you cannot explain a decision to the next engineer, it was not
recorded properly.

## Adding a repository

Repository sprawl is a real cost: another CI setup, another dependency
inventory to patch, another audit surface. To add one, state in a proposal what
it deploys, who maintains it, why it cannot live in an existing repository, and
what its data ownership is. The platform lead approves, then
`scripts/bootstrap-org.sh` creates it with the standard settings.

## Releases

- Semantic versioning per service.
- Facility deployments are pinned. A facility is never auto-upgraded into a
  breaking change.
- Every release notes its migrations, whether they need a maintenance window,
  and whether the clinical safety officer signed off.
- Security fixes can ship out of band and skip the normal train, but never skip
  the safety review if they touch clinical behaviour.
