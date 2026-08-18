# Data Protection and Compliance

Read this before writing code that reads or writes a patient record. This is a
working summary for engineers, not legal advice, and it does not replace the
data protection officer or counsel.

## The law we build against

| Instrument | What it means for the code |
|---|---|
| **Data Protection Act 2019 (Kenya)** | Health data is sensitive personal data. Processing needs a lawful basis, purpose limitation, data minimisation, and defined retention. Data subjects have rights of access, rectification, erasure where applicable, and objection. The controller registers with the ODPC |
| **Health Act 2017** | Patient information is confidential. Disclosure needs consent or a specific legal ground. Records must be kept and protected |
| **Digital Health Act 2023** | Governs digital health services, health data exchange, and data governance, and establishes the national digital health authority. Expect registration, standards conformance, and exchange obligations |
| **ODPC guidance** | Breach notification within 72 hours of becoming aware, and data protection impact assessments for high-risk processing |
| **HIPAA** | Not Kenyan law and not our compliance target, but partners and funders often ask. Our controls are designed to map onto it cleanly |

Data residency: patient data stays in Kenya. Any processor outside Kenya needs
an explicit transfer assessment before a single record moves, including
analytics, error tracking, and AI services. This is why crash reporters and
third-party telemetry are not added casually.

## The engineer's rules

1. **Minimise.** Do not collect a field because it might be useful. Every field
   holding personal data needs a purpose you can state in one sentence.
2. **Scope every query.** Patient data is always filtered by facility and by
   the caller's role. A missing filter is a data breach, not a bug.
3. **Audit every access.** Reads as well as writes. If it is not in the audit
   trail, we cannot prove it did not happen improperly.
4. **Never log personal data.** No names, national IDs, phone numbers, or
   diagnoses in application logs, error messages, stack traces, analytics,
   crash reports, or metrics labels. Log the record identifier.
5. **Encrypt.** TLS in transit, encryption at rest for the database and
   backups. Backups are as sensitive as the live database and are tested by
   restoring them.
6. **Synthetic data only outside production.** Never copy a production database
   into staging or a laptop, even anonymised, without a documented approval.
   Re-identification of health data is easier than people assume.
7. **Delete on schedule.** Retention is defined per data category and enforced
   by a job, not by intention. Clinical records have long statutory retention,
   but session logs, exports, and support attachments do not.
8. **Consent is data.** Where consent is the basis (patient portal sharing,
   research, cross-facility access), it is recorded with who, what, when, and
   scope, and it is revocable.

## Break-glass access

Emergency care is never blocked by access control. A clinician can override
into a record they would not normally see, with a reason, and every such access
is flagged, reported, and reviewed by the facility. Design for accountability
after the fact rather than refusal at the moment of need.

## When a change needs more than code review

| Trigger | Required |
|---|---|
| New category of personal data collected | Data protection officer sign-off, retention defined |
| New processor or third-party service touching patient data | Transfer assessment, contract, DPO approval |
| Automated decision-making or risk scoring on patients | Data protection impact assessment, clinical safety review |
| Large-scale export, research dataset, or analytics | DPIA, anonymisation review, approval before any extract runs |
| Change to audit, consent, or access control | DPO plus platform lead |

## If something goes wrong

Suspected exposure of patient data is a personal data breach. Report it
immediately through [../SECURITY.md](../SECURITY.md), marked **BREACH**. Do not
delete evidence, do not investigate quietly to see whether it was real first,
and do not notify patients yourself. The 72-hour clock to notify the ODPC
starts when we become aware, and "aware" means when you noticed, not when the
report reached a manager.

Reporting a breach you caused is the right move and is treated as such.
