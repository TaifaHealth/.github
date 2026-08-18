# Support

## For facilities running Taifa Health

If patient care is affected, use the emergency support line in your service
agreement, not GitHub. GitHub issues are not monitored around the clock and a
ward at 2am cannot wait for a triage rotation.

| Need | Where |
|---|---|
| System down, or patient care affected | Emergency line in your service agreement |
| Non-urgent fault, question, or change request | `support@taifahealth.co.ke` |
| User guides and training material | The documentation site (`taifa-health-docs`) |
| Suspected security issue or data breach | [SECURITY.md](SECURITY.md), never a public issue |

## For developers and integrators

- **Bugs and feature requests:** open an issue in the specific service
  repository using the templates. Issues opened here in `.github` that belong
  to a service will be moved.
- **Questions about the platform, the API, or an integration:** start a
  discussion in the relevant repository.
- **Integration and FHIR API questions:** see
  [docs/STANDARDS.md](docs/STANDARDS.md) first, then open a discussion in
  `taifa-interop`.

## What makes an issue useful

Repository and version or commit, environment (local, staging, a facility
deployment), what you did, what you expected, what happened, and any error
identifier from the interface.

**Never include patient data.** Not a name, a national ID, a hospital number, a
date of birth, or an unredacted screenshot. Reference the internal record
identifier and we will look it up.
