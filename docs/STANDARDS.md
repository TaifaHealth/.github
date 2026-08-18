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
| **ICD-11** | Diagnoses and morbidity reporting, with an ICD-10 mapping retained because claims and legacy reporting still expect it |
| **SNOMED CT** | Clinical findings, procedures, and problem list where precision matters beyond ICD |
| **LOINC** | Laboratory and observation codes, including vitals |
| **ATC and the Kenya Essential Medicines List (KEML)** | Formulary, prescribing, and procurement |
| **ICHI** | Procedures, where an international code is needed |

Rule: store the code, the system, and the display text, never the display text
alone. A free-text diagnosis is not reportable and cannot be claimed.

## Kenyan national systems

| System | What it is | How we integrate |
|---|---|---|
| **SHA** (Social Health Authority) | The national insurer under the Social Health Insurance Act 2023, replacing NHIF. Covers the primary health care fund, the social health insurance fund, and the emergency and chronic illness fund | Eligibility check at registration, benefit and preauthorisation rules at the point of order, claim submission and reconciliation from `taifa-revenue` |
| **KHIS** | The national DHIS2 instance for aggregate reporting | Scheduled aggregate submission of the MOH reporting set, derived from clinical data rather than typed in a second time |
| **KMHFL** | Kenya Master Health Facility List | Facility identity. Our `Facility` carries its KMHFL code, and reporting is keyed on it |
| **Client and provider registries** | National identity for patients and practitioners under the health information exchange | Master patient index reconciliation, practitioner verification |
| **M-Pesa (Daraja)** | Payments | STK push, C2B and B2C reconciliation against invoices |

The intent of the Digital Health Act 2023 is a national health information
exchange that facilities feed rather than duplicate. We build toward being a
compliant node in it: canonical identifiers, FHIR out, and no data trapped in a
proprietary schema.

## Reporting

Facility reporting is a **projection of the clinical record**, never a separate
data entry exercise. If a report cannot be derived from the record, the record
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
