# Software Catalogue

Everything TaifaHealth builds, how hard each piece is, which FHIR
Implementation Guides it must conform to, and the order to build in.
Difficulty is rated 1 to 5: a 1 is weeks with one engineer, a 5 is the
better part of a year with several and a clinician in the room.

The Kenyan IG family that anchors conformance (all continuous builds as of
August 2026, so pin versions and expect churn): **Kenya Core FHIR IG**
(v1.0.0, SHA, the foundational layer every other IG depends on), the two
detailed below, and the **Kenya eClaims FHIR IG** (draft 0.1.0, DHA:
Claim/ClaimResponse/Coverage and preauthorization profiles that
`taifa-revenue` must emit). The two that shape the product most:

- **Kenya Patient Summary (KPS)**: IPS-modeled FHIR R4 document every
  point-of-care system must produce and consume. Composition typed LOINC
  60591-5 with required Problems, Allergies, and Medications sections
  (optional Immunizations, Results, Procedures), 23 `ke-kps-*` profiles,
  UPI identity via the national Client Registry, submission through Kenya
  HIE transactions, terminology from LOINC, ICD-10, SNOMED CT, ATC, and
  100+ Kenyan code systems. Its business processes KPS.A to KPS.G
  (registration, consultation, diagnostics, treatment, immunization,
  emergency, referral) are, in effect, the functional spec of an outpatient
  EMR.
- **Kenya Emergency Care IG**: pre-hospital EMS exchange, dispatch through
  ambulance response to ED handover. 27 profiles (incident and
  point-of-care Encounters, triage acuity and vitals Observations,
  medication administrations, a Composition handover document), SHA NSHR
  code systems, no Patient profile of its own (identity resolution is left
  to the EMR side). Scope ends at facility handover, so it defines an EMS
  product plus an intake surface on the EMR, not the EMR itself.

## The catalogue

| # | Product | What it is | Difficulty | Why that rating |
|---|---|---|---|---|
| 1 | **taifa-interop** | FHIR R4 facade, IG conformance layer, terminology client, HIE/registry connectors (Client Registry UPI, KMHFL, KHIS), HL7 v2 bridges | **4** | Not much UI, but it carries every IG obligation, every national dependency, and the terminology problem. Everything else leans on it |
| 2 | **taifa-emr** | Clinical core: registration, encounters, notes, problems, allergies, orders, results, prescribing, referrals, discharge. Produces and consumes KPS | **5** | Largest surface, clinical safety review on most changes, identity/merge logic, offline behaviour. The KPS.A-G processes are its requirements document |
| 3 | **taifa-hmis** | Scheduling, queues and triage, ADT, beds and wards, theatre, rosters, facility reporting | **4** | Big but mostly operational logic; less terminology pain, no document exchange of its own. Reporting derivation is the hard corner |
| 4 | **taifa-ems** | Emergency care per the Emergency IG: dispatch console (CAD), responder/paramedic mobile app, ambulance tracking, ED handover documents | **4** | Real-time positions, offline-first mobile capture, 27 profiles to emit. Bounded scope, but mobile + realtime + a draft IG is real risk. Separate buyer (counties, ambulance services) |
| 5 | **taifa-revenue** | Cash, corporate and insurance billing, SHA eligibility and claims, M-Pesa reconciliation | **4** | The logic is medium; the difficulty is the external dependency on SHA interfaces (the KPS work references a separate Kenya eClaims IG) and reconciliation correctness. Money bugs are audit findings |
| 6 | **taifa-lab** | LIS: orders, specimens, analyzer interfacing, validation, release | **3.5** | Well-trodden domain; analyzer interfacing (HL7 v2 / ASTM over serial and TCP) is fiddly per-device work that never fully ends |
| 7 | **taifa-pharmacy** | Dispensing, stock, batches and expiry, formulary (KEML), interaction checks | **3** | Clear domain model; interaction/dose checking is the clinically sensitive part and needs safety review |
| 8 | **taifa-radiology** | RIS: worklists, reporting, DICOM modality integration, PACS | **4** | DICOM is its own world; do it after the LIS proves the ordering/results loop |
| 9 | **taifa-portal** | Patient portal: appointments, results, visit history, consent | **2.5** | Thin client over EMR/HMIS APIs; consent flows are the only subtle part |
| 10 | **taifa-health-design** | Design system: tokens, Iconsax two-tone icon pack, Svelte primitives, the brand in `brand/` | **2** | Port the TaifaSupport house style; mostly disciplined assembly |
| 11 | **taifa-health-deploy** | Compose stacks, facility server images, backups, synthetic seed data | **2.5** | Small pieces, high stakes; restore testing and the offline story live here |
| 12 | **taifa-health-docs** | Documentation site | **1** | Static site, house style |
| 13 | **taifa-health-sdks** | Generated API clients | **2** | Codegen from OpenAPI/FHIR packages once APIs stabilize |

The full-suite estimate only means anything phased. Phase 1 of the roadmap
(outpatient record a facility can run on) is items 1, 2, 10, 11 plus thin
slices of 6 and 7.

## Conformance and testing (the part that is not optional)

The extracted per-profile requirements (required elements, identifier
systems, terminology bindings, known IG defects) live in
[IG_CONFORMANCE.md](IG_CONFORMANCE.md). "All IGs followed" is a CI
property, not a promise:

- **Pin IG packages.** Each IG is consumed as a versioned FHIR package
  (`ke.fhir.patient-summary#0.1.0`, the emergency IG likewise), vendored in
  `taifa-interop`. Upgrades are deliberate PRs with a diff review, because
  both IGs are 0.1.0 drafts that will change under us.
