# Platform Architecture

How the pieces fit together, and the constraints that shaped them.

## The constraints first

Four facts about Kenyan facilities drive most of the design.

1. **Connectivity and power fail.** A sub-county hospital loses its link and
   sometimes its mains. The clinical record must keep working through the
   outage and reconcile afterwards, so anything on the critical path of care
   has to tolerate the network going away.
2. **A deployment is rarely one hospital.** A county wants one deployment
   across many facilities, with the record following the patient between them
   and reporting rolling up. Facility scoping is in the data model from the
   first migration, never retrofitted.
3. **Hardware is modest.** Target a facility server with 8 to 16 GB of RAM, not
   a Kubernetes cluster. The whole platform must come up with `docker compose`.
4. **The data outlives the vendor.** Clinical records have decade-long
   retention. Everything is exportable in an open format, and FHIR R4 is the
   contract for anything clinical that leaves the platform.

## Service map

```
                 ┌───────────────────────────────────────────────┐
   clinicians ──▶│  taifa-emr        clinical record, orders     │
   registration  │  taifa-hmis       queues, ADT, wards, theatre │
   pharmacy   ──▶│  taifa-pharmacy   dispensing, stock           │──▶ PostgreSQL 16
   lab, imaging  │  taifa-lab        specimens, results          │    Redis
   finance    ──▶│  taifa-revenue    billing, SHA claims, M-Pesa │    object storage
                 │  taifa-radiology  worklists, reports, DICOM   │
                 └───────────────┬───────────────────────────────┘
                                 │
                        ┌────────▼─────────┐
   patients ───────────▶│  taifa-interop   │──▶ SHA claims, KHIS (DHIS2),
   partner systems      │  FHIR R4 facade  │    KMHFL, HL7 v2 devices, PACS
                        └──────────────────┘
```

`taifa-portal` sits in front for patients. `taifa-health-design` is the shared
component library. `taifa-health-deploy` composes all of it.

## Boundaries that matter

- **One writer per domain.** The pharmacy service owns stock, the lab owns
  results, the EMR owns the record. Cross-domain reads go through the owning
  service's API, never straight into its tables. This is the rule that keeps
  the audit trail honest.
- **The EMR is the record of truth for clinical data.** Other services publish
  into it (a released lab result becomes an observation on the encounter), they
  do not keep a private parallel copy of the truth.
- **Money never touches the clinical path.** A billing failure cannot block a
  prescription or a discharge. Charges are raised asynchronously from clinical
  events.
- **Everything leaving the platform is FHIR.** Internal APIs are pragmatic
  REST. The moment data crosses the boundary to another organisation, it is
  FHIR R4, produced by `taifa-interop`, not by each service inventing its own.

## Core clinical entities

The names are fixed across every service and every interface. See the
terminology table in [../CONTRIBUTING.md](../CONTRIBUTING.md).

| Entity | Notes |
|---|---|
| **Patient** | Identity, demographics, national ID or birth certificate, next of kin. One record per person, per deployment, deduplicated by the master patient index |
| **Facility** | A KMHFL-coded facility. The tenancy boundary for every query |
| **Encounter** | A contact between patient and facility: outpatient visit, admission, theatre, or a telephone consultation |
| **Observation** | Anything measured or observed: vitals, lab results, clinical findings. LOINC coded where a code exists |
| **Condition** | A diagnosis or problem, ICD-10 coded (the national IG binding), with an ICD-11 forward mapping |
| **Order** | A request for something to be done: lab, imaging, medication, procedure. Has a lifecycle and an owner |
| **MedicationRequest / Dispense** | Prescribing is separate from dispensing, always |
| **Invoice / Claim** | Money, derived from clinical events, never the other way round |
| **AuditEvent** | Immutable. Every read and write of a patient record |

## Tenancy and access

- Every patient-scoped table carries `facility_id`, enforced at the repository
  layer and by row-level policies, not by remembering to add a `WHERE` clause.
- A clinician has roles scoped to facilities. Access to another facility's
  record is possible only through an explicit patient-consent flow or a
  **break-glass** action, which is always allowed but always alarming: it is
  logged, flagged, and reviewed. Emergency care must never be blocked by
  access control, so the answer is accountability, not refusal.
- Sessions are first-party (password and passkey), consistent with the rest of
  the Taifa platform. No third-party identity product on the critical path.

## Offline behaviour

Anything a clinician needs at the bedside works from a local cache and queues
its writes. Anything requiring a central authority (a claim, a national
registry lookup, a controlled drug ledger) is allowed to be unavailable and
must fail loudly rather than silently pretend to have succeeded. Reconciliation
is last-writer-wins only for non-clinical fields. Clinical conflicts are
surfaced to a human, never merged automatically.

## Audit trail

Immutable, append only, and outside the reach of application delete paths.
Every entry records who, what record, what action, when, from where, and under
what role or break-glass justification. This is a legal requirement, not a
feature, and it is the first thing an inspection asks for.

## Deployment shapes

| Shape | Who | Notes |
|---|---|---|
| **Single facility** | A private or mission hospital | One `docker compose` stack on site, nightly encrypted backup off site |
| **County** | A county health department | Central deployment, facilities as tenants, on-site cache per facility |
| **Hosted** | Facilities without IT capacity | Multi-tenant, run by RCFI, data resident in Kenya |

The same image runs in all three. Behaviour is selected by configuration, not
by a fork.

## Recorded decisions

Cross-cutting decisions live in `docs/adr/` as numbered architecture decision
records. If you are about to make a decision the next engineer will have to
reverse-engineer, write one.
