# Security Policy

Taifa Health processes patient health records, which are sensitive personal
data under the Kenya Data Protection Act 2019 and confidential under the Health
Act 2017. We treat security reports accordingly.

## Reporting a vulnerability

**Do not open a public issue.**

Report privately, whichever is faster for you:

- GitHub private vulnerability reporting: the **Security** tab of the affected
  repository, then **Report a vulnerability**.
- Email: `security@taifahealth.co.ke`

Include what you need to make the report actionable: affected repository and
version or commit, a description of the issue, reproduction steps, and the
impact you believe it has. **Redact any real patient data from your report.**
If a proof of concept required real data, say so and describe it, do not attach
it.

## What to expect

| Stage | Target |
|---|---|
| Acknowledgement | 2 working days |
| Initial assessment and severity | 5 working days |
| Fix or mitigation for critical issues | 7 days |
| Fix for high issues | 30 days |
| Public disclosure | Coordinated with you, after affected facilities are patched |

We will keep you updated, credit you if you want credit, and tell you when the
fix ships.

## Scope

In scope: any repository in the `TaifaHealth` organisation, and the hosted
platform.

Particularly interested in: authentication and session handling, access control
between facilities (a user of one facility reaching another facility's data),
audit trail tampering, injection, insecure direct object references on patient
records, and anything that leaks patient data into logs, exports, or error
messages.

Out of scope: denial of service testing against production, social engineering
of staff or clinicians, physical attacks, and reports from automated scanners
without a demonstrated impact.

## Never test against real data

Do not test against a live facility deployment. If you need an environment, ask
and we will provision a staging instance with synthetic data.

## If patient data has been exposed

Exposure of patient data is a personal data breach. Report it the same way,
immediately, and mark it **BREACH** in the subject. Kenyan law requires the
data controller to notify the Office of the Data Protection Commissioner within
72 hours of becoming aware, so the clock starts when you tell us. Do not delete
evidence, and do not attempt to notify affected patients yourself.
