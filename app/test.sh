#!/usr/bin/env bash
# The "test suite". Break it on purpose in a PR (say, remove __COMMIT__ from web/index.html) to
# watch the build go red and nothing after it run.
set -euo pipefail
cd "$(dirname "$0")"

for service in api func; do
  jq -e . "$service/version.json" >/dev/null || { echo "$service/version.json is not valid JSON"; exit 1; }
  grep -q __COMMIT__ "$service/version.json" || { echo "$service/version.json lost its __COMMIT__ placeholder"; exit 1; }
done
grep -q __COMMIT__ web/index.html || { echo "web/index.html lost its __COMMIT__ placeholder"; exit 1; }
echo "tests passed"
