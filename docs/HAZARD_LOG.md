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

---

## HAZ-012 Two patients are admitted into one bed

**Chain.** Two devices draw the bed board, both see bed 4 free, both admit. The
software records two patients in one bed and the second is walked to a bed that
is occupied.

**Severity** Major. **Likelihood** High on a busy ward. **Status** controlled.

**Controls.** A partial unique index, `admissions_one_live_per_bed ON
admissions(bed_id) WHERE status='admitted'`. There is deliberately **no**
application pre-check of occupancy: a check in Go cannot see a transaction that
has not committed, so the second insert blocks on the index and returns 23505,
which becomes a 409 saying the board has moved and to pick another bed. A CHECK
pins `status` to the two values the index is written against, because a status
string drifting by one character would silently free every bed it touched.

**Verified independently at the database level**, not only through the
application: a second live admission to one bed is rejected by Postgres.

**Accepted by** not accepted.

---

## HAZ-013 A patient appears on two wards at once

**Chain.** An admission is opened for a patient who is already admitted, from a
second encounter or a colleague who did not know. The round on the ward they
are not on shows them; the round on the ward they are on may not.

**Severity** Major. **Likelihood** Medium. **Status** controlled.

**Controls.** Partial unique indexes on `(facility_id, patient_id)` and on
`visit_id` where the admission is live. The refusal says to transfer rather
than admit again. The ward round is derived from live admissions, so there is
no second list to fall out of step.

**Accepted by** not accepted.

---

## HAZ-014 A transfer half applies and the movement history stops reconstructing

**Chain.** The bed is updated but no movement is written, or the reverse. Where
a patient was can no longer be reconstructed, which is half the point of ADT.

**Severity** Moderate. **Likelihood** Medium. **Status** controlled.

**Controls.** One transaction: `SELECT ... FOR UPDATE` on the admission so two
clinicians moving the same patient serialise rather than interleave, then the
bed check, the update and the movement insert. The destination bed is claimed
by the same unique index as an admission, so a transfer into a bed taken a
moment ago fails on the constraint rather than on a stale read.
`admission_movements` is append-only and **the database enforces it**: a
trigger refuses UPDATE and DELETE, because a record of where a patient was that
somebody can rewrite is not a record.

**Verified independently**: UPDATE and DELETE on a movement row are both
refused by Postgres with an explicit message.

**Accepted by** not accepted.

---

## HAZ-015 A discharge frees a bed while the patient is still on the ward

**Chain.** The bed reads free and the next patient is brought to it. Or the
reverse: the patient is recorded as gone with the bed still held, and the ward
looks full when it is not.

**Severity** Major. **Likelihood** Medium. **Status** controlled.

**Controls.** There is no `occupied` flag anywhere. Occupancy is derived from
the live admission every time it is read, so there is no second copy of the
truth to drift. Discharge is one transaction closing the admission, writing the
movement and ending the encounter. A CHECK makes a discharge all of its parts
or none: `status='discharged'` requires both a time and a destination.
Destination is one of home, referred, absconded, died, so an absconded patient
cannot be recorded as having gone home.

**Residual risk.** The system records what a clinician tells it. A patient who
walks out unrecorded is still shown in a bed, which is what the absconded
destination exists to close afterwards.

**Accepted by** not accepted.

---

## HAZ-016 An encounter is closed while its patient is lying on a ward

**Chain.** The outpatient consultation panel discharges the visit. The patient
leaves every list, the bed stays occupied, and nobody has written a discharge
summary or recorded where they went.

**Severity** Major. **Likelihood** High, because the outpatient discharge button
is the one clinicians already know. **Status** controlled.

**Controls.** Two layers, deliberately. The service answers 409 naming the ward
and bed and saying to discharge from the ward instead; and the repository
UPDATE carries `AND NOT EXISTS (live admission)`, so the guarantee does not
depend on the service being called first. Admission moves the encounter to
`admitted` rather than closing it, so an inpatient's notes, orders and results
still belong to the encounter that admitted them.

**Accepted by** not accepted.

---

## HAZ-017 An admission is filed against an encounter that already ended

**Chain.** A stale panel admits on a discharged encounter. The stay hangs off a
closed record and the timeline reads as care given after the patient left.

