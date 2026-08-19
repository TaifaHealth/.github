# KPS conformance rules, derived from the vendored packages

Every rule below is read out of the packages pinned in [`PINS.md`](PINS.md), not
from an IG landing page and not from an international publication. Each carries
the StructureDefinition and the element id it comes from, so it can be traced
back to `ig/extract/kps-summary.json` and re-derived after any package upgrade.

This is the checklist that `taifa-interop/internal/kps` and our golden-bundle
tests are measured against. Rules are stated as testable assertions.

**Source of truth**: `ke.fhir.patient-summary@0.1.0`, canonical
`https://fhir.dha.go.ke/ig/patient-summary`, sha256
`8b00075d…992b` (full value in `PINS.md`).

Rule ids: `KPS-<PROFILE>-<n>`. Severity `MUST` = the official validator raises an
error; `SHOULD` = MustSupport or a base-spec invariant we choose to enforce.

---

## 0. Document-level rules (ours, not the IG's)

The KPS package contains **no Bundle profile and no document Bundle example**.
The only Composition instance it ships (`Composition-CompositionKPS.json`) is a
bare resource. So every rule in this section is *our* convention, taken from
base FHIR R4 document semantics, and must be marked as ours in tests: it is the
part most likely to churn when the IG finally specifies an exchange format.

| id | rule | severity | source |
|---|---|---|---|
| KPS-DOC-1 | `Bundle.resourceType` = `Bundle` | MUST | base FHIR |
| KPS-DOC-2 | `Bundle.type` = `document` | MUST | base FHIR `bdl-9`/document semantics |
| KPS-DOC-3 | `Bundle.entry[0].resource.resourceType` = `Composition` | MUST | base FHIR `bdl-11` |
| KPS-DOC-4 | every `Reference.reference` in the document resolves to an entry, by `fullUrl` or `Type/id` | MUST | base FHIR `bdl-10` |
| KPS-DOC-5 | `Bundle.identifier` and `Bundle.timestamp` present | SHOULD | base FHIR |

`fullUrl` values must be absolute and must make the relative references inside
the resources resolvable (we use `https://fhir.dha.go.ke/fhir/<Type>/<id>`).

---

## 1. `ke-kps-composition`

`https://fhir.dha.go.ke/ig/patient-summary/StructureDefinition/ke-kps-composition`

### Structure

| id | rule | severity | element |
|---|---|---|---|
| KPS-COMP-1 | `Composition.id` present | MUST (1..1) | `Composition.id` |
| KPS-COMP-2 | `Composition.meta` present | MUST (1..1) | `Composition.meta` |
| KPS-COMP-3 | `Composition.meta.profile` contains exactly `https://fhir.dha.go.ke/ig/patient-summary/StructureDefinition/ke-kps-composition` | MUST (1..*, patternCanonical) | `Composition.meta.profile` |
| KPS-COMP-4 | `Composition.type` matches the pattern **system `http://loinc.org`, code `60591-5`, display `Patient summary Document`** | MUST (patternCodeableConcept) | `Composition.type` |
| KPS-COMP-5 | `Composition.subject` present and references a `ke-kps-patient` | MUST (1..1, targetProfile) | `Composition.subject` |
| KPS-COMP-6 | `Composition.status`, `.date`, `.title`, `.author` present | MUST (base 1..1 / 1..*) | base `Composition` |
| KPS-COMP-7 | `Composition.author` references only `ke-kps-organization`, `ke-kps-practitioner` or `ke-kps-practitioner-role` | MUST (targetProfile) | `Composition.author` |
| KPS-COMP-8 | `Composition.encounter`, `.attester`, `.custodian` supported when present; `.custodian` → `ke-kps-organization`, `.attester.party` → organization or practitioner | SHOULD (MustSupport) | `Composition.encounter`, `.attester.*`, `.custodian` |
| KPS-COMP-9 | `Composition.section` has **at least 3** entries | MUST (`min = 3`) | `Composition.section` |