- **Validate in CI with the official HL7 FHIR validator** (Java
  `validator_cli.jar`) against the pinned packages. Every profile we emit
  has golden example fixtures; the validator gate fails the build on any
  error, and warnings are triaged, not ignored.
- **Round-trip contract tests.** Produce a KPS Bundle from seeded clinical
  data, validate it, consume it back, and assert clinical equivalence
  (problems, allergies, medications survive intact). Same for the emergency
  handover Composition into ED intake.
- **Terminology tests.** Every coded field asserts system+code+display
  against the pinned code systems; a free-text-only diagnosis fails the
  test suite the same way it would fail a claim.
- **Synthetic Kenyan test data** in `taifa-health-deploy/seed`: UPI-shaped
  identifiers, KMHFL facility codes, KEML medications. Never production
  data, per compliance rules.
- **A conformance suite lives in `taifa-interop/conformance/`** and runs
  against any service's staging URL, so "does taifa-emr still produce valid
  KPS" is one command and a nightly job, not a belief.

## Stack decision

The house stack elsewhere is Python/FastAPI + SvelteKit. The request on the
table is a fast-language backend. Recommendation: **Go backend, SvelteKit
frontend, PostgreSQL 16**, with two qualifications.

Why Go fits this product specifically:

- **Facility servers, not clouds.** The architecture targets 8 to 16 GB
  on-prem boxes that lose power. A Go service is a single static binary
  with tens of MB of RSS; the same services in Python need an interpreter,
  a process manager, and 5 to 10x the memory, and a JVM FHIR stack (HAPI)
  wants more than the whole box has.
- **The concurrent edges are where we live.** HL7 v2 MLLP listeners,
  analyzer TCP bridges, ambulance position streams, queue websockets: Go's
  concurrency model is built for exactly this; Python needs asyncio
  gymnastics or extra processes for each.
- **Operationally boring.** Cross-compile for the facility hardware, ship
  one binary per service, no dependency resolution at deploy time. For a
  product installed by a county IT officer, that is a feature with a face.

The qualifications:

1. **FHIR tooling is thinner in Go than Java or TypeScript.** We accept
   that because conformance enforcement happens in CI with the Java
   validator regardless of runtime language, and profile types can be
   code-generated from the IG StructureDefinitions. We write FHIR
   serialization once, in `taifa-interop`, and the other services speak our
   internal REST.
2. **It breaks stack symmetry with Taifa Mail and TaifaSupport.** The
   frontend does not: SvelteKit + Tailwind v4 + the house design rules stay
   identical, so the products still look and feel like one family. The
   backend divergence is the price of the deployment story, and it is
   contained by keeping the same service shape (thin handlers, service
   layer, repository layer, forward-only migrations, `make dev`).

If team reality argues otherwise (hiring, existing Python muscle), the
honest fallback is Python everywhere except `taifa-interop` and the device
bridges in Go; at facility scale FastAPI is not the bottleneck, Postgres
is. What we do not do is Rust (development cost buys nothing here) or a
JVM (memory budget) or per-service language free-for-all.

Frontend is SvelteKit in either case, with the TaifaSupport house rules:
Tailwind v4 CSS-only config, tokens in `@theme`, inline `var(--color-*)`
for colour, Iconsax two-tone icons behind an `Icon.svelte` wrapper, the
motion vocabulary, ink focus rings, and the brand in `brand/`.

## Where to start

**Start with taifa-interop and taifa-emr together, KPS-first.** Reasons:

1. **KPS is the center of gravity.** Its business processes are the
   outpatient EMR spec, its Composition is the artifact every national
   integration consumes, and its Client Registry/UPI flow is the identity
   backbone everything else (claims, referrals, emergency access) assumes.
   Conform here and the platform is a citizen of the national architecture
   from day one.
2. **The Emergency IG is a different product for a different buyer.** It is
   pre-hospital: dispatch, ambulances, handover. Building taifa-ems first
   would mean building mobile, realtime, and offline hard parts against a
   draft IG before we have an EMR to hand patients to. It comes after the
   record exists; the EMR's ED intake consumes the handover Composition
   when it does.
3. **It matches roadmap Phase 1** (docs/ROADMAP.md): one facility running
   its outpatient department without paper is the exit criterion, and
   KPS.A to KPS.G is exactly that loop.

Two ecosystem facts that shape the plan beyond the IGs:

- **DHA certification is a gate, not a nicety.** Under the Digital Health
  Act 2023 and the draft Data Exchange Regulations 2025, only DHA-certified
  systems may connect to the national exchange, and there is a certification
  portal covering EMR, HIS, lab, pharmacy, and diagnostics. Certification
  requirements go on the taifa-emr roadmap as scheduled work with a named
  owner, and the conformance CI exists partly to make that audit boring.
- **The SHA claims channel is in flux.** Reporting in mid-2026 says Level 4+
  public hospital claims now route through the government's own "Taifa Care
  HMIS" with SHA/DHA approval, on secondary sources with a reported
  September 2026 cutoff. What that means for third-party systems must be
  verified with SHA/DHA directly before taifa-revenue's claims work is
  scheduled; the eClaims IG is the payload standard either way.

Concrete first milestone: registration with UPI resolution against a mocked
Client Registry, an outpatient encounter with coded problems, allergies,
and medications, and a valid `ke-kps-composition` Bundle out the other end,
validated in CI against the pinned package. That is the smallest thing that
is simultaneously a usable product slice and proof the conformance
machinery works.
