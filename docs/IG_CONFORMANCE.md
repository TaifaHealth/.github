# IG Conformance Requirements

Implementation-level requirements extracted from the Kenyan FHIR IG
continuous builds in August 2026. This is what the code must actually do,
as opposed to what the IG landing pages say. Both IGs are drafts; pin
packages and re-extract on every upgrade PR.

## Kenya Patient Summary (KPS)

Package `ke.fhir.patient-summary`, branch `compositionResource`, 20
resource profiles, 7 NamingSystems, 1 CapabilityStatement, ~30 examples.

### Patient identity (ke-kps-Patient)

- `identifier` 1..*, `gender` 1..1, contact relationship/telecom 1..1.
- Identifier slices, by system URI:
  - National ID: `http://moh.kenya/identifier/nationalID-no`
  - **UPI**: `http://moh.kenya/identifier/UPI` (the national unique patient
    identifier from the Client Registry)
  - Passport, Birth Certificate (own systems)
- Invariant: **at least one of National ID or Birth Certificate** must be
  present. Registration UI and API validation must enforce exactly this,
  and our MPI stores all four slices.

### The summary document (ke-kps-Composition)

- `type` fixed to LOINC `60591-5`; `subject` 1..1 Patient; `author` 1..*;
  `status`, `date`, `title` 1..1.
- Sections, all MustSupport:
  - **Required 1..1**: Problems (LOINC 11450-4, entries Condition),
    Allergies (48765-2, AllergyIntolerance), Medications (10160-0,
    MedicationStatement or MedicationRequest)
  - Optional 0..1: Immunizations, Results, Procedures
- Empty sections need `emptyReason`, not absence.

### Terminology bindings that constrain our data model

| Element | Binding |
|---|---|
| Condition.code | **Required, full ICD-10** (`http://hl7.org/fhir/sid/icd-10`) |
| MedicationStatement.medication | WHO ATC value set |
| Immunization.vaccineCode | WHO ATC J07, Required |
| Immunization targetDisease | ICD-10, Required |
| Allergy manifestations, procedures, bodySite | SNOMED CT subsets, locally hosted |
| Vital signs | LOINC |
| identifier.use | HL7 v2-0203 |
| Statuses, categories, demographics | local KPS code systems |

Consequence: **ICD-10 is the national requirement today**, bound Required,
not ICD-11. We code diagnoses in ICD-10 as primary and keep ICD-11 as a
forward mapping, which reverses the emphasis older platform docs assumed.

### API surface

The CapabilityStatement is thin: server mode, JSON+XML, only 10 of 20
profiles declared (Patient/Practitioner/Organization read+search SHALL;
clinical resources read+search+create+update). **No search parameters
named, no $summary, $everything, or $document operations, and no document
Bundle example anywhere in the IG.** Document assembly
(`Bundle type=document` with Composition first) follows the base FHIR
convention because the IG never shows it. Our `taifa-interop` defines and
documents that Bundle shape, and we should expect it to be corrected
against future IG releases.

## Kenya Emergency Care IG

Branch `removedUnusedProfiles`, 23 profiles, 23 extensions, ~40 ValueSets,
~90 CodeSystems (almost all locally defined, hosted at
`nshr-uat.sha.go.ke`), 25 examples.

- **Data shapes only.** There is no CapabilityStatement, no
  OperationDefinition, no MessageDefinition, no Bundle example. Until a
  companion API spec surfaces, conformance means "our resources validate
  against the profiles", nothing more.
- Incident Encounter requires both identifiers
  `http://hie.go.ke/fhir/identifier/dispatch-id` and `.../incident-id`
  (1..1 each) plus a caller extension; point-of-care Encounter fixes
  `class` to `FLD` (field).
- Vitals are real LOINC (BP 8480-6/8462-4, GCS 9267-6/9270-0/9268-4);
  triage acuity binds Required to a local priority value set.
- Identity: Kenya National ID NamingSystem
  (`https://ilm-hie.dha.go.ke/fhir/NamingSystem/national-id`) and an
  emergency record identifier. **No UPI anywhere in this IG**; identity
  reconciliation with the KPS world is explicitly our problem, via
  extensions for unidentified/identity-verified patients.
- **Known upstream defect**: the Vital Signs and Investigation Codes
  ValueSets include from `http://localhost:8085/fhir/CodeSystem/...`, a dev
  placeholder that does not resolve. Our CI validates with a locally
  patched copy of the package, the patch is committed alongside the pin,
  and the defect is reported upstream.

## What this means for the conformance suite

1. **Seed golden fixtures from the IGs' own examples.** KPS ships a
   complete worked summary (CompositionKPS with all six sections and every
   referenced resource); the Emergency IG ships ~25 instances, several as
   valid/invalid pairs, which slot directly into the validator harness as
   positive and negative cases.
2. **Test the invariants that will actually bite**: the National
   ID/Birth Certificate presence rule, required Composition sections with
   emptyReason handling, fixed identifier systems, the `FLD` encounter
   class, ICD-10-only condition codes.
3. **Round-trip through our own Bundle convention** since no IG defines
   one, and mark that test as "ours, expect churn".
4. **Terminology fetches must tolerate the national infrastructure being
   down or wrong** (the localhost defect proves the point): pinned local
   terminology copies, refreshed deliberately.
