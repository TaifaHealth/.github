# Defect report: Kenya Patient Summary and Kenya eClaims IGs

To: IntelliSOFT Consulting, Digital Health Agency (Kenya)
From: TaifaHealth (RCFI)
Date: 2026-08-19
Packages: `ke.fhir.patient-summary` 0.1.0 (branch `compositionResource`),
`ke.fhir.eclaims` 0.1.0 (branch `canonicalUpdate`), `kenya.fhir.core`
1.0.0 (branch `profileValidation`), Kenya Emergency Care IG (branch
`removedUnusedProfiles`). All four vendored and pinned by sha256; pins
in `ig/PINS.md`.

We are implementing an EMR that produces Kenya Patient Summary
documents. We validate every export with the official HL7
`validator_cli.jar` against these four packages. The issues below are
the ones we cannot resolve on our side, in the order they cost us.

## D1: the canonical base is split, and the published half is the one
nothing binds through

`CodeSystem-kps-vaccine-atc-cs.json` declares

    "url": "https://fhir.dha.go.ke/ig/patient-summary/CodeSystem/kps-vaccine-atc-cs"

while `ValueSet-immunization-vaccine-code-vs.json` includes from

    "system": "https://fhir.dha.go.ke/fhir/CodeSystem/kps-vaccine-atc-cs"

The two never meet. A code emitted under the published URL is reported
by the validator as not being in the ValueSet that binds it; a code
emitted under the referenced URL validates but points at a base the IG
publishes nowhere. The same split affects at least 14 ValueSets,
including `observation-category-vs`, and the IG's own examples use the
unpublished base.

We emit the referenced base, because conforming to a URL that every
binding rejects helps nobody, but it means our documents carry a
canonical that cannot be dereferenced.

**Ask:** reconcile the two, in whichever direction you intend, and
republish. One base is enough.

## D2: code systems declared complete are truncated

- `kps-substances-cs` declares `content: complete` and does not
  contain penicillin. `AllergyIntolerance.code` binds Required to
  `allergy-intolerance-code-vs`, which draws from it, so a penicillin
  allergy, one of the commonest and most consequential in Kenyan
  practice, cannot be coded conformantly.
- `kps-medication-atc-cs` stops at `B02BX01`. Artemether-lumefantrine,
  amoxicillin and paracetamol are all absent, so
  `MedicationStatement.medication[x]`, also bound Required, cannot be
  coded for the medicines a Kenyan facility dispenses most.
- `kps-target-diseases-cs` is truncated at 1000 concepts (A00 to
  C09.8). ICD-10 chapters G, Q and Z have no concepts at all, and
  vitamin A deficiency (E50) is unreachable.

We will not invent national codes to satisfy a Required binding: an
invented code that looks official is worse for the receiving system
than an honest text-only concept.

**Ask:** publish the complete content, or relax the bindings to
extensible while the content is being completed.

## D3: no notifiable disease value set

Kenya's IDSR notifiable diseases have no ValueSet in any of the four
packages, so every implementer maintains their own list and they will
not agree. Ours is prefix-derived over 21 ICD-10 codes and is marked in
our own data as not IG-sourced.

**Ask:** publish the IDSR notifiable list as a ValueSet. It is the kind
of content that must not be reinvented facility by facility.

## Smaller observations

- `Composition.section` code patterns pin `display` as well as system
  and code, so an implementer using the LOINC long name gets a hard
  error with no hint that the short form is required. Worth a note in
  the guide.
- `Patient.telecom` carries a mandatory phone slice. That is a
  defensible rule, but it means an unidentified or unaccompanied
  patient cannot have a conformant summary; a stated exception would
  help emergency and outreach settings.
- `A39.0` in `kps-target-diseases-cs` has the display
  `"Meningococcal meningitis[G01]"`, which appears to be an export
  artifact rather than intended text.

## D4: the investigation code system is published as `ksp`, not `kps`

`CodeSystem-ksp-investigation-cs.json` declares

    "url": "https://fhir.dha.go.ke/ig/patient-summary/CodeSystem/ksp-investigation-cs"

with the acronym transposed. `ValueSet-kps-investigations-vs` includes
from the same transposed URL, so the two agree and nothing fails
validation today. It is consistent, which is precisely why it is worth
raising now: every implementer who codes an investigation is writing
`ksp` into stored clinical data, and correcting the canonical later
silently invalidates all of it.

Unlike D1 this one is on the published base and resolves. The only
question is whether the spelling is intended.

**Ask:** if it is a typo, correct it before adoption spreads, and say
so loudly, because the fix is not backward compatible for anyone who
already stored the old canonical.

## What is right, and worth saying

Not everything we checked is a defect, and two of these mattered to us:

- `kps-acquisition-modality-cs` declares `content: complete`, declares
  51 concepts and contains exactly 51. `ksp-investigation-cs` declares
  2183 and contains 2183. Both are whole, both are on the published
  base, and both are directly usable. Imaging and investigations can be
  coded conformantly today, which is not true of substances and
  medications (D2).
- `kps-diagnostic-service-sections-vs` binds to HL7 `v2-0074` rather
  than a republished Kenyan copy. Reusing the international code system
  where Kenya has no reason to differ is the right call and saves
  everyone a mapping.

## What we did on our side

Vendored and pinned all four packages, extracted every binding and
cardinality into a testable rule list, wired the official validator
into CI, and fixed ten deviations of our own that this exercise
surfaced, including two that wrongly rejected conformant patients. Our export is down from 16 errors to 6, and every one that remains
traces to D2 above. Nothing outstanding is ours.

We would be glad to contribute the extraction tooling or test bundles
if they are useful to you.
