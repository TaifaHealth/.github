#!/usr/bin/env bash
#
# Create and configure the Taifa Health repositories under a GitHub
# organisation. Idempotent: existing repositories are re-configured, never
# recreated, and nothing is ever deleted.
#
# GitHub has no API for creating an organisation, so create it first at
# https://github.com/account/organizations/new?plan=free then run this.
#
# Usage:
#   ./scripts/bootstrap-org.sh [org] [--dry-run] [--public] [--only <repo>]
#
# Requires: gh, authenticated with the admin:org and repo scopes.
#   gh auth refresh -h github.com -s admin:org,repo

set -euo pipefail

ORG="TaifaHealth"
DRY_RUN=0
VISIBILITY="--private"
ONLY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --public)  VISIBILITY="--public"; shift ;;
    --only)    ONLY="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    -*)        echo "unknown flag: $1" >&2; exit 2 ;;
    *)         ORG="$1"; shift ;;
  esac
done

# name|description
REPOS=(
  ".github|Taifa Health organisation profile, shared policies, and platform documentation"
  "taifa-emr|Clinical core: patient record, encounters, orders, results, prescribing"
  "taifa-hmis|Hospital operations: scheduling, queues, admissions and transfers, wards, theatre"
  "taifa-pharmacy|Dispensing, stock and expiry, formulary, procurement"
  "taifa-lab|Laboratory information system: specimens, analyzers, results"
  "taifa-radiology|Radiology information system: worklists, reporting, DICOM and PACS"
  "taifa-revenue|Billing, insurance, SHA claims, payments and reconciliation"
  "taifa-ems|Emergency medical services: dispatch console, responder app, ED handover"
  "taifa-interop|FHIR R4 facade, HL7 v2 interfaces, DHIS2 and national registry integration"
  "taifa-portal|Patient portal: appointments, results, visit history, consent"
  "taifa-health-design|Shared design system and Svelte component library"
  "taifa-health-docs|Documentation site for Taifa Health"
  "taifa-health-deploy|Infrastructure, containers, environments, backups, synthetic seed data"
  "taifa-health-sdks|Client SDKs for the Taifa Health public APIs"
)

say()  { printf '  %s\n' "$*"; }
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m  %s\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then printf '  would run: %s\n' "$*"; else "$@"; fi; }

step "Preflight"

command -v gh >/dev/null || { echo "gh is not installed: https://cli.github.com" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh is not authenticated. Run: gh auth login" >&2; exit 1; }
ok "gh authenticated as $(gh api /user --jq .login 2>/dev/null || echo unknown)"

if ! gh auth status 2>&1 | grep -q 'admin:org'; then
  warn "the admin:org scope is missing, org settings and repo creation may fail"
  say  "fix with: gh auth refresh -h github.com -s admin:org,repo"
fi

if ! gh api "/orgs/$ORG" >/dev/null 2>&1; then
  echo >&2
  echo "Organisation '$ORG' does not exist or is not visible to this account." >&2
  echo "GitHub has no API to create an organisation. Create it in the browser:" >&2
  echo "  https://github.com/account/organizations/new?plan=free" >&2
  echo "Then run this script again." >&2
  [[ $DRY_RUN -eq 1 ]] || exit 1
  warn "continuing anyway because --dry-run is set"
else
  ok "organisation $ORG found"
fi

configure_repo() {
  local repo="$1" full="$ORG/$1"

  if [[ $DRY_RUN -eq 1 ]]; then
    say "would apply merge settings, dependabot, and branch protection to $full"
    return 0
  fi

  if gh api -X PATCH "/repos/$full" \
      -F has_wiki=false \
      -F has_projects=false \
      -F allow_squash_merge=true \
      -F allow_merge_commit=false \
      -F allow_rebase_merge=false \
      -F delete_branch_on_merge=true \
      -F allow_auto_merge=true \
      -f squash_merge_commit_title=PR_TITLE \
      -f squash_merge_commit_message=PR_BODY >/dev/null 2>&1; then
    ok "$repo: merge and feature settings applied"
  else
    warn "$repo: could not apply repository settings"
  fi

  gh api -X PUT "/repos/$full/vulnerability-alerts" >/dev/null 2>&1 \
    && ok "$repo: dependabot alerts on" \
    || warn "$repo: could not enable dependabot alerts"

  gh api -X PUT "/repos/$full/automated-security-fixes" >/dev/null 2>&1 \
    && ok "$repo: automated security fixes on" \
    || warn "$repo: could not enable automated security fixes"

  # Branch protection needs a main branch to exist, and on a private
  # repository it needs a paid organisation plan. Tolerate both failures.
  if ! gh api "/repos/$full/branches/main" >/dev/null 2>&1; then
    warn "$repo: no main branch yet, protect it after the first push"
    return 0
  fi

  if gh api -X PUT "/repos/$full/branches/main/protection" --input - >/dev/null 2>&1 <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
  then
    ok "$repo: main protected"
  else
    warn "$repo: could not protect main (a private repo needs a paid org plan)"
  fi
}

step "Repositories"

created=0; existing=0
for entry in "${REPOS[@]}"; do
  name="${entry%%|*}"
  desc="${entry#*|}"
  [[ -n "$ONLY" && "$ONLY" != "$name" ]] && continue

  if gh repo view "$ORG/$name" >/dev/null 2>&1; then
    ok "$name exists"
    existing=$((existing + 1))
  else
    say "creating $name"
    if run gh repo create "$ORG/$name" $VISIBILITY --description "$desc"; then
      created=$((created + 1))
    else
      warn "$name: creation failed"
      continue
    fi
  fi
  configure_repo "$name"
done

step "Summary"
say "organisation: $ORG"
say "created: $created   already present: $existing"
[[ $DRY_RUN -eq 1 ]] && say "dry run, nothing was changed"

cat <<EOF

Next:
  1. Push this repository so the org profile goes live:
       git init && git add -A && git commit -m "chore: organisation scaffold"
       git branch -M main
       git remote add origin git@github.com:$ORG/.github.git
       git push -u origin main
  2. Confirm the profile renders at https://github.com/$ORG
  3. Set org defaults in settings: require 2FA for all members, restrict
     repository creation to owners, and set the default branch name to main.
  4. Create teams and assign CODEOWNERS: platform, clinical, integrations.
  5. Name the clinical safety officer and the data protection officer in
     GOVERNANCE.md, then open the hazard log.
EOF
