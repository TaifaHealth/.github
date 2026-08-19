#!/usr/bin/env python3
"""Extract machine-readable conformance facts from vendored Kenyan FHIR IG packages.

Reads the NPM-style FHIR packages under ig/packages/<ig>/package/ and emits
ig/extract/<ig>-summary.json for each, containing:

  * every StructureDefinition: id, url, base resource, kind/derivation, and
    for each element its cardinality, mustSupport flag, fixed/pattern values,
    slicing discriminators and terminology binding
  * every binding, flattened: element path, strength, ValueSet canonical
  * every ValueSet: canonical, name, the code systems it composes from,
    whether those systems resolve inside the vendored packages, and concept
    counts (enumerated concepts only; filter-based includes are marked)
  * every CodeSystem: canonical, name, concept count (recursive)
  * NamingSystems and their unique identifier URIs
  * the example instances shipped with the package

Usage:  python3 ig/tools/extract_ig.py [--packages DIR] [--out DIR]

The output is deliberately stable-sorted so that re-running it after a package
upgrade produces a reviewable diff.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter


# --------------------------------------------------------------------------
# loading
# --------------------------------------------------------------------------

def load_package(pkg_dir):
    """Load every JSON resource in a package directory (root + example/)."""
    resources = []
    for sub in ("", "example"):
        d = os.path.join(pkg_dir, sub) if sub else pkg_dir
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if not name.endswith(".json") or name in (".index.json", "package.json"):
                continue
            path = os.path.join(d, name)
            if not os.path.isfile(path):
                continue
            try:
                with open(path, encoding="utf-8") as fh:
                    res = json.load(fh)
            except (json.JSONDecodeError, UnicodeDecodeError) as exc:
                print(f"  warn: cannot parse {path}: {exc}", file=sys.stderr)
                continue
            if isinstance(res, dict) and res.get("resourceType"):
                resources.append((name, "example" if sub else "root", res))
    return resources


# --------------------------------------------------------------------------
# StructureDefinition
# --------------------------------------------------------------------------

def element_facts(elem):
    """Pull the conformance-relevant facts out of one ElementDefinition."""
    fact = {
        "path": elem.get("path"),
        "id": elem.get("id"),
        "min": elem.get("min"),
        "max": elem.get("max"),
    }
    if elem.get("mustSupport"):
        fact["mustSupport"] = True
    if elem.get("sliceName"):
        fact["sliceName"] = elem["sliceName"]
    if "slicing" in elem:
        disc = elem["slicing"].get("discriminator", [])
        fact["slicing"] = {
            "discriminator": [f"{d.get('type')}:{d.get('path')}" for d in disc],
            "rules": elem["slicing"].get("rules"),
        }

    types = [t.get("code") for t in elem.get("type", []) if t.get("code")]
    if types:
        fact["types"] = types
    targets = sorted({p for t in elem.get("type", []) for p in t.get("targetProfile", [])})
    if targets:
        fact["targetProfiles"] = targets
    profiles = sorted({p for t in elem.get("type", []) for p in t.get("profile", [])})
    if profiles:
        fact["typeProfiles"] = profiles

    for key in list(elem):
        if key.startswith("fixed"):
            fact["fixed"] = {"element": key, "value": elem[key]}
        elif key.startswith("pattern"):
            fact["pattern"] = {"element": key, "value": elem[key]}

    binding = elem.get("binding")
    if binding:
        b = {"strength": binding.get("strength")}
        if binding.get("valueSet"):
            b["valueSet"] = binding["valueSet"]
        if binding.get("description"):
            b["description"] = binding["description"]
        fact["binding"] = b

    constraints = [
        {
            "key": c.get("key"),
            "severity": c.get("severity"),
            "human": c.get("human"),
            "expression": c.get("expression"),
        }
        for c in elem.get("constraint", [])
        # base-spec constraints (ele-1, dom-*, ext-1) carry no local meaning
        if c.get("key") and not c["key"].startswith(("ele-", "dom-", "ext-"))
    ]
    if constraints:
        fact["constraints"] = constraints

    return fact


def is_interesting(fact):
    """Keep only elements a conformance rule could be written against."""
    return (
        (fact.get("min") or 0) >= 1
        or fact.get("mustSupport")
        or fact.get("binding")
        or fact.get("fixed")
        or fact.get("pattern")
        or fact.get("slicing")
        or fact.get("sliceName")
        or fact.get("constraints")
        or (fact.get("max") not in (None, "*"))
    )


def summarize_structuredefinition(sd):
    diff = sd.get("differential", {}).get("element", [])
    snap = sd.get("snapshot", {}).get("element", [])
    # The differential is what the IG authors actually wrote; the snapshot is
    # the resolved view. Prefer the differential for "what this IG says", but
    # fall back to the snapshot when no differential is shipped.
    source, elems = ("differential", diff) if diff else ("snapshot", snap)

    facts = [element_facts(e) for e in elems]
    kept = [f for f in facts if is_interesting(f)]

    required = [f["path"] for f in facts if (f.get("min") or 0) >= 1]
    must_support = [f["path"] for f in facts if f.get("mustSupport")]

    bindings = [
        {
            "path": f["path"],
            "id": f.get("id"),
            "strength": f["binding"].get("strength"),
            "valueSet": f["binding"].get("valueSet"),
        }
        for f in facts
        if f.get("binding")
    ]

    root_constraints = [
        {
            "key": c.get("key"),
            "severity": c.get("severity"),
            "human": c.get("human"),
            "expression": c.get("expression"),
        }
        for c in (elems[0].get("constraint", []) if elems else [])
        if c.get("key") and not c["key"].startswith(("ele-", "dom-", "ext-"))
    ]

    return {
        "id": sd.get("id"),
        "url": sd.get("url"),
        "name": sd.get("name"),
        "title": sd.get("title"),
        "version": sd.get("version"),
        "status": sd.get("status"),
        "kind": sd.get("kind"),
        "derivation": sd.get("derivation"),
        "abstract": sd.get("abstract", False),
        "type": sd.get("type"),
        "baseResource": sd.get("type"),
        "baseDefinition": sd.get("baseDefinition"),
        "context": [
            f"{c.get('type')}:{c.get('expression')}" for c in sd.get("context", [])
        ],
        "elementSource": source,
        "requiredElements": sorted(set(required)),
        "mustSupportElements": sorted(set(must_support)),
        "bindings": bindings,
        "rootConstraints": root_constraints,
        "elements": kept,
    }


# --------------------------------------------------------------------------
# CodeSystem / ValueSet
# --------------------------------------------------------------------------

def count_concepts(concepts):
    total = 0
    for c in concepts or []:
        total += 1
        total += count_concepts(c.get("concept"))
    return total


def summarize_codesystem(cs):
    enumerated = count_concepts(cs.get("concept"))
    return {
        "id": cs.get("id"),
        "url": cs.get("url"),
        "name": cs.get("name"),
        "title": cs.get("title"),
        "version": cs.get("version"),
        "status": cs.get("status"),
        "content": cs.get("content"),
        "declaredCount": cs.get("count"),
        "conceptCount": enumerated,
    }


def summarize_valueset(vs, known_systems):
    """known_systems: {codesystem url -> conceptCount} across all vendored packages."""
    compose = vs.get("compose", {})
    includes = []
    resolvable = True
    total = 0
    for kind in ("include", "exclude"):
        for inc in compose.get(kind, []):
            system = inc.get("system")
            entry = {"mode": kind, "system": system}
            if inc.get("version"):
                entry["systemVersion"] = inc["version"]
            if inc.get("valueSet"):
                entry["valueSets"] = inc["valueSet"]
            enumerated = inc.get("concept")
            if enumerated is not None:
                entry["enumeratedConcepts"] = len(enumerated)
                if kind == "include":
                    total += len(enumerated)
            if inc.get("filter"):
                entry["filters"] = [
                    f"{f.get('property')} {f.get('op')} {f.get('value')}"
                    for f in inc["filter"]
                ]
            if system is None:
                # include-by-valueset only; resolvability follows the referenced VS
                entry["localSystem"] = None
            elif system in known_systems:
                entry["localSystem"] = True
                if enumerated is None and not inc.get("filter") and kind == "include":
                    # "all codes from this system"
                    total += known_systems[system]
            else:
                entry["localSystem"] = False
                if kind == "include":
                    resolvable = False
            includes.append(entry)

    expansion = vs.get("expansion", {})
    exp_count = expansion.get("total")
    if exp_count is None and expansion.get("contains") is not None:
        exp_count = len(expansion["contains"])

    return {
        "id": vs.get("id"),
        "url": vs.get("url"),
        "name": vs.get("name"),
        "title": vs.get("title"),
        "version": vs.get("version"),
        "status": vs.get("status"),
        "immutable": vs.get("immutable"),
        "composeFrom": includes,
        "allSystemsResolveLocally": resolvable,
        "conceptCount": total,
        "expansionCount": exp_count,
    }


def summarize_namingsystem(ns):
    return {
        "id": ns.get("id"),
        "name": ns.get("name"),
        "kind": ns.get("kind"),
        "status": ns.get("status"),
        "uniqueIds": [
            {"type": u.get("type"), "value": u.get("value"), "preferred": u.get("preferred")}
            for u in ns.get("uniqueId", [])
        ],
    }


# --------------------------------------------------------------------------
# driver
# --------------------------------------------------------------------------

def collect_known_systems(pkg_dirs):
    """Build {CodeSystem.url -> conceptCount} across every vendored package."""
    known = {}
    for pkg_dir in pkg_dirs:
        for _name, _kind, res in load_package(pkg_dir):
            if res.get("resourceType") == "CodeSystem" and res.get("url"):
                known[res["url"]] = count_concepts(res.get("concept"))
    return known


def summarize_package(ig_name, pkg_dir, known_systems):
    manifest_path = os.path.join(pkg_dir, "package.json")
    manifest = {}
    if os.path.isfile(manifest_path):
        with open(manifest_path, encoding="utf-8") as fh:
            manifest = json.load(fh)

    out = {
        "ig": ig_name,
        "package": {
            "name": manifest.get("name"),
            "version": manifest.get("version"),
            "canonical": manifest.get("canonical"),
            "date": manifest.get("date"),
            "title": manifest.get("title"),
            "fhirVersions": manifest.get("fhirVersions"),
            "url": manifest.get("url"),
            "dependencies": manifest.get("dependencies", {}),
        },
        "structureDefinitions": [],
        "codeSystems": [],
        "valueSets": [],
        "namingSystems": [],
        "capabilityStatements": [],
        "examples": [],
    }

    counts = Counter()
    for name, kind, res in load_package(pkg_dir):
        rt = res.get("resourceType")
        counts[rt] += 1
        if kind == "example":
            out["examples"].append(
                {"file": name, "resourceType": rt, "id": res.get("id"),
                 "profiles": res.get("meta", {}).get("profile", [])}
            )
            continue
        if rt == "StructureDefinition":
            out["structureDefinitions"].append(summarize_structuredefinition(res))
        elif rt == "CodeSystem":
            out["codeSystems"].append(summarize_codesystem(res))
        elif rt == "ValueSet":
            out["valueSets"].append(summarize_valueset(res, known_systems))
        elif rt == "NamingSystem":
            out["namingSystems"].append(summarize_namingsystem(res))
        elif rt == "CapabilityStatement":
            out["capabilityStatements"].append({
                "id": res.get("id"),
                "url": res.get("url"),
                "kind": res.get("kind"),
                "fhirVersion": res.get("fhirVersion"),
                "format": res.get("format"),
                "rest": [
                    {
                        "mode": r.get("mode"),
                        "resources": [
                            {
                                "type": x.get("type"),
                                "profile": x.get("profile"),
                                "supportedProfile": x.get("supportedProfile", []),
                                "interactions": [
                                    f"{i.get('code')}"
                                    + (
                                        f" ({i['extension'][0]['valueCode']})"
                                        if i.get("extension") else ""
                                    )
                                    for i in x.get("interaction", [])
                                ],
                                "searchParams": [
                                    s.get("name") for s in x.get("searchParam", [])
                                ],
                                "operations": [
                                    o.get("name") for o in x.get("operation", [])
                                ],
                            }
                            for x in r.get("resource", [])
                        ],
                        "operations": [o.get("name") for o in r.get("operation", [])],
                    }
                    for r in res.get("rest", [])
                ],
            })

    # stable ordering so upgrades diff cleanly
    out["structureDefinitions"].sort(key=lambda x: (x.get("id") or ""))
    out["codeSystems"].sort(key=lambda x: (x.get("url") or ""))
    out["valueSets"].sort(key=lambda x: (x.get("url") or ""))
    out["namingSystems"].sort(key=lambda x: (x.get("id") or ""))
    out["examples"].sort(key=lambda x: x["file"])

    out["counts"] = dict(sorted(counts.items()))
    out["stats"] = {
        "profiles": sum(
            1 for s in out["structureDefinitions"]
            if s["derivation"] == "constraint" and s["kind"] != "logical"
        ),
        "extensions": sum(
            1 for s in out["structureDefinitions"] if s["type"] == "Extension"
        ),
        "logicalModels": sum(
            1 for s in out["structureDefinitions"] if s["kind"] == "logical"
        ),
        "bindings": sum(len(s["bindings"]) for s in out["structureDefinitions"]),
        "valueSetsWithUnresolvableSystems": sorted(
            v["url"] for v in out["valueSets"] if not v["allSystemsResolveLocally"]
        ),
    }
    return out


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(here)
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--packages", default=os.path.join(root, "packages"))
    ap.add_argument("--out", default=os.path.join(root, "extract"))
    args = ap.parse_args()

    igs = sorted(
        d for d in os.listdir(args.packages)
        if os.path.isdir(os.path.join(args.packages, d, "package"))
    )
    if not igs:
        print(f"no packages found under {args.packages}", file=sys.stderr)
        return 1

    pkg_dirs = [os.path.join(args.packages, ig, "package") for ig in igs]
    print("indexing code systems across all packages ...")
    known_systems = collect_known_systems(pkg_dirs)
    print(f"  {len(known_systems)} distinct CodeSystem canonicals vendored")

    os.makedirs(args.out, exist_ok=True)
    for ig, pkg_dir in zip(igs, pkg_dirs):
        summary = summarize_package(ig, pkg_dir, known_systems)
        dest = os.path.join(args.out, f"{ig}-summary.json")
        with open(dest, "w", encoding="utf-8") as fh:
            json.dump(summary, fh, indent=2, sort_keys=False)
            fh.write("\n")
        s = summary["stats"]
        print(
            f"{ig:10s} {summary['package']['name']}@{summary['package']['version']}"
            f"  profiles={s['profiles']} ext={s['extensions']} logical={s['logicalModels']}"
            f"  bindings={s['bindings']} VS={len(summary['valueSets'])}"
            f" CS={len(summary['codeSystems'])} examples={len(summary['examples'])}"
            f" -> {os.path.relpath(dest, root)}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
