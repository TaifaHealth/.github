# Roadmap

Direction, not dates. Each phase ends with something a real facility can use,
because a hospital system that is only useful when it is complete never becomes
useful.

## Phase 1: the record

The minimum that replaces the registration book and the paper file.

- Patient registration, master patient index, deduplication
- Facility and user management, roles, first-party authentication, audit trail
- Outpatient encounter: triage, vitals, consultation notes, diagnosis (ICD-11)
- Prescribing, and dispensing against the prescription
- Lab and radiology ordering, results back onto the encounter
- Cash billing, invoicing, receipting, M-Pesa
- The deployment story: `docker compose` on a facility server, encrypted
  backups, restore tested

Exit criterion: one facility runs its outpatient department on it for a month
without paper.

## Phase 2: the hospital

- Admissions, discharge, transfer, bed and ward management
- Theatre lists and perioperative records
- Inpatient prescribing, drug administration records, ward stock
- Pharmacy stock, batches, expiry, procurement
- Laboratory information system with analyzer interfacing
- Radiology worklists and PACS integration
- Facility reporting derived from the record, submitted to KHIS

Exit criterion: a district hospital runs inpatient care on it.

## Phase 3: the network

- SHA eligibility, preauthorisation, claims submission and reconciliation
- Insurance and corporate billing, contract pricing
- Multi-facility deployments with the record following the patient, and the
  cross-facility consent flow behind it
- FHIR R4 API opened to partners, HL7 v2 interfaces for legacy systems
- Patient portal: appointments, results, visit history, consent management
- National registries: client and provider identity, KMHFL alignment

Exit criterion: a county runs several facilities on one deployment and claims
are reconciled without a spreadsheet.

## Phase 4: depth

- Clinical decision support: interaction and dose checking, guideline prompts,
  critical result escalation, each one hazard-assessed before it ships
- Specialty modules driven by demand: maternity, paediatrics, oncology, renal
- Offline-first clinical client, hardened for genuinely bad connectivity
- Analytics for facility and county management, and a research export path with
  the anonymisation and approvals that requires
- Mobile clinical access

## Deliberately not doing

- Chasing every certification before the software is good. Compliance is built
  in from the start, but a certificate is not a product.
- A plugin marketplace. It multiplies the safety and data protection surface
  for a benefit nobody has asked for yet.
- Autonomous clinical AI. Anything that influences a clinical decision goes
  through clinical safety review, is explainable, and keeps a human accountable
  for the decision.