**KPS-COMP-4 detail.** The constraint is `patternCodeableConcept`, and a FHIR
pattern matches *every* property it specifies, `display` included. A Composition
carrying system + code but a different display string **fails**. Verified
against the official validator: changing the display to `Patient Summary`
produces `Composition.type.coding.display … is fixed to 'Patient summary
Document'`.

**KPS-COMP-6 detail.** The profile marks `status` MustSupport but does **not**
narrow its value set. The base binding (`composition-status`: `preliminary |
final | amended | entered-in-error`) stands, so `amended` is conformant.
Verified: an otherwise-valid Composition with `status = amended` passes.

### Sections

`Composition.section` is sliced, discriminator `pattern:code`, rules `open`
(so additional sections beyond these six are permitted).

| id | slice | card | LOINC code | display in pattern | entry targetProfile |
|---|---|---|---|---|---|
| KPS-SEC-1 | `problems` | **1..1** | `11450-4` | `Problem list` | `ke-kps-condition` |
| KPS-SEC-2 | `allergies` | **1..1** | `48765-2` | `Allergies and adverse reactions` | `ke-kps-allergy-intolerance` |
| KPS-SEC-3 | `medications` | **1..1** | `10160-0` | `History of Medication use` | `ke-kps-medication-request` **or** `ke-kps-medication-statement` |
| KPS-SEC-4 | `immunizations` | 0..1 | `11369-6` | `History of immunization` | `ke-kps-immunization` |
| KPS-SEC-5 | `results` | 0..1 | `30954-2` | `Relevant diagnostic tests/laboratory data` | `ke-kps-diagnostic-report` **or** `ke-kps-observation` |
| KPS-SEC-6 | `procedures` | 0..1 | `47519-4` | `History of Procedures` | `ke-kps-procedure` |

All six slices are MustSupport. For every slice present:

| id | rule | severity | element |
|---|---|---|---|
| KPS-SEC-7 | `section.title` present | MUST (1..1) | `Composition.section:<slice>.title` |
| KPS-SEC-8 | `section.code` matches the slice's LOINC pattern, **display included** | MUST (1..1, patternCodeableConcept) | `Composition.section:<slice>.code` |
| KPS-SEC-9 | `section.entry` references resolve to the slice's target profile | MUST (targetProfile) | `Composition.section:<slice>.entry` |
| KPS-SEC-10 | a section satisfies base `cmp-1` via **any** of `text`, `entry` or `section` | MUST | base FHIR `cmp-1` |
| KPS-SEC-11 | `section.emptyReason` only when the section has no `entry` | MUST | base FHIR `cmp-2` |

**KPS-SEC-9/10 detail.** `section.entry` is **0..\*** in every slice; the IG
does **not** require entries. A required section carrying only narrative `text`
and no entries is conformant. `emptyReason` is 0..1 MustSupport, not a
substitute the IG demands.

---

## 2. `ke-kps-patient`

`https://fhir.dha.go.ke/ig/patient-summary/StructureDefinition/ke-kps-patient`

### The identifier invariant

| id | rule | severity | element |
|---|---|---|---|
| KPS-PAT-1 | **`PatientIdentification-1`**: the Patient SHALL carry at least one identifier whose `system` is `http://moh.kenya/identifier/nationalID-no` **or** `http://moh.kenya/identifier/birthCertificate-No` | MUST (error) | `Patient` root constraint |

Verbatim FHIRPath from the package:

```
identifier.where(system = 'http://moh.kenya/identifier/nationalID-no').exists()
  or identifier.where(system = 'http://moh.kenya/identifier/birthCertificate-No').exists()
```

> Note the casing: `nationalID-no` ends in lowercase `no`, `birthCertificate-No`
> ends in capital `No`. They are inconsistent with each other, and the
> invariant compares system URIs by exact string. This is not a typo we may
> normalise away; it is what the validator enforces. See deviation **X1**.

### Identifier slices

`Patient.identifier` is **1..\***, sliced on `value:system`, rules `open`.
Every slice is 0..1 and MustSupport, with `system` fixed by `patternUri` and
`value` 1..1.

