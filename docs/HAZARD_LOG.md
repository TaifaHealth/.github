# Hazard log

The log `docs/CLINICAL_SAFETY.md` requires: every hazard gets an entry, entries
are closed and never deleted, and the log is reviewed at every release and
audited when a facility asks.

Severity and likelihood use the scales in
`.github/ISSUE_TEMPLATE/clinical_safety.md`. Risk is severity times likelihood.
A catastrophic hazard with any likelihood above negligible blocks a release.

**Nothing here has been accepted yet.** Accepting residual risk is a named
person's decision, and TaifaHealth has not appointed a clinical safety officer.
Until that happens, every entry below reads "not accepted", and that is the
honest state, not an oversight. No facility should run this software on real
patients while this column is empty.

Status is **open** (mitigation outstanding), **controlled** (mitigation in
place, residual risk stands), or **closed** (no longer reachable).

---

## HAZ-001 An allergy warning can be overridden at prescribing

**Chain.** A clinician prescribes a drug that collides with a recorded allergy.
The system refuses and offers an override. The clinician overrides, out of
habit or time pressure, and the patient receives a drug they react to.

**Severity** Catastrophic (anaphylaxis). **Likelihood** Low.
**Status** controlled.

**Controls.** The prescription is refused outright rather than warned about.
Proceeding requires a free-text reason, which is stored on the prescription and
written to the append-only audit trail with the prescriber's identity. There is
no way to override silently and no way to remove the record afterwards.

**Residual risk.** An override remains possible by design, because forbidding it
outright would stop legitimate prescribing where the recorded allergy is wrong
or the benefit outweighs it. The control is accountability, not prevention.

**Mitigation outstanding.** Overrides are not reviewed by anyone. A periodic
report of overrides per prescriber would turn the audit record into an actual
control. Not built.

**Accepted by** not accepted.

---

## HAZ-002 A penicillin allergy cannot be coded, only typed

**Chain.** Kenya's `kps-substances-cs` declares `content: complete`, declares
500 concepts, contains exactly 500, and does not include penicillin,
amoxicillin, latex or peanut. So an allergy to any of them is carried as free
text. A receiving system reading our Kenya Patient Summary cannot match that
text against its own allergy checking, and prescribes the drug.

**Severity** Catastrophic. **Likelihood** Medium, penicillin allergy is common.
**Status** open, blocked upstream.

**Controls.** Inside TaifaHealth the allergy check works on the recorded text
and HAZ-001 applies, so our own prescribing is protected. The gap is at the
boundary, when another system consumes the summary.

**Residual risk.** Real and not ours to close. Documented as defect D2 in
`ig/CONFORMANCE_RULES.md` and raised upstream in
`ig/reports/2026-08-19-kps-defects.md`.

**Explicitly refused mitigation.** We could emit a SNOMED code under the Kenyan
system URL and the validator would accept it, because it cannot expand that
ValueSet. That would assert a code is a member of a code system the vendored
package proves it is not. A lie that validates is worse than a gap that is
documented, because the next reader believes it.

**Accepted by** not accepted.

---

## HAZ-003 The Client Registry is a mock, and its UPIs are not national

**Chain.** Registration issues a Universal Patient Identifier from a local mock,
not from AfyaLink. Two facilities register the same person and get different
identifiers, or worse, two different people collide on one. Records are then
merged or split on a false identity.

**Severity** Catastrophic. `docs/CLINICAL_SAFETY.md` names identity as the
highest-consequence operation in the platform. **Likelihood** Very high if
deployed to more than one facility. **Status** open.

**Controls.** None adequate. The mock is deterministic and clearly marked in
`docs/CAPABILITIES.md` as capability 12, state "mock, blocked on AfyaLink
access".

**Mitigation outstanding.** Real AfyaLink credentials. The seam exists and the
mock implements the same interface, so the swap is a constructor change, but no
amount of building produces the credential.

**This hazard alone should block any multi-facility deployment.**

**Accepted by** not accepted.

---

## HAZ-004 A queued clinical write is recorded twice

**Chain.** A device loses its link, queues a vitals set, and the flush is
interrupted after the server committed but before the response arrived. The
client cannot tell that from "never arrived", retries, and the observation is
recorded twice. A duplicated observation misleads anyone reading a trend.

