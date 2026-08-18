## What this changes

<!-- One paragraph. What was wrong or missing, and what this does about it. -->

Closes #

## How it was tested

<!-- Tests added, manual steps taken, and against what data. -->

## Checklist

- [ ] Tests cover the new behaviour, and a bug fix has a test that failed before it
- [ ] Lint, types, and the full test suite pass locally
- [ ] No patient data in the diff, the fixtures, the tests, or this description
- [ ] Documentation updated if behaviour or the API changed

## Data protection

- [ ] Does not add a new field holding personal or health data
- [ ] Adds personal or health data, and: the purpose is documented, retention is
      defined, access is restricted by role, and the data protection officer has
      been informed
- [ ] Every read or write of a patient record here is captured by the audit trail
- [ ] Nothing sensitive is written to logs, error messages, or analytics

## Clinical safety

- [ ] No clinical impact: this cannot change what a clinician sees, is alerted
      to, or decides
- [ ] Clinical impact, and: the hazard is described below, the clinical safety
      officer has reviewed it, and the hazard log is updated

<!-- If clinical impact, describe the hazard, its severity, and the mitigation. -->

## Migrations and deployment

- [ ] No migration
- [ ] Forward-only migration, safe to run during clinic hours
- [ ] Migration requires a maintenance window (explain below)
- [ ] Breaking API change, and consumers have been identified and notified
