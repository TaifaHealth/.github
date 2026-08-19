#!/usr/bin/env bash
# Run the official HL7 FHIR validator against a resource or Bundle using the
# VENDORED Kenyan IGs as the source of truth for profiles and terminology.
#
#   ig/tools/validate.sh [options] <file.json> [more.json ...]
#
# Options:
#   -p, --profile URL   Assert the instance(s) conform to this profile canonical.
#                       May be repeated. When omitted the validator uses
#                       meta.profile on each instance.
#   -t, --tx URL        Terminology server ("n/a" disables). Default: n/a.
#                       The Kenyan IGs bind Required to code systems that are
#                       not fully resolvable (see ig/CONFORMANCE_RULES.md,
#                       "Upstream defects"), so the default is offline and
#                       terminology warnings are expected.
#   -o, --output FILE   Also write the validator's OperationOutcome JSON here.
#   -v, --verbose       Stream the raw validator output.
#   -h, --help          Show this help.
#
# Exit status: 0 when every file validates with no ERROR/FATAL issues, 1 otherwise.
#
# The validator jar is downloaded to ig/tools/validator_cli.jar on first use.
# It is large (~180MB) and is NOT committed; see ig/tools/.gitignore.

set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IG_ROOT="$(dirname "$TOOLS_DIR")"
PKG_ROOT="$IG_ROOT/packages"
JAR="$TOOLS_DIR/validator_cli.jar"
JAR_URL="https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar"
FHIR_VERSION="4.0.1"

# The four vendored Kenyan IGs, in dependency order (core first: the others
# reuse its code systems). Pinned by sha256 in ig/PINS.md.
KENYAN_IGS=(core kps eclaims emergency)

TX="n/a"
OUTPUT=""
VERBOSE=0
PROFILES=()
FILES=()

usage() { sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--profile) PROFILES+=("$2"); shift 2 ;;
    -t|--tx)      TX="$2"; shift 2 ;;
    -o|--output)  OUTPUT="$2"; shift 2 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    --)           shift; FILES+=("$@"); break ;;
    -*)           echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)            FILES+=("$1"); shift ;;
  esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "error: no input files given" >&2
  usage >&2
  exit 2
fi

for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { echo "error: no such file: $f" >&2; exit 2; }
done

command -v java >/dev/null 2>&1 || {
  echo "error: java not found on PATH (Java 17+ required)" >&2; exit 2; }

if [[ ! -f "$JAR" ]]; then
  echo "==> validator_cli.jar not present, downloading (~180MB) ..."
  curl -fsSL --max-time 600 -o "$JAR.part" "$JAR_URL"
  mv "$JAR.part" "$JAR"
fi

# Assemble -ig arguments from the vendored packages. Each package directory
# contains the standard NPM-style package/ subfolder the validator expects.
IG_ARGS=()
for ig in "${KENYAN_IGS[@]}"; do
  d="$PKG_ROOT/$ig/package"
  if [[ -d "$d" ]]; then
    IG_ARGS+=(-ig "$d")
  else
    echo "error: vendored package missing: $d" >&2
    echo "       run: tar -xzf $IG_ROOT/dist/$ig.tgz -C $PKG_ROOT/$ig" >&2
    exit 2
  fi
done

PROFILE_ARGS=()
for p in "${PROFILES[@]+"${PROFILES[@]}"}"; do
  PROFILE_ARGS+=(-profile "$p")
done

# The validator infers the OperationOutcome format from the file extension,
# so the output path must end in .json or it silently emits XML.
TMPDIR_RUN="$(mktemp -d -t fhirvalidate)"
RAW="$TMPDIR_RUN/validator.log"
OUTCOME="$TMPDIR_RUN/outcome.json"
trap 'rm -rf "$TMPDIR_RUN"' EXIT

echo "==> HL7 FHIR validator, FHIR $FHIR_VERSION"
echo "    IGs (vendored, Kenyan):"
for ig in "${KENYAN_IGS[@]}"; do
  v=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(d['name']+'@'+d['version'])" \
      "$PKG_ROOT/$ig/package/package.json" 2>/dev/null || echo "$ig")
  echo "      - $v"
done
echo "    terminology server: $TX"
echo "    files: ${FILES[*]}"
echo

set +e
java -jar "$JAR" \
  "${FILES[@]}" \
  -version "$FHIR_VERSION" \
  "${IG_ARGS[@]}" \
  ${PROFILE_ARGS[@]+"${PROFILE_ARGS[@]}"} \
  -tx "$TX" \
  -output "$OUTCOME" \
  >"$RAW" 2>&1
JAVA_RC=$?
set -e

if [[ $VERBOSE -eq 1 ]]; then
  cat "$RAW"
fi

if [[ -n "$OUTPUT" ]]; then
  mkdir -p "$(dirname "$OUTPUT")"
  cp "$OUTCOME" "$OUTPUT" 2>/dev/null || true
fi

if [[ ! -s "$OUTCOME" ]]; then
  echo "FAIL: validator produced no OperationOutcome (exit $JAVA_RC)"
  echo "----- validator output -----"
  tail -n 60 "$RAW"
  exit 1
fi

# Summarise the OperationOutcome(s): errors and fatals fail the run, warnings
# and information are reported but tolerated.
python3 - "$OUTCOME" <<'PYEOF'
import json, sys, collections

with open(sys.argv[1], encoding="utf-8") as fh:
    doc = json.load(fh)

# A single file yields an OperationOutcome; several yield a Bundle of them.
outcomes = []
if doc.get("resourceType") == "Bundle":
    for e in doc.get("entry", []):
        r = e.get("resource")
        if r and r.get("resourceType") == "OperationOutcome":
            outcomes.append(r)
else:
    outcomes.append(doc)

overall_fail = False
for oc in outcomes:
    src = "(unknown)"
    for ext in oc.get("extension", []):
        if ext.get("url", "").endswith("source") or "file" in ext.get("url", "").lower():
            src = ext.get("valueString") or ext.get("valueUri") or src
    counts = collections.Counter()
    lines = collections.defaultdict(list)
    for issue in oc.get("issue", []):
        sev = issue.get("severity", "information")
        counts[sev] += 1
        loc = ", ".join(issue.get("expression") or issue.get("location") or [])
        txt = (issue.get("details", {}) or {}).get("text") or issue.get("diagnostics") or ""
        lines[sev].append(f"      [{loc}] {txt}")

    errs = counts["error"] + counts["fatal"]
    status = "FAIL" if errs else "PASS"
    if errs:
        overall_fail = True
    print(f"  {status}  {src}")
    print(f"      errors={counts['error']} fatal={counts['fatal']} "
          f"warnings={counts['warning']} info={counts['information']}")
    for sev in ("fatal", "error", "warning"):
        for line in lines[sev][:40]:
            print(f"    {sev}:{line}")
        if len(lines[sev]) > 40:
            print(f"    {sev}: ... and {len(lines[sev]) - 40} more")
    print()

print("RESULT:", "FAIL" if overall_fail else "PASS")
sys.exit(1 if overall_fail else 0)
PYEOF