| id | slice | system | card |
|---|---|---|---|
| KPS-PAT-2 | `NationalIDNo` | `http://moh.kenya/identifier/nationalID-no` | 0..1 |
| KPS-PAT-3 | `UPI` | `http://moh.kenya/identifier/UPI` | 0..1 |
| KPS-PAT-4 | `PassportNo` | `http://moh.kenya/identifier/passport-No` | 0..1 |
| KPS-PAT-5 | `BirthCertificateNo` | `http://moh.kenya/identifier/birthCertificate-No` | 0..1 |

Each has a matching NamingSystem in the package
(`NationalIdIdentifierNamingSystem`, `UpiIdentifierNamingSystem`,
`PassportIdentifierNamingSystem`, `BirthCertificateIdentifierNamingSystem`).
**The UPI is 0..1, not mandatory** — nothing in the profile requires it, and the
`PatientIdentification-1` invariant does not accept it as a substitute for the
national ID or birth certificate.

### Everything else

| id | rule | severity | element |
|---|---|---|---|
| KPS-PAT-6 | `Patient.id` and `Patient.meta` present; `meta.profile` matches the profile canonical | MUST (1..1 / patternCanonical) | `Patient.id`, `.meta`, `.meta.profile` |
| KPS-PAT-7 | `Patient.gender` present, bound **Required** to `…/ValueSet/kps-patient-gender-vs` | MUST (1..1) | `Patient.gender` |
| KPS-PAT-8 | `Patient.telecom` **1..\***, sliced on `pattern:system`, with a **`phone` slice 1..1** whose `system` is fixed to `phone` and whose `value` is 1..1 | MUST | `Patient.telecom`, `.telecom:phone.*` |
| KPS-PAT-9 | optional `email` slice 0..1, `system` fixed `email`, `value` 1..1 | MUST when present | `Patient.telecom:email.*` |
| KPS-PAT-10 | when `Patient.contact` is present, `contact.relationship` 1..1 and `contact.telecom` 1..1 | MUST | `Patient.contact.relationship`, `.contact.telecom` |
| KPS-PAT-11 | `Patient.address.line` capped at **0..1** (one line only) | MUST | `Patient.address.line` |
| KPS-PAT-12 | `contact.name.given` capped at 0..1 | MUST | `Patient.contact.name.given` |

**KPS-PAT-8 is the sharpest new rule**: a phone number is mandatory on every KPS
Patient. Registration flows that allow a patient with no phone produce
non-conformant summaries.

---

## 3. Clinical resource profiles

### `ke-kps-condition`

| id | element | card | binding |
|---|---|---|---|
| KPS-COND-1 | `Condition.id`, `.meta`, `.meta.profile` | 1..1 / 1..1 / 1..* pattern | — |
| KPS-COND-2 | `Condition.code` | **1..1** | **Required** → `…/ValueSet/condition-code-vs` |
| KPS-COND-3 | `Condition.clinicalStatus` | **1..1** | **Required** → `…/ValueSet/condition-clinical-status-vs` |
| KPS-COND-4 | `Condition.verificationStatus` | **1..1** | **Required** → `…/ValueSet/condition-verification-status-vs` |
| KPS-COND-5 | `Condition.category` | **1..1** (base is 0..*) | — |
| KPS-COND-6 | `Condition.severity` | 0..1 | **Required** → `…/ValueSet/condition-severity-vs` |
| KPS-COND-7 | `Condition.onset[x]` restricted to `dateTime \| Age`; `abatement[x]` restricted to `dateTime` | 0..1 | — |

**What `condition-code-vs` actually is.** It is a single unfiltered include of
`http://hl7.org/fhir/sid/icd-10` — the whole of ICD-10, nothing narrower.

```json
{"compose": {"include": [{"system": "http://hl7.org/fhir/sid/icd-10"}]}}
```

So **diagnoses are ICD-10, bound Required**, and the correct `coding.system` to
emit is `http://hl7.org/fhir/sid/icd-10`. ICD-11 has no place in a KPS
`Condition.code` today. ICD-10 is not shipped in the package (it is externally
licensed), so the validator reports it as unresolvable rather than checking
membership.