**Severity** Moderate. **Likelihood** High on an intermittent link.
**Status** controlled.

**Controls.** Each queued write carries a client-generated `Idempotency-Key` for
its whole life. The server writes the claim before running the handler, stores
the response, and replays it for any repeat of that key. The settle runs on a
context detached from the request, because a client hanging up would otherwise
leave the claim open for takeover and the write would be made again. Writes
carry the key even when the link is up, since the expensive case is the lost
response rather than the obvious outage.

**Closed instance, worth keeping visible.** On 2026-08-20 the node server that
fronts the backend was found to be dropping the `Idempotency-Key` header: it
copied an allowlist of three headers upstream. The guarantee was absent in
production only. Dev forwarded everything and the Go tests call the API
directly, so both were green. Fixed by forwarding all but hop-by-hop headers,
with a test that an unknown header is forwarded rather than dropped. The lesson
is the hazard: a safety control that is not exercised along the real path is not
a control.

**Accepted by** not accepted.

---

## HAZ-005 A child's observations are not flagged, and the chart looks reassuring

**Chain.** Vitals flagging uses adult reference ranges. A toddler's pulse of 120
and respiratory rate of 28 are normal for age but abnormal for an adult.
Flagging them would cry wolf on every child until clinicians ignore flags
entirely, so under 18 the system flags neither pulse, respiratory rate, nor
blood pressure. A clinician reads an unflagged chart as a well child.

**Severity** Major. **Likelihood** Medium. **Status** controlled, incomplete.

**Controls.** SpO2 and temperature are flagged at every age, being close enough
to age independent. For anyone under 18 the row carries an explicit note
naming what is not being flagged and why, so absence of a flag cannot be read as
presence of normality.

**Mitigation outstanding.** Age-banded reference ranges for paediatric pulse,
respiratory rate and blood pressure, sourced from a Kenyan or WHO reference
rather than invented. Until then the note is the whole control, and a note is a
weak control by the standard of `docs/CLINICAL_SAFETY.md` step 2.

**Accepted by** not accepted.

---

## HAZ-006 A paediatric body mass index is read as an adult's

**Chain.** BMI is computed from weight and height at any age. For a child the
number means nothing without a growth reference for age and sex. A clinician
reads 15.2 as underweight and acts on it.

**Severity** Moderate. **Likelihood** Medium. **Status** controlled.

**Controls.** Under 18 the value is shown with the interpretation withheld in as
many words: not interpretable without a growth reference for age and sex.
Covered by tests that assert the caveat is present for a child and absent for an
adult.

**Mitigation outstanding.** Growth references and percentile plotting, which is
its own feature with its own hazards, not a tweak to this one.

**Accepted by** not accepted.

---

## HAZ-007 A patient is registered without a phone number

**Chain.** The Kenya Patient Summary IG makes `Patient.telecom` mandatory
(KPS-PAT-8). Registration allows a patient with no phone, so a summary is
exported that does not satisfy the profile, and a receiving system may reject
it. Follow-up by phone is also impossible.

**Severity** Minor clinically, moderate operationally. **Likelihood** High: many
patients present without a phone. **Status** controlled by decision.

**Controls.** Registration proceeds. The chart carries a conformance note citing
the rule, so the gap is visible to whoever looks at the record rather than
surfacing later as a rejected export.

**The decision, recorded deliberately.** Conformance never blocks care. A
patient without a phone is registered and treated. This is a considered
departure from the IG and is documented in `docs/IG_CONFORMANCE.md`, not an
oversight.

**Accepted by** not accepted.

---

## HAZ-008 The system is unavailable in a department

**Chain.** `docs/CLINICAL_SAFETY.md` says an outage in a ward is a clinical
event. Power or connectivity fails and clinicians cannot read allergies,
results, or the queue.

**Severity** Major. **Likelihood** High in a sub-county facility.
**Status** controlled, partially.

**Controls.** The interface and its assets are served from the device, so the
application opens with no network. The worklist and the last twenty charts
opened on that device are readable offline with an explicit capture timestamp,
so nothing stale is presented as live. Append-only clinical writes queue and
reconcile. Anything needing a central authority refuses with a sentence saying
why, rather than spinning.

