# Standards and Interoperability

What Taifa Health speaks, and where each standard applies. Verify anything
Kenya-specific against current Ministry of Health and Digital Health Agency
guidance before you build against it, since national systems change faster than
this document.

## Clinical data exchange

| Standard | Where we use it |
|---|---|
| **HL7 FHIR R4** | The contract for all clinical data leaving the platform. Patient, Encounter, Observation, Condition, MedicationRequest, MedicationDispense, ServiceRequest, DiagnosticReport, Immunization, AllergyIntolerance, Coverage, Claim |
| **HL7 v2.x** | Device and legacy integration where FHIR is not an option: ADT feeds, lab analyzers, order and result messages (ORM, ORU) |
| **DICOM** | Imaging. Modality worklist out, studies into PACS, reports back to the record |
| **IHE profiles** | Reference for cross-enterprise patterns (patient identity, document sharing) rather than a certification target |

FHIR resources are produced by `taifa-interop`, not by each service separately.
Internal service-to-service calls stay pragmatic REST: FHIR is a wire format
for the boundary, not an internal storage model.

## Terminology and coding

| Standard | Where |
|---|---|
| **ICD-10** | Diagnoses: the KPS IG binds Condition.code Required to full ICD-10, so it is the primary diagnosis coding today. ICD-11 is kept as a forward mapping for when the national bindings move |
| **SNOMED CT** | Clinical findings, procedures, and problem list where precision matters beyond ICD |
| **LOINC** | Laboratory and observation codes, including vitals |
| **ATC and the Kenya Essential Medicines List (KEML)** | Formulary, prescribing, and procurement |
| **ICHI** | Procedures, where an international code is needed |

Rule: store the code, the system, and the display text, never the display text
alone. A free-text diagnosis is not reportable and cannot be claimed.

## Kenyan national systems

Verified against DHA/SHA sources and the IG continuous builds in August
2026. Primary government sites are often unreachable or gated, so re-verify
each interface directly during onboarding before treating it as a build
requirement.

| System | What it is | How we integrate |
|---|---|---|
| **Kenya Core FHIR IG** | The foundational profile and terminology layer (v1.0.0, published by SHA, canonical `fhir.sha.go.ke`). Every other Kenyan IG depends on it | Pinned as the base package in `taifa-interop`; our profiles derive from it |
| **Kenya Patient Summary IG** | DHA's IPS-adapted summary document (draft 0.1.0) | Produced and consumed by `taifa-emr`, see docs/SOFTWARE.md |
| **Kenya eClaims FHIR IG** | Claim, ClaimResponse, Coverage, and preauthorization profiles for SHA billing (draft 0.1.0, DHA) | Claims pipeline in `taifa-revenue` emits it via `taifa-interop` |
| **Kenya Emergency Care IG** | Pre-hospital EMS exchange, dispatch to ED handover (draft 0.1.0, DHA) | `taifa-ems`, plus handover intake on the EMR |
| **SHA** (Social Health Authority) | National insurer under the Social Health Insurance Act 2023. Provider portal at `portal.sha.go.ke`; since mid-2026 claims for Level 4+ public hospitals reportedly route through the government "Taifa Care HMIS" with DHA approval gates | Eligibility at registration, preauthorisation at point of order, eClaims submission and reconciliation from `taifa-revenue` |
| **Kenya HIE / AfyaLink** | DHA's FHIR-based exchange (OpenHIE lineage, OpenHIM mediators historically). Developer onboarding via AfyaLink: sandbox, API testing, security review, production; OAuth 2.0 / JWT | `taifa-interop` is our single connection point |
| **Client Registry** | National master patient index issuing the Unique Patient Identifier (UPI/NUPI), `cr.kenya-hie.health` | UPI resolution at registration; our MPI reconciles against it |
| **Health Facility Registry (KMHFR)** | Successor of KMHFL, `kmhfr.health.go.ke`, with community units | Facility identity; our `Facility` carries its code and reporting is keyed on it |
| **Health Worker Registry** | Practitioner identity, `hwr.dha.go.ke` | Practitioner verification on onboarding |
| **National SHR and Terminology Service** | Shared health record aggregating facility data; terminology service for SNOMED CT, ICD-10, LOINC | KPS submission target; terminology validation source for coded fields |
| **KHIS** | The national DHIS2 instance (`hiskenya.org`) for aggregate reporting | Scheduled aggregate submission (DHIS2 Web API / ADX, not FHIR) derived from clinical data |
| **DHA certification** | Under the Digital Health Act 2023 and draft Data Exchange Regulations 2025, only DHA-certified systems may connect to the national exchange (CIHIS ESB). Certification portal covers EMR, HIS, lab, pharmacy, diagnostics | A release-blocking track for `taifa-emr` and siblings: certification is scheduled work, not an afterthought |
| **M-Pesa (Daraja)** | Payments | STK push, C2B and B2C reconciliation against invoices |

The intent of the Digital Health Act 2023 is a national health information
exchange that facilities feed rather than duplicate. We build toward being a
compliant, certified node in it: canonical identifiers, FHIR out, and no
data trapped in a proprietary schema.

## Reporting

Facility reporting is a **projection of the clinical record**, never a separate
data entry exercise. The concrete MOH 700-series forms (MOH 705 outpatient
summary, MOH 717 workload, MOH 731 HIV, and the rest of the facility set)
are derived views submitted to KHIS over the DHIS2 Web API. If a report cannot be derived from the record, the record
is missing something, and that is the bug to fix. Registers, MOH tally sheets,
and county dashboards are all views over the same data.

## Versioning and compatibility

- FHIR R4 is the target. R5 is watched, not chased. When the national exchange
  moves, `taifa-interop` handles the translation so no service downstream has
  to care.
- Our own public APIs are versioned in the path (`/api/v1/`) and never break
  within a major version.
- Terminology sets are versioned data, loaded from `taifa-interop`, not
  hardcoded in each service. A new ICD release is a data update and a mapping
  review, not a code change in six repositories.

## Testing an integration

Every interface ships with a test harness and synthetic data. Integration
testing against a live national system, or against a facility's production
instance, needs written approval. Testing a claims submission with real patient
data because it "only goes to SHA" is a data protection breach.