### `ke-kps-medication-statement`

| id | element | card | binding |
|---|---|---|---|
| KPS-MEDSTMT-1 | `MedicationStatement.id`, `.meta`, `.meta.profile` | 1..1 / 1..1 / 1..* pattern | — |
| KPS-MEDSTMT-2 | `MedicationStatement.medication[x]` | 1..1 (base) | **Required** → `…/ValueSet/kps-medication-vs` |
| KPS-MEDSTMT-3 | `MedicationStatement.effective[x]` | **1..1** (base is 0..1) | — |
| KPS-MEDSTMT-4 | `.status`, `.subject` (→ `ke-kps-patient`), `.dosage` | MustSupport | — |

### `ke-kps-medication-request`

| id | element | card | binding |
|---|---|---|---|
| KPS-MEDREQ-1 | `MedicationRequest.id`, `.meta`, `.meta.profile` | 1..1 / 1..1 / 1..* pattern | — |
| KPS-MEDREQ-2 | `MedicationRequest.status` | 1..1 (base) | **Required** → `http://hl7.org/fhir/ValueSet/medicationrequest-status` (base VS, not Kenyan) |
| KPS-MEDREQ-3 | `MedicationRequest.category` | 0..* | **Required** → `…/ValueSet/medication-request-category-vs` |

> `ke-kps-medication-request` does **not** bind `medication[x]` at all. The
> medication vocabulary is enforced on `MedicationStatement.medication[x]` and
> on `Medication.code`, so a MedicationRequest should carry a
> `medicationReference` to a `ke-kps-medication`, which is where the binding
> bites.

### `ke-kps-medication`

| id | element | card | binding |
|---|---|---|---|
| KPS-MED-1 | `Medication.code` | **1..1** | **Required** → `…/ValueSet/kps-medication-vs` |
| KPS-MED-2 | `Medication.status` | **1..1** | — |
| KPS-MED-3 | `Medication.form` | 0..1 | **Required** → `…/ValueSet/medication-form-vs` — **which is empty**, see defect D5 |
| KPS-MED-4 | `Medication.ingredient.strength.numerator.unit` / `.denominator.unit` | 0..1 | **Required** → `…/ValueSet/ucum-units-vs` |
| KPS-MED-5 | `Medication.batch.lotNumber` | **1..1** when `batch` present | — |
| KPS-MED-6 | optional `brandName` extension slice 0..1 | — | `…/StructureDefinition/medication-brand-name` |

**What `kps-medication-vs` actually is.** A single unfiltered include of
`kps-medication-atc-cs` — a **Kenya-hosted ATC classification**, *not* the WHO
ATC canonical `http://www.whocc.no/atc`:

```json
{"compose": {"include": [{"system": ".../CodeSystem/kps-medication-atc-cs"}]}}
```

The concepts are ATC codes (`A01AA01` = sodium fluoride), so the *content* is
WHO ATC, but the `coding.system` we must emit is the Kenyan canonical. See
defects **D1** (which base) and **D2** (truncation).

### `ke-kps-allergy-intolerance`

| id | element | card | binding |
|---|---|---|---|
| KPS-ALG-1 | `AllergyIntolerance.type` | **1..1** | **Required** → `…/ValueSet/kps-allergy-type-vs` |
| KPS-ALG-2 | `AllergyIntolerance.verificationStatus` | **1..1** | **Required** → `…/ValueSet/allergy-intolerance-verification-status-vs` |
| KPS-ALG-3 | `AllergyIntolerance.reaction` | **1..\*** | — |
| KPS-ALG-4 | `AllergyIntolerance.code` | 0..1 | **Required** → `…/ValueSet/allergy-intolerance-code-vs` |
| KPS-ALG-5 | `AllergyIntolerance.reaction.substance` | 0..1 | **Required** → `…/ValueSet/allergy-intolerance-code-vs` (same VS as `.code`) |
| KPS-ALG-6 | `AllergyIntolerance.reaction.manifestation` | 1..* (base) | **Required** → `…/ValueSet/allergy-intolerance-reaction-manifestation-vs` |
| KPS-ALG-7 | `AllergyIntolerance.reaction.severity` | 0..1 | **Required** → `…/ValueSet/kps-allergy-severity-vs` |
| KPS-ALG-8 | `AllergyIntolerance.clinicalStatus` | 0..1 | **Required** → `…/ValueSet/kps-allergy-status-vs` |