**Severity** Moderate. **Likelihood** Medium. **Status** controlled.

**Controls.** The insert selects from `visits ... AND v.status <> 'discharged'`,
and the patient is taken from the visit row rather than from the caller, so an
admission can never be filed against somebody else. A closed encounter (409)
is told apart from another facility's (404), because they need different things
done about them.

**Accepted by** not accepted.

---

## HAZ-018 A queued admission is accepted at the bedside and refused on arrival

**Chain.** The link is down. A device queues the admission the way it queues
vitals. Two devices flush into the same bed and one is refused, having already
shown a clinician the patient in it.

**Severity** Major. **Likelihood** High on an intermittent link.
**Status** controlled by refusal.

**Controls.** No ADT route is queueable and none accepts an idempotency key.
Admitting refuses offline in words: a bed is a claim on a central resource, not
a record of something that already happened to a patient, and that is the line
the offline architecture already draws for the Client Registry.

**Accepted by** not accepted.

---

## HAZ-019 Length of stay is computed from a timestamp in the wrong zone

**Chain.** "In for 2 d 6 h" is what a clinician acts on for fluid balance and
review timing. Computing it from a formatted string carrying a `Z` it did not
earn puts it hours out. `docs/CLINICAL_SAFETY.md` warns that most published
health IT harm comes from mundane things, and names time zones.

**Severity** Minor to moderate. **Likelihood** Medium.
**Status** controlled.

**Controls.** Stay length is computed in Postgres from the admission time, and
the ADT routes convert to UTC before appending the literal `Z`.

**The wider fix, which is the important half.** The other 40 `to_char(ts,
'...Z')` sites across the read models did not convert, and nothing pinned a
session timezone. They were correct only because the database container
happened to run `Etc/UTC`. Point the system at a Postgres set to
`Africa/Nairobi`, which is an entirely reasonable thing for a Kenyan facility
to configure, and every time in the record silently shifts by three hours while
still claiming to be UTC: doses, observations, admissions, the audit trail.

Fixed by pinning the session to UTC in the connection pool, once, rather than
editing forty call sites, because a sweep leaves the forty-first to whoever
writes the next query. A test asks for `Africa/Nairobi` in the DSN and asserts
the session is still UTC and that `to_char` agrees with it. The test was
checked in both directions: with the pin removed it fails.

**Residual risk.** A read model that formats a timestamp in application code
rather than in SQL would not be covered by the pin. None does today.

**Accepted by** not accepted.

---

## HAZ-020 An imaging study irradiates a pregnant patient

**Chain.** A clinician orders a plain abdominal film or a CT on a woman who is
pregnant. Nobody asks, or the answer is not recorded, and the foetus is
irradiated.

**Severity** Major to catastrophic, depending on dose and gestation.
**Likelihood** Medium: the commonest ionising studies in these facilities are
abdominal and pelvic. **Status** controlled.

**Controls.** The order form is where this is caught, not the machine. For an
ionising study on a patient the register says could be pregnant, a pregnancy
status is required and the order is refused without one. `not_applicable` is
refused on its own, because it is the answer somebody clicks to get past the
question. An answer of `pregnant` refuses the order outright and proceeding
requires a written justification stored on the order, on the care timeline and
in the audit trail with the clinician's identity. This is deliberately the
allergy-at-prescribing model from HAZ-001: refusal plus accountability, not a
silent auto-refusal and not a warning nobody reads. The interlock is a CHECK on
the table as well as a service rule, so it survives a future caller who forgets
to ask. Whether a study is ionising is derived from its modality across all 51
of Kenya's acquisition modalities, and an unknown modality is treated as
ionising.

**Residual risk, and it is the weak point.** `unknown` is allowed through. It is
often the true answer, and forcing a choice between two answers a clinician does
not have produces a false one. An unknown status is carried onto the radiology
worklist in amber and the radiographer at the machine is the control of last
resort, which is a human control and the weakest kind by the standard in
`docs/CLINICAL_SAFETY.md`.

