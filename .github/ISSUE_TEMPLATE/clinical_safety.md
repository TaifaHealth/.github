---
name: Clinical safety concern
about: A hazard, near miss, or safety risk in the software
title: "[safety] "
labels: clinical-safety, priority-high, needs-triage
assignees: ''
---

<!--
  Use this whenever the software could contribute to patient harm, whether or
  not harm occurred, and whether or not you are sure. Raising a concern that
  turns out to be nothing is always the right call. Nobody is penalised for
  raising one, including the person who introduced the problem.

  If a patient is at risk RIGHT NOW: call the emergency support line first,
  then file this.

  No patient data. Describe the clinical situation without identifying anyone.
-->

### What is the hazard

<!-- What could go wrong, in clinical terms. For example: "an allergy recorded
     at a previous encounter is not shown on the prescribing screen". -->

### How it can reach a patient

<!-- The chain from software behaviour to potential harm. -->

### Has this already happened?

- [ ] Hazard only, no known incident
- [ ] Near miss, caught before reaching a patient
- [ ] Incident, reached a patient
  - Reported to the facility incident process: yes / no

### Severity if it occurs

- [ ] Catastrophic (death or permanent major harm)
- [ ] Major (permanent minor harm, or severe temporary harm)
- [ ] Moderate (temporary harm needing intervention)
- [ ] Minor (inconvenience, no clinical impact)

### Likelihood

- [ ] Very high, happens routinely
- [ ] High, happens regularly
- [ ] Medium, happens occasionally
- [ ] Low, needs an unusual combination of circumstances

### Affected component and versions

### Existing controls

<!-- What currently stops this reaching a patient: a second check, a paper
     process, an alert, staff training. -->

### Proposed mitigation

---

**For the clinical safety officer**

- [ ] Added to the hazard log with an identifier
- [ ] Risk rated (severity times likelihood)
- [ ] Affected facilities notified, with a workaround if one exists
- [ ] Mitigation tracked to a fix
- [ ] Hazard log entry closed with residual risk recorded
