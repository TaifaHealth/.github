#!/usr/bin/env bash
# Re-download the vendored Kenyan FHIR IG packages, verify them against the
# sha256 pins in ig/PINS.md, and re-extract into ig/packages/.
#
#   ig/tools/fetch.sh            verify the current pins still match upstream
#   ig/tools/fetch.sh --update   accept whatever upstream now serves and
#                                re-extract (then re-run extract_ig.py and
#                                review the diff before committing)
#
# These are continuous-integration builds off feature branches, not published
# releases: upstream rewrites them in place. A pin mismatch is expected over
# time and is the signal to review, not an error to paper over.

set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IG_ROOT="$(dirname "$TOOLS_DIR")"
DIST="$IG_ROOT/dist"
PKG="$IG_ROOT/packages"

UPDATE=0
[[ "${1:-}" == "--update" ]] && UPDATE=1

declare -a NAMES=(kps core eclaims emergency)
declare -a URLS=(
  "https://build.fhir.org/ig/IntelliSOFT-Consulting/Kenya-Patient-Summary-FHIR-IG/branches/compositionResource/package.tgz"
  "https://build.fhir.org/ig/IntelliSOFT-Consulting/Kenya-core-FHIR-IG/branches/profileValidation/package.tgz"
  "https://build.fhir.org/ig/IntelliSOFT-Consulting/Kenya-eClaims-FHIR-IG/branches/canonicalUpdate/package.tgz"
  "https://build.fhir.org/ig/IntelliSOFT-Consulting/Kenya-Emmergency-FHIR-IG/branches/removedUnusedProfiles/package.tgz"
)

mkdir -p "$DIST" "$PKG"
rc=0
for i in "${!NAMES[@]}"; do
  n="${NAMES[$i]}"; u="${URLS[$i]}"
  echo "==> $n"
  curl -fsSL --max-time 180 -o "$DIST/$n.tgz.new" "$u"
  new=$(shasum -a 256 "$DIST/$n.tgz.new" | cut -d' ' -f1)
  old=""
  [[ -f "$DIST/$n.tgz" ]] && old=$(shasum -a 256 "$DIST/$n.tgz" | cut -d' ' -f1)

  if [[ "$new" == "$old" ]]; then
    echo "    pin OK  $new"
    rm -f "$DIST/$n.tgz.new"
    continue
  fi

  echo "    PIN CHANGED"
  echo "      pinned:  ${old:-<none>}"
  echo "      upstream: $new"
  if [[ $UPDATE -eq 1 ]]; then
    mv "$DIST/$n.tgz.new" "$DIST/$n.tgz"
    rm -rf "${PKG:?}/$n"
    mkdir -p "$PKG/$n"
    tar -xzf "$DIST/$n.tgz" -C "$PKG/$n"
    echo "    re-extracted"
  else
    rm -f "$DIST/$n.tgz.new"
    rc=1
  fi
done

if [[ $UPDATE -eq 1 ]]; then
  echo
  echo "==> re-extracting conformance facts"
  python3 "$TOOLS_DIR/extract_ig.py"
  echo
  echo "Now update ig/PINS.md with the new sha256 values and review the diff"
  echo "under ig/packages/ and ig/extract/ before committing."
else
  [[ $rc -ne 0 ]] && echo && echo "Pins differ from upstream. Re-run with --update to adopt."
fi
exit $rc