**Closed instance, kept visible because the lesson is the hazard.** Code review
found the age band originally decided whether the interlock ran at all. An
ionising study on a patient recorded as **pregnant** but outside the band, or
male, skipped the justification, violated the table CHECK, and returned a 404
saying the encounter did not exist: the order was silently lost. The order panel
asks the pregnancy question without knowing the patient's age, so a mis-click
reached it. Fixed so a recorded `pregnant` is believed whatever the register
says, with the band deciding only whether a **missing** answer is refused. The
test for it was verified to fail against the defective code.

**Mitigation outstanding.** No dose recording and no cumulative dose per
patient. No enforced justification for `unknown`, considered and not built
because it would put friction on every woman of childbearing age whose status
was not checked, and a decision that heavy belongs to a clinical safety officer.

**Accepted by** not accepted.

---

## HAZ-021 A report is filed against the wrong study or the wrong patient

**Chain.** A radiologist works from two studies at once, or a stale panel. The
report lands on another patient's record and the next clinician reads someone
else's images as this patient's.

**Severity** Major. **Likelihood** Low to medium. **Status** controlled.

**Controls.** There is no patient identifier in the report request to be wrong:
the report is keyed to the order and the order supplies both the patient and the
facility. A unique index allows one report per order, so a second is refused
rather than leaving two answers to one question with nothing saying which is
current. The report modal shows the patient's name and UPI, the study, and the
clinical question that was asked; the worklist row carries name, UPI, age and
sex, because a name and a UPI are what two patients called Wanjiku Kamau have in
common.

**Residual risk.** Nothing verifies that the images the radiologist looked at are
the images the order asked for. Without a PACS there is nothing to verify
against.

**Mitigation outstanding.** No amendment path: a wrong report can only be
followed by a new order. Amendment is its own hazard, since the ordering
clinician may already have acted on the original, and needs its own analysis.

**Accepted by** not accepted.

---

## HAZ-022 A critical imaging finding sits unread in a worklist

**Chain.** A radiologist reports a tension pneumothorax or an extradural
haematoma. The ordering clinician has gone off shift, nobody reads the
notification, and the patient waits.

**Severity** Catastrophic. **Likelihood** Medium.
**Status** open, controlled only weakly.

**Controls.** The reporter marks the finding critical. The notification to the
ordering clinician is retitled and says so, the timeline entry is prefixed
CRITICAL, the flag is on the record and in the audit trail, and the worklist and
chart show the impression in the danger colour. That is the whole of it.

**What is deliberately not built, said plainly because the gap is the hazard.**
No acknowledgement, no read receipt, no escalation after a timeout, no second
recipient, no on-call routing, no telephone or SMS. The checkbox in the
interface says so in as many words, rather than letting a radiologist believe
that ticking it summons somebody. A critical result pathway is a facility policy
question, who is called, in what time, and who is called when they do not
answer, before it is a software one, and inventing one here would be worse than
naming its absence.

**This is the highest residual risk in the log after HAZ-003.**

**Accepted by** not accepted.

---

## HAZ-023 A radiology report is on the chart and absent from the patient summary

**Chain.** The terminology service cannot confirm an investigation code, so the
order stores none. The report is filed, appears on the chart, and reads
normally. The Kenya Patient Summary leaves it out, and the receiving facility
repeats the study or misses the finding.

**Severity** Moderate. **Likelihood** Low. **Status** controlled, incomplete.

**Controls.** The omission is deliberate rather than accidental:
`DiagnosticReport.code` is bound Required, so a text-only code would fail the
binding and take its whole section entry down with it. The report is never
withheld from the patient's own record. A code the terminology service answers
"not found" for is logged as loudly as an outage, because for a code that came
off our own catalogue it means the catalogue is wrong.

**Residual risk.** Nothing tells the clinician at the time that this report will
not travel. The chart already carries a conformance-note mechanism for the
missing-phone case (HAZ-007) and this belongs there.

**Related gap, stated rather than hidden.** The acquisition modality does not
travel in the summary at all, because `ke-kps-imaging-study` is not emitted:
FHIR R4 makes `ImagingStudy.series.uid` mandatory and there is no PACS to supply
a DICOM UID. Minting one would assert that a series exists which nothing can
resolve, the same class of lie the export already refuses for allergy
substances. The modality is on the order, the worklist and the chart, and is
legible inside the investigation code's own wording.

**Accepted by** not accepted.