Allergen vocabulary resolves to `kps-substances-cs` (500 concepts) and
manifestations to `manifestation-cs`. **Neither is SNOMED CT.**

### `ke-kps-immunization`

| id | element | card | binding |
|---|---|---|---|
| KPS-IMM-1 | `Immunization.vaccineCode` | 1..1 (base) | **Required** → `…/ValueSet/immunization-vaccine-code-vs` → `kps-vaccine-atc-cs` (132 concepts, ATC `J07…`) |
| KPS-IMM-2 | `Immunization.protocolApplied.targetDisease` | **1..1** (base is 0..*) | **Required** → `…/ValueSet/immunization-target-disease-vs` → `kps-target-diseases-cs` |
| KPS-IMM-3 | `Immunization.protocolApplied.series` | **1..1** | — |
| KPS-IMM-4 | `Immunization.status` | 1..1 (base) | **Required** → `…/ValueSet/immunization-status-vs` |
| KPS-IMM-5 | `Immunization.occurrence[x]` restricted to `dateTime`; `doseNumber[x]` to `positiveInt` | — | — |

**`targetDisease` is not bound to `http://hl7.org/fhir/sid/icd-10`.** It binds
to the Kenya-hosted `kps-target-diseases-cs`, whose *concepts* are ICD-10
(`A37` = Whooping cough) but whose `system` URI is the Kenyan canonical. A
Kenyan-conformant Immunization therefore codes the same disease with a
different `system` than a Kenyan-conformant Condition does. That asymmetry is
real and must be honoured, not smoothed over.

---

## 4. Terminology facts

### Bindings that constrain our data model

| element | strength | ValueSet | resolves to | concepts |
|---|---|---|---|---|
| `Condition.code` | Required | `condition-code-vs` | `http://hl7.org/fhir/sid/icd-10` | external |
| `MedicationStatement.medication[x]`, `Medication.code` | Required | `kps-medication-vs` | `kps-medication-atc-cs` | 1000 (truncated) |
| `AllergyIntolerance.code`, `.reaction.substance` | Required | `allergy-intolerance-code-vs` | `kps-substances-cs` | 500 |
| `AllergyIntolerance.reaction.manifestation` | Required | `allergy-intolerance-reaction-manifestation-vs` | `manifestation-cs` | 30 |
| `Immunization.vaccineCode` | Required | `immunization-vaccine-code-vs` | `kps-vaccine-atc-cs` | 132 |
| `Immunization.protocolApplied.targetDisease` | Required | `immunization-target-disease-vs` | `kps-target-diseases-cs` | 1000 (truncated) |
| `Procedure.code` | Required | `procedure-code-vs` | `kps-procedures-cs` | 975 |
| `DiagnosticReport.code` | Required | `kps-investigations-vs` | `ksp-investigation-cs` | 2183 |
| `Condition.severity` | Required | `condition-severity-vs` | `condition-severity-cs` | 4 |
| `Patient.gender` | Required | `kps-patient-gender-vs` | `administrative-gender` | 4 |
| `MedicationRequest.status` | Required | base `medicationrequest-status` | HL7 | — |
| `Condition.clinicalStatus` / `.verificationStatus` | Required | KPS VS wrapping HL7 `condition-clinical` / `condition-ver-status` | HL7 | — |

The correct CodeSystem base for every Kenyan system above is
**`https://fhir.dha.go.ke/ig/patient-summary/CodeSystem/`**.

### Notifiable diseases

**There is no notifiable-disease ValueSet in any of the four packages.** Nothing
matching `notifiable`, `surveillance`, `reportable`, `IDSR`, `epidemic` or
`outbreak` exists as a ValueSet or CodeSystem across all 359 ValueSets and 441
CodeSystems vendored. Any reportability flagging we do is **ours**, derived from
Kenya's IDSR lists outside the IGs, and must be labelled as such — it cannot
claim IG backing.

