#!/usr/bin/env bash
# Audits every commit in this repo for secrets, tokens and personal emails.
# Run it from anywhere in the repo before a public release:
#
#   scripts/audit_history.sh [email-to-search-for]
#
# The email is optional and passed as an argument, or through the AUDIT_EMAIL
# environment variable, so it is never stored here.
# Exit codes: 0 = clean, 1 = something found, 2 = the audit itself failed.
# It recognizes known secret formats, so a clean result is not a guarantee.
set -u

cd "$(git rev-parse --show-toplevel)" || exit 2
email=${1:-${AUDIT_EMAIL:-}}
found=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

revs=()
while IFS= read -r rev; do revs+=("$rev"); done < <(git rev-list --all)
[ "${#revs[@]}" -gt 0 ] || { echo "No commits to audit."; exit 2; }

echo "=== Scope: ${#revs[@]} commits ==="
for rev in "${revs[@]}"; do
  git cat-file -e "$rev^{commit}" || { echo "Invalid commit: $rev"; exit 2; }
  echo "  ${rev:0:7} $(git log -1 --format=%s "$rev")"
done

# Prints the number of lines matching a regex across all commits.
count_matches() {
  local out rc
  out=$(git grep -I -i -E -e "$1" "${revs[@]}" --)
  rc=$?
  [ "$rc" -le 1 ] || { echo "git grep failed (rc=$rc)" >&2; exit 2; }
  printf '%s' "$out" | grep -c . || true
}

scan() {
  local n
  n=$(count_matches "$2") || exit 2
  printf '%-36s %s\n' "$1" "$n"
  if [ "$n" -gt 0 ]; then
    found=1
    # Shows where it matched without printing the matched value.
    git grep -I -i -l -E -e "$2" "${revs[@]}" -- | sed -E 's/^([0-9a-f]{7})[0-9a-f]{33}:/    \1 /'
  fi
}

echo "=== Control: the search must find a known string ==="
known=$(count_matches 'dependencies') || exit 2
[ "$known" -gt 0 ] || { echo "Control failed: pattern search found nothing."; exit 2; }
echo "ok ($known matches)"

echo "=== Secret patterns, all commits ==="
scan "private key block" 'BEGIN [A-Z ]*PRIVATE KEY'
scan "GCP service account JSON" '"private_key(_id)?"[[:space:]]*:|"type":[[:space:]]*"service_account"|"client_email"[[:space:]]*:'
scan "Google API key" 'AIza[0-9A-Za-z_-]{35}'
scan "Google OAuth token" 'ya29\.[0-9A-Za-z_-]+'
scan "GitHub token" 'gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}'
scan "AWS access key" '(AKIA|ASIA)[0-9A-Z]{16}'
scan "Slack token" 'xox[abprs]-[0-9A-Za-z-]{10,}'
scan "Anthropic/OpenAI key" 'sk-(ant-)?[A-Za-z0-9_-]{20,}'
scan "JWT" 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
scan "password/secret/token assignment" "(password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token)[[:space:]]*[:=][[:space:]]*[\"']?[^[:space:]\"']{6,}"
scan "URL with embedded login" '[a-z]+://[^/[:space:]:]+:[^/[:space:]@]+@'
scan "any Gmail address" '@gmail\.com'
scan "home-folder path" '/Users/[a-z]|/home/[a-z]'
scan "international phone number" '\+[0-9]{2}[ -]?[0-9]{3}[ -]?[0-9]{3}[ -]?[0-9]{3}'

echo "=== Commit metadata and messages ==="
git log --all --format='author: %an <%ae>%ncommitter: %cn <%ce>' | sort | uniq -c
metadata=$(git log --all --format=fuller)
gmail_in_log=$(printf '%s\n' "$metadata" | grep -ci '@gmail\.com')
echo "Gmail addresses in metadata: $gmail_in_log"
[ "$gmail_in_log" -eq 0 ] || found=1

if [ -n "$email" ]; then
  echo "=== Given email ==="
  scan "given email in files" "$(printf '%s' "$email" | sed 's/[][\.*^$+?(){}|]/\\&/g')"
  email_in_log=$(printf '%s\n' "$metadata" | grep -ciF -- "$email")
  echo "given email in metadata: $email_in_log"
  [ "$email_in_log" -eq 0 ] || found=1
else
  echo "=== Given email: skipped (no argument) ==="
fi

echo "=== Paths ever committed ==="
paths=$(git log --all --name-only --format= | sort -u)
printf '%s\n' "$paths" | sed 's/^/  /'
risky=$(printf '%s\n' "$paths" | grep -iE '(^|/)\.env|\.pem$|\.p12$|\.key$|credential|service.?account|keyfile|profiles\.yml|settings\.local|(^|/)\.venv/')
if [ -n "$risky" ]; then
  found=1
  echo "Credential-looking paths:"
  printf '%s\n' "$risky" | sed 's/^/  /'
else
  echo "Credential-looking paths: 0"
fi

summarize='
import collections, json, sys
results = json.load(open(sys.argv[1]))["results"]
hits = collections.Counter((f, x["type"]) for f, v in results.items() for x in v)
for (name, kind), n in sorted(hits.items()):
    print(f"    {n} {name} - {kind}")
sys.exit(1 if hits else 0)
'

echo "=== detect-secrets control: must flag a fake key ==="
mkdir "$tmp/control"
# Built at runtime so this script does not contain a key-shaped string.
printf 'aws_access_key_id = %s%s\n' 'AKIA' 'IOSFODNN7EXAMPLE' > "$tmp/control/fake.txt"
(cd "$tmp/control" && uvx --quiet detect-secrets scan --all-files .) > "$tmp/control.json" || exit 2
if uv run --quiet python -I -c "$summarize" "$tmp/control.json"; then
  echo "Control failed: detect-secrets flagged nothing."
  exit 2
fi

echo "=== detect-secrets, each commit ==="
for rev in "${revs[@]}"; do
  short=${rev:0:7}
  mkdir "$tmp/$short"
  git archive "$rev" | tar -x -C "$tmp/$short" || exit 2
  (cd "$tmp/$short" && uvx --quiet detect-secrets scan --all-files .) > "$tmp/$short.json" || exit 2
  echo "  $short ($(find "$tmp/$short" -type f | wc -l | tr -d ' ') files)"
  uv run --quiet python -I -c "$summarize" "$tmp/$short.json" || found=1
done

echo
if [ "$found" -eq 0 ]; then
  echo "RESULT: clean"
else
  echo "RESULT: review the findings above"
fi
exit "$found"
