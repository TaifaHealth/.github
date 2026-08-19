# Vendored Kenyan FHIR IG packages: pins

These four packages are the **authority** for terminology bindings, profile
cardinalities and invariants across TaifaHealth. Where an international
publication (IPS, WHO SMART Guidelines, the ICD-11 roadmap) disagrees with
what is pinned here, the pinned Kenyan package wins.

Every package is extracted verbatim under `ig/packages/<name>/`, and the
tarball it came from is kept under `ig/dist/<name>.tgz`. The `sha256` below is
of that tarball. Committing both the tarball and the expanded tree is
deliberate: upgrades then show up as a reviewable diff of actual profile and
ValueSet content, not as an opaque blob swap.

> **These are continuous-integration builds off feature branches, not
> published releases.** `build.fhir.org` rewrites a branch's `package.tgz` in
> place whenever the branch is rebuilt, so re-downloading the same URL will
> eventually produce a different sha256. That is expected. The committed tree
> here, not the URL, is what our code and CI are validated against.

Verify or upgrade with `ig/tools/fetch.sh` (add `--update` to adopt upstream).

## Pins

### Kenya Patient Summary — `kps`

| field | value |
|---|---|
| package name | `ke.fhir.patient-summary` |
| version | `0.1.0` |
| canonical | `https://fhir.dha.go.ke/ig/patient-summary` |
| build date | 2026-08-16 12:29:10 UTC |
| FHIR version | 4.0.1 |
| branch | `compositionResource` |
| source | https://build.fhir.org/ig/IntelliSOFT-Consulting/Kenya-Patient-Summary-FHIR-IG/branches/compositionResource/package.tgz |
| sha256 (tarball) | `8b00075d52c768cf6d0c8efb8a43ce6331e0ef4401dea0985aed18292769992b` |
| tarball size | 932,044 bytes |
| resources | 423 |
| vendored at | `ig/packages/kps/package/` |
| dependencies | `hl7.fhir.r4.core@4.0.1`, `hl7.terminology.r4@7.3.0`, `hl7.fhir.uv.extensions.r4@5.3.0`, `hl7.fhir.uv.ips@2.0.0` |

### Kenya Core (SHA) — `core`

| field | value |
|---|---|
| package name | `kenya.fhir.core` |
| version | `1.0.0` |
| canonical | `https://fhir.sha.go.ke/fhir` |
| build date | 2026-05-30 04:51:31 UTC |
| FHIR version | 4.0.1 |
| branch | `profileValidation` |
| source | https://build.fhir.org/ig/IntelliSOFT-Consulting/Kenya-core-FHIR-IG/branches/profileValidation/package.tgz |
| sha256 (tarball) | `72c2528a7d70e4630f98fbc16363230645bccea5bbfa8912653e01e14a4852a6` |
| tarball size | 507,370 bytes |
| resources | 168 |
| vendored at | `ig/packages/core/package/` |
| dependencies | `hl7.fhir.r4.core@4.0.1`, `hl7.terminology.r4@7.1.0`, `hl7.fhir.uv.extensions.r4@5.3.0`, `hl7.fhir.uv.ips@1.1.0` |

### Kenya eClaims — `eclaims`

| field | value |
|---|---|
| package name | `ke.fhir.eclaims` |
| version | `0.1.0` |
| canonical | `https://fhir.dha.go.ke/ig/eclaims` |
| build date | 2026-08-07 13:05:54 UTC |
| FHIR version | 4.0.1 |
| branch | `canonicalUpdate` |
| source | https://build.fhir.org/ig/IntelliSOFT-Consulting/Kenya-eClaims-FHIR-IG/branches/canonicalUpdate/package.tgz |
| sha256 (tarball) | `e86a84e5d584209e02eb5e432b496387cadd82eda6a25a975e314bb2092baea0` |
| tarball size | 1,137,062 bytes |
| resources | 153 |
| vendored at | `ig/packages/eclaims/package/` |
| dependencies | `hl7.fhir.r4.core@4.0.1`, `hl7.fhir.uv.extensions.r4@5.3.0`, `hl7.terminology.r4@7.1.0` |

### Kenya Emergency — `emergency`

| field | value |
|---|---|
| package name | `fhir.kenyaEmergencyIG` |
| version | `0.1.0` |
| canonical | `https://nshr-uat.sha.go.ke/fhir` |
| build date | 2026-07-20 11:01:59 UTC |
| FHIR version | 4.0.1 |
| branch | `removedUnusedProfiles` |
| source | https://build.fhir.org/ig/IntelliSOFT-Consulting/Kenya-Emmergency-FHIR-IG/branches/removedUnusedProfiles/package.tgz |
| sha256 (tarball) | `fb98b9a6e6f0dbe67cf7d5e386edfd45f048062e73c92efcb13c1de59ba962b0` |
| tarball size | 753,790 bytes |
| resources | 232 |
| vendored at | `ig/packages/emergency/package/` |
| dependencies | `hl7.fhir.r4.core@4.0.1`, `hl7.terminology.r4@7.2.0`, `hl7.fhir.uv.extensions.r4@5.3.0` |

## sha256sum format

For scripted verification:

```
8b00075d52c768cf6d0c8efb8a43ce6331e0ef4401dea0985aed18292769992b  dist/kps.tgz
72c2528a7d70e4630f98fbc16363230645bccea5bbfa8912653e01e14a4852a6  dist/core.tgz
e86a84e5d584209e02eb5e432b496387cadd82eda6a25a975e314bb2092baea0  dist/eclaims.tgz
fb98b9a6e6f0dbe67cf7d5e386edfd45f048062e73c92efcb13c1de59ba962b0  dist/emergency.tgz
```

## Canonical URL map

The four IGs do not share a canonical base. Anything we emit or match on must
use the exact base of the IG that defines it.

| IG | canonical base |
|---|---|
| Kenya Patient Summary | `https://fhir.dha.go.ke/ig/patient-summary` |
| Kenya Core (SHA) | `https://fhir.sha.go.ke/fhir` |
| Kenya eClaims | `https://fhir.dha.go.ke/ig/eclaims` |
| Kenya Emergency | `https://nshr-uat.sha.go.ke/fhir` |

> **Trap.** The KPS package publishes all 131 of its CodeSystems under
> `https://fhir.dha.go.ke/ig/patient-summary/CodeSystem/…`, but its own example
> instances and 14 of its ValueSets reference them as
> `https://fhir.dha.go.ke/fhir/CodeSystem/…`, which is published nowhere. Emit
> the `/ig/patient-summary/` form. See `ig/CONFORMANCE_RULES.md`,
> "Upstream defects", defect **D1**.
