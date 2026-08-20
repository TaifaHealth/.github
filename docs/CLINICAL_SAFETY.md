# Clinical Safety

Software that shows a clinician the wrong allergy, loses an order, or attaches
a result to the wrong patient can kill someone. That is the whole reason this
document exists.

## The principle

A defect in an EMR is not just a bug, it is a **hazard**: a condition that
could contribute to patient harm. We manage hazards explicitly and in writing,
in the same way an aviation or medical device team does. The reference model is
the clinical risk management standard used for health IT (the DCB0129 and
DCB0160 family), adapted to our size.

## Roles

- **Clinical safety officer.** A clinically qualified person, named in
  [../GOVERNANCE.md](../GOVERNANCE.md). Owns the hazard log, reviews changes
  with clinical impact, and can block a release. This veto is not overridable
  by engineering or by a deadline.
- **Engineers.** Identify hazards in what they build, declare clinical impact
  in the pull request, and never work around a safety block.
- **Facilities.** Report incidents and near misses through support, which feed
  the same hazard log.

## The hazard log

The log is [`HAZARD_LOG.md`](HAZARD_LOG.md).

Every hazard gets an entry: identifier, description, the chain from software
behaviour to potential harm, severity, likelihood, existing controls, planned
mitigation, residual risk after mitigation, and who accepted that residual
risk. Entries are closed, never deleted. The log is reviewed at every release
and audited when a facility asks.

Accepting residual risk is a named person's decision. TaifaHealth has not
appointed a clinical safety officer, so every entry in the log currently reads
"not accepted", and HAZ-003 in particular should block any multi-facility
deployment until it does.

Risk is severity times likelihood, using the categories in the clinical safety
issue template. A catastrophic hazard with any likelihood above negligible
blocks the release.

## What counts as clinical impact

If your change touches any of these, declare it:

- Medication: dosing, frequency, route, interactions, contraindications,
  dispensing, controlled drugs
- Allergies, alerts, and warnings, including whether they are shown at the
  right moment
- Patient identity: registration, matching, merging, the master patient index.
  Merging two people, or splitting one, is the highest-consequence operation in
  the platform
- Results: values, units, reference ranges, critical result flagging, who is
  notified and when
- Orders: creation, routing, cancellation, and anything that could cause an
  order to be silently lost
- Triage, scoring, or any calculation a clinician acts on
- Anything that changes what is displayed on a clinical screen, including
  layout changes that move a safety-relevant field
- Availability: an outage in a ward is a clinical event, not only an
  operational one

Units, rounding, and time zones deserve specific paranoia. Most published
health IT harm comes from mundane things: a decimal point, a truncated field, a
stale cache, a date rendered in the wrong zone.

## Process

1. **Design.** For a feature with clinical impact, list the hazards before
   writing code. Ask "how could this contribute to harm" and write down the
   answers.
2. **Build.** Mitigate in the software where possible. A training note or a
   manual double check is the weakest control and is never the only one for a
   major hazard.
3. **Review.** Pull request declares clinical impact and names the hazards. The
   clinical safety officer reviews. Approval is recorded.
4. **Release.** Release notes state the safety position and any residual risk.
   Facilities are told what changed on clinical screens.
5. **Live.** Incidents and near misses come back in through support and the
   clinical safety template, and reopen the loop.

## Raising a concern

Use the clinical safety issue template. Raise it early, raise it when unsure,
and raise it about your own work. A concern that turns out to be nothing costs
an hour. The alternative costs a patient.

Nobody at Taifa Health is ever penalised for raising a safety concern, and
anyone who discourages one is in breach of the
[code of conduct](../CODE_OF_CONDUCT.md).