---

## 5. Upstream defects

These are bugs in the packages, confirmed against the official validator. They
change what we must emit; they are not ours to silently correct.

### D1 — the KPS CodeSystem canonical base is split, and the wrong half is the one used

All **131** KPS CodeSystems are published under
`https://fhir.dha.go.ke/ig/patient-summary/CodeSystem/…`.

But:

* **14 of 39** Kenyan ValueSet includes reference
  `https://fhir.dha.go.ke/fhir/CodeSystem/…` — a base published nowhere. Those
  Required bindings can never be satisfied.
* **All 19** Kenyan codings across **16 of 32** example instances use the
  unpublished `/fhir/CodeSystem/` base. Not one example uses the base its own
  package publishes.

Consequence, straight from the validator: eight `A definition for CodeSystem
'https://fhir.dha.go.ke/fhir/CodeSystem/…' could not be found` warnings on the
IG's own content, and one hard error where the ValueSet happens to be correct
and the example is not (see D3).

**What we do**: emit `https://fhir.dha.go.ke/ig/patient-summary/CodeSystem/…`,
the published base. Do not copy the IG's examples. Report upstream.

**D1a: for those 14 ValueSets there is no conformant option, and the
published base is the worse one.** Confirmed against the official validator on
our own export. `Observation.category` binds Required to
`observation-category-vs`, whose only include is
`https://fhir.dha.go.ke/fhir/CodeSystem/observation-category-cs`, and which
carries no expansion. Emitting the *published* base gives a hard error:

```
error [Observation.category[0]] None of the codings provided are in the value set
'Category ValueSet' (.../ValueSet/observation-category-vs|0.1.0), and a coding from
this value set is required) (codes =
https://fhir.dha.go.ke/ig/patient-summary/CodeSystem/observation-category-cs#laboratory)
```

Emitting the *unpublished* base the ValueSet actually names downgrades it to the
familiar D1 warning:

```
warning [Observation.category[0].coding[0].system] A definition for CodeSystem
'https://fhir.dha.go.ke/fhir/CodeSystem/observation-category-cs' could not be
found, so the code cannot be validated
```

So the guidance splits. **Emit the published `/ig/patient-summary/` base
everywhere except where the binding's own ValueSet includes the `/fhir/` base**
(those 14, listed above), **where the ValueSet's base must be matched or the
instance hard-fails.** This is following a bug to stay valid, and it reverses
the moment upstream fixes the includes, so every such emission must be tagged in
code with a pointer to D1a.

The 14: `allergy-intolerance-code-vs`,
`allergy-intolerance-reaction-manifestation-vs`, `condition-severity-vs`,
`immunization-target-disease-vs`, `immunization-vaccine-code-vs`,
`kps-acquisition-modality-vs`, `kps-communication-preference-vs`,
`kps-generic-products-vs`, `kps-medication-vs`, `kps-referral-direction-vs`,
`kps-referral-reason-vs`, `kps-referral-source-vs`, `observation-category-vs`,
`procedure-code-vs`.

### D2 — `content: complete` code systems are truncated at exactly 1000 concepts

`kps-medication-atc-cs`, `kps-target-diseases-cs`, `investigations-cs` and
`ClaimDiagnosisCodeableConceptCS` each declare `"content": "complete"` and
`"count": 1000`, and each stops at exactly 1000 concepts:

* `kps-medication-atc-cs` ends at `B02BX01` (etamsylate). ATC runs A–V; roughly
  the last three-quarters of the classification is missing.
* `kps-target-diseases-cs` ends inside ICD-10 chapter I.

Measured on real Kenyan clinical data: `kps-substances-cs` (500 concepts,
`content: complete`) is a numerically-sorted SNOMED substance list that stops at
`4728000`, so it contains `Hemoglobin Okaloosa` and `Scopulariopsis proteinase`
but **not penicillin**. `kps-medication-atc-cs` stops at `B02BX01`, so
artemether-lumefantrine (`P01BF01`), paracetamol (`N02BE01`) and amoxicillin
(`J01CA04`) are all absent. The two Required bindings that matter most for a
Kenyan patient summary (the allergen and the medication) cannot be satisfied
for the commonest real values.

