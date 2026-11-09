#!/usr/bin/env bash
# Shows when a BigQuery table expires. It reads metadata only and changes nothing.
#
#   scripts/check_raw_table.sh [warn-days] [dataset.table]
#
# Defaults: warn 7 days ahead, table raw.iowa_sales.
# Exit codes: 0 = ok, 1 = expires within warn-days, 2 = the check itself failed.
set -u

project=iowa-liquor-lab
warn_days=${1:-7}
table=${2:-raw.iowa_sales}

case "$warn_days" in
  '' | *[!0-9]*) echo "warn-days must be a whole number, got: $warn_days"; exit 2 ;;
esac
command -v bq > /dev/null || { echo "bq not found: install the Google Cloud CLI."; exit 2; }
cd "$(git rev-parse --show-toplevel)" || exit 2

if ! meta=$(bq --project_id="$project" --format=json show "$project:$table" 2>&1); then
  echo "Could not read $project:$table"
  printf '%s\n' "$meta"
  exit 2
fi

# Exits 10 for a warning, so a Python or uv failure can't be mistaken for one.
parse='
import datetime as dt, json, sys
name, warn_days = sys.argv[1], int(sys.argv[2])
try:
    expiration = json.load(sys.stdin).get("expirationTime")
    if expiration is None:
        print(f"{name}: no expiration set")
        sys.exit(0)
    expires = dt.datetime.fromtimestamp(int(expiration) / 1000, dt.timezone.utc)
except (ValueError, TypeError, AttributeError) as error:
    print(f"Could not parse the table metadata: {error}")
    sys.exit(2)
days_left = (expires - dt.datetime.now(dt.timezone.utc)).days
print(f"{name}: expires {expires:%Y-%m-%d %H:%M} UTC ({days_left} days left)")
if days_left < warn_days:
    print(f"WARNING: less than {warn_days} days left")
    sys.exit(10)
'

printf '%s' "$meta" | uv run --quiet python -I -c "$parse" "$project:$table" "$warn_days"
case $? in
  0) exit 0 ;;
  10) exit 1 ;;
  *) exit 2 ;;
esac