**Residual risk.** A chart never opened on that device is not available offline.
A clinician meeting an unfamiliar patient during an outage has nothing. Verified
in a browser with the network cut on 2026-08-20.

**Mitigation outstanding.** No pre-caching of, for example, today's booked
patients. Considered and not built, because caching charts nobody opened widens
the amount of patient data resident on a device that may be shared or lost, and
that trade needs a decision by someone accountable, not a default chosen here.

**Accepted by** not accepted.

---

## HAZ-009 A manifestation code is offered for a reaction that was ruled out

**Chain.** The allergy form suggests a coded manifestation from what the
clinician typed. The clinician types "no rash seen". The suggestion offers
`RASH`, they accept it under time pressure, and the record now says the patient
reacted with a rash they were explicitly noted not to have. The next clinician
reads it as fact.

**Severity** Moderate. **Likelihood** Low. **Status** controlled.

**Controls.** Nothing is ever mapped automatically: on the server there is no
text-to-code mapping at all, and a code that the terminology service cannot
verify is dropped rather than stored. In the interface the suggestion is offered
behind an explicit click, never applied on its own. It fires only on a
whole-word match of a code's own wording, and offers nothing at all when two
codes both fit, so "crushing chest pain" suggests neither `CHEST-PAIN` nor
`PAIN`. Negated matches are suppressed: "no rash", "denies rash", "without rash"
all offer nothing, scoped to the clause so that "fever, no rash" still offers
`FEVER`. The clinician's own words are always kept and always exported alongside
any code.

**Residual risk.** Negation detection is a word list, not language
understanding. Phrasings it does not know will still offer a code, and the
control of last resort is that a person clicked.

**Needs a decision.** Whether to keep the suggestion at all is a clinical
safety officer's call, not an engineering one. Removing it costs a few
keystrokes per allergy and removes this hazard entirely.

**Accepted by** not accepted.

---

## HAZ-010 An adult is told they are overdue eighteen infant vaccines

**Chain.** The KEPI schedule was placed against a date of birth with no upper
age bound, so every scheduled childhood dose not on the record read as
"overdue". A 48 year old patient's chart showed eighteen doses overdue in red.
The reader learns the immunization strip means nothing, and misses the child
for whom it means everything.

**Severity** Major, by way of alarm fatigue rather than directly.
**Likelihood** Very high: it happened for every adult in the system.
**Status** controlled.

**Controls.** A dose the childhood schedule no longer addresses now reads
`out-of-range` rather than `overdue`, and the section says in one quiet line
that the schedule no longer applies at this age and that vaccinations given
before this record began are not held here. Doses actually on the record still
read as given at any age. Covered by tests in both directions: an adult shows
no overdue dose, and a two year old with nothing recorded still does.

**Residual risk, and it is the important part.** The cutoff is five years, and
that is **not a settled clinical number**. Kenyan and WHO catch-up guidance
differs by antigen and the right answer is probably per vaccine rather than one
bound. Five was chosen because it is the common catch-up horizon and because
the alternative in the code was no bound at all, which was certainly wrong. Set
too low, a child who could still be caught up stops being flagged, which is the
more dangerous direction.

**Needs a decision** before release: the cutoff, and whether it should be per
antigen.

**Accepted by** not accepted.

---

## HAZ-011 An out-of-range vital sign is shown without a reference range

**Chain.** The observation history flags a reading as out of range in words
("systolic out of range") but does not show the range it was judged against.
A clinician cannot tell whether the threshold matches their protocol, and a
facility using different thresholds has no way to see the mismatch.

**Severity** Minor. **Likelihood** Medium. **Status** open.

**Controls.** The flag is worded, not coloured red: clinical severity owns red
in this interface and an out-of-range vital sign is not a critical result. The
ranges are the widely taught adult resting ones and live in one place in
`internal/service/vitals.go`.

**Mitigation outstanding.** Show the range alongside the flag, and let a
facility configure its own thresholds rather than inherit whatever was
hardcoded. Not built.

**Accepted by** not accepted.