`complete` is a claim the validator relies on to *reject* codes outside the
list. Under a Required binding, a legitimate Kenyan medication coded `N02BE01`
(paracetamol) would be rejected as not in the value set. Treat these as
`fragment`, never as an authority for rejection.

### D3 — the IG's own `DiagnosticReportKPS` example does not validate

`DiagnosticReport-DiagnosticReportKPS.json` codes
`ksp-investigation-cs#718-7` under the D1 wrong base, while
`kps-investigations-vs` correctly includes the published base. Result:

```
error [DiagnosticReport.code] None of the codings provided are in the value set
'KPS Investigations' (…/ValueSet/kps-investigations-vs|0.1.0), and a coding from
this value set is required (codes = https://fhir.dha.go.ke/fhir/CodeSystem/ksp-investigation-cs#718-7)
```

The code `718-7` **is** present in the 2183-concept CodeSystem. Only the
`system` URI is wrong. This is D1 producing a hard failure rather than a warning.

### D4 — `http://localhost:8085/…` placeholders persist in the Emergency IG

16 ValueSets in `fhir.kenyaEmergencyIG@0.1.0` include from
`http://localhost:8085/fhir/CodeSystem/…`, including
`vital-signs-loinc-cs`, `investigations-cs` and `manifestation-cs`. Each has a
correctly published twin at `https://nshr-uat.sha.go.ke/fhir/CodeSystem/…`. The
`removedUnusedProfiles` branch has **not** fixed this; the defect noted in
earlier platform docs is still live.

### D5 — 146 of the KPS IG's 248 ValueSets are empty, and one of them is bound Required

146 KPS ValueSets carry **neither `compose` nor `expansion`** — they are
metadata shells with a title and a copyright notice and no content. Most are
unused scaffolding, but four bindings point at one, and one of those four is on
a real profile rather than a logical model:

| profile | element | strength | empty ValueSet |
|---|---|---|---|
| `ke-kps-medication` | `Medication.form` | **Required** | `medication-form-vs` |
| `ClientTreatmentModel` (logical) | `.medicationForm` | Required | `medication-form-vs` |
| `ClinicalConsultationModel` (logical) | `.allergy.allergen` | Required | `allergy-intolerance-reaction-substance-vs` |
| `DiagnosticsModel` (logical) | `.status` | Required | `diagnostic-report-status-vs` |

Verified behaviour: a `ke-kps-medication` with
`form = http://snomed.info/sct#385055001` **passes** today, because a ValueSet
that expands to nothing gives the validator no basis to reject. So the Required
binding currently protects nothing — and will turn into a hard failure the
moment upstream populates the ValueSet with something we do not emit. Do not
build on `Medication.form` conformance either way.

Separately, a near-twin ValueSet `kps-medication-form-vs` (note the `kps-`
prefix) *does* have content: a single include of the literal placeholder
`http://example.org/fhir/CodeSystem/medication-form`. Nothing binds to it.

### D6 — cross-IG canonical drift

`kps-referral-codes` is referenced by KPS at
`https://fhir.dha.go.ke/fhir/CodeSystem/kpsg-referral-codes` but is only
published by the **Emergency** IG at
`https://nshr-uat.sha.go.ke/fhir/CodeSystem/kpsg-referral-codes`. Loading all
four packages together is therefore required, and still insufficient.

---

## 6. Deviations found in our current implementation

Measured against `taifa-interop/internal/kps/validate.go` as it stands. The
package is deliberately not edited here; this is the spec it must satisfy.

### X1 — `birthCertificate` system URI casing is wrong (correctness bug)

```go
birthCertificateSystem = "http://moh.kenya/identifier/birthCertificate-no"
```

The IG's `PatientIdentification-1` invariant and the `BirthCertificateNo` slice
both use **`birthCertificate-No`** (capital `N`). System URIs compare exactly.

