#!/usr/bin/env bash
# The "test suite". Break it on purpose in a PR (say, remove __COMMIT__ from web/index.html) to
# watch the build go red and nothing after it run.
set -euo pipefail
cd "$(dirname "$0")"

jq -e . api/version.json >/dev/null || { echo "api/version.json is not valid JSON"; exit 1; }
grep -q __COMMIT__ api/version.json || { echo "api/version.json lost its __COMMIT__ placeholder"; exit 1; }
grep -q __COMMIT__ web/index.html || { echo "web/index.html lost its __COMMIT__ placeholder"; exit 1; }
echo "tests passed"
