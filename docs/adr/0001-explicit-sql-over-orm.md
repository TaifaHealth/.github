# ADR 0001: Explicit SQL over an ORM in clinical services

Status: accepted, 2026-08-19

## Context

taifa-emr's Go backend needs a data access approach. GORM was proposed.
Every patient-scoped query in the platform must be filtered by
facility_id (the tenancy boundary), several queries need Postgres
features ORMs abstract poorly (jsonb audit detail, DISTINCT ON,
RETURNING, encrypted column round-trips), and cross-tenant leakage is
the single worst bug class an EMR can have.

## Decision

Explicit SQL on pgx, organised in a repository layer, no ORM.

- All SQL lives in `internal/repo/*`, one file per aggregate, behind
  narrow interfaces consumed by `internal/service/*`.
- Handlers (`internal/api`) never touch SQL: parse, authorize, call a
  service, encode.
- Every patient-scoped statement carries a visible `facility_id`
  predicate; a reviewer can grep the repo layer and see the tenancy
  boundary enforced line by line.
- sqlc may be adopted later to generate type-safe code from the same
  SQL; that decision is deferred and would not change this structure.

## Consequences

- Queries stay auditable and reviewable; ORM query-builder drift cannot
  silently drop a tenancy filter.
- More SQL is written by hand; the repo layer and integration tests
  (which run against a real Postgres) are the guard rails.
- New services (hmis, pharmacy, lab) follow the same layout:
  api -> service -> repo -> Postgres, with domain errors
  (ErrNotFound/ErrConflict/ErrValidation) mapped to HTTP at the edge.
