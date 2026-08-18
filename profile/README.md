<h1 align="center">Taifa Health</h1>

<p align="center">
  <strong>Hospital software for Kenya.</strong><br>
  The record, the ward, the pharmacy, the lab, and the claim, on one platform.
</p>

<p align="center">
  <a href="https://github.com/TaifaHealth/.github/blob/main/docs/ARCHITECTURE.md">Architecture</a> ·
  <a href="https://github.com/TaifaHealth/.github/blob/main/docs/STANDARDS.md">Standards</a> ·
  <a href="https://github.com/TaifaHealth/.github/blob/main/docs/COMPLIANCE.md">Compliance</a> ·
  <a href="https://github.com/TaifaHealth/.github/blob/main/SECURITY.md">Security</a>
</p>

---

Most Kenyan facilities run on a patchwork: a registration book, a standalone
pharmacy till, a lab that phones results across the corridor, and a claims
clerk retyping everything at month end. Taifa Health replaces the patchwork
with one platform that a district hospital can actually afford to run and a
county can operate across every facility it owns.

### What we build

- **Taifa EMR**, the clinical record: registration, encounters, notes, orders,
  results, prescriptions, referrals, discharge.
- **Taifa HMIS**, hospital operations: queues, admissions and transfers, beds
  and wards, theatre lists, rosters, facility reporting.
- **Pharmacy, Laboratory and Radiology**, connected to the record rather than
  bolted beside it.
- **Revenue**, from cash and corporate billing through to SHA claims and
  M-Pesa reconciliation.
- **Interoperability**, an HL7 FHIR R4 surface with HL7 v2 interfaces, DHIS2
  and KHIS reporting, and KMHFL facility identity.

### How we build it

| | |
|---|---|
| **Interoperable by default** | FHIR R4 for clinical data leaving the platform, HL7 v2 where the equipment demands it, DICOM for imaging, ICD-11, SNOMED CT and LOINC for coding. |
| **Safe by design** | Changes that can affect patient care go through a clinical safety review and a hazard log, not just code review. |
| **Kenyan by construction** | SHA claims, M-Pesa, KMHFL codes, Kenya Essential Medicines List, and the Data Protection Act 2019 are requirements, not a localisation layer added later. |
| **Runs where the power does not** | Facilities lose connectivity and mains power. The clinical record has to keep working, then reconcile. |

### Working with us

Reports of security issues go to the process in
[SECURITY.md](https://github.com/TaifaHealth/.github/blob/main/SECURITY.md),
never to a public issue. Everything else starts with
[CONTRIBUTING.md](https://github.com/TaifaHealth/.github/blob/main/CONTRIBUTING.md).

**Never post patient data in an issue, a pull request, a log excerpt, or a
screenshot.** Not a name, not a national ID, not a hospital number, not a date
of birth.

<p align="center"><sub>Taifa Health is a product of RCFI, built in Nairobi.</sub></p>