**Effect**: a conformant patient identified only by birth certificate — a child
with no national ID, the exact case the invariant exists to permit — is
**rejected** by our validator and **accepted** by the official one. Correct
value: `http://moh.kenya/identifier/birthCertificate-No`. Rule KPS-PAT-1.

### X2 — the Medications section rejects `MedicationRequest` (correctness bug)

```go
{name: "Medications", loincCode: "10160-0", resourceType: "MedicationStatement"},
```

`Composition.section:medications.entry` targets **both**
`ke-kps-medication-request` and `ke-kps-medication-statement`. A conformant
summary of prescribed-but-not-yet-taken medication is rejected. Rule KPS-SEC-3.

### X3 — `Composition.status` must be `final` (over-strict)

```go
if status, ok := getString(composition, "status"); !ok || status != "final" {
```

The profile does not constrain `status`; base `composition-status` applies.
Verified: `status = amended` passes the official validator and fails ours.
Rule KPS-COMP-6.

### X4 — sections require `entry` or `emptyReason` (over-strict)

`section.entry` is 0..* and `emptyReason` 0..1. Base `cmp-1` is satisfied by
`text` alone. A narrative-only Problems section is conformant and we reject it.
Rules KPS-SEC-9, KPS-SEC-10.

### X5 — `meta.profile` is never checked (missing rule, high impact)

Every KPS profile sets `meta` 1..1 and `meta.profile` 1..* with a
`patternCanonical`. We check neither. This matters beyond conformance:
**without `meta.profile` the official validator does not apply the Kenyan
profile at all**, so a bundle that passes our validator can sail through the
official one having been checked against nothing. Rules KPS-COMP-2/3, KPS-PAT-6,
and the `.meta`/`.meta.profile` rows of every clinical profile.

### X6 — pattern `display` values are not checked (missing rule)

`Composition.type` and all six `section.code` patterns pin `display` as well as
`system` and `code`. `hasLOINCCoding` compares system and code only. Verified: a
mismatched display is a hard error against the official validator. Rules
KPS-COMP-4, KPS-SEC-8.

### X7 — required elements on clinical resources are not checked (missing rules)

We check only `Condition.code`'s system. Unchecked and required:
`Condition.clinicalStatus`, `.verificationStatus`, `.category` (1..1);
`MedicationStatement.effective[x]` (1..1);
`AllergyIntolerance.type`, `.verificationStatus`, `.reaction` (1..*);
`Immunization.protocolApplied.series` and `.targetDisease` (1..1);
`Medication.code`, `.status`, `.batch.lotNumber`. Rules KPS-COND-*, KPS-MEDSTMT-*,
KPS-ALG-*, KPS-IMM-*, KPS-MED-*.

### X8 — `Patient.telecom` phone is not checked (missing rule)

`Patient.telecom` is 1..* with a mandatory `phone` slice (1..1, `system` fixed,
`value` 1..1). We check neither telecom nor `contact.relationship` /
`contact.telecom` (1..1 each when `contact` is present). Rules KPS-PAT-8,
KPS-PAT-10.

### X9 — `Patient.gender` presence only, no value set (partial rule)

`gender` binds **Required** to `kps-patient-gender-vs`. We check presence only.
Rule KPS-PAT-7.

### X10 — the doc comment's binding table is contradicted by the packages

`validate.go`'s header points at `IG_CONFORMANCE.md`, whose binding table said
`Immunization.targetDisease` binds to ICD-10 and allergy/manifestation bind to
SNOMED CT. Neither is true: those bind to Kenya-hosted `kps-target-diseases-cs`
and `kps-substances-cs`/`manifestation-cs`. Corrected in section 3.

### Not a deviation

`Condition.code` requiring `http://hl7.org/fhir/sid/icd-10` is **correct** —
`condition-code-vs` is an unfiltered include of exactly that system. Our
`icd10System` constant is right. The document-Bundle rules (KPS-DOC-*) are ours
by necessity, since the IG defines no Bundle; keep them labelled as ours.
