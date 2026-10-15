#!/usr/bin/env bash
# Usage: data.sh <env> [name]
#
# One data set, standing in for data.bicep: a Cosmos database, a SQL database and three queues,
# each a JSON file under azure/<env>/data/. Main data has no name; any other set appends --<name>.
# Creates what is missing and leaves what exists alone, like an incremental deployment.
set -euo pipefail

env=$1
name=${2:-}
suffix=${name:+--$name}
root="azure/$env/data"

mkdir -p "$root/cosmos" "$root/sql" "$root/queues"

create() {
  [[ -f $1 ]] && return 0
  jq -n --arg name "$(basename "$1" .json)" --arg at "$(date -u +%FT%TZ)" \
    '{name: $name, createdAt: $at, items: []}' >"$1"
  echo "created ${1#azure/}"
}

create "$root/cosmos/ConsentSherpa$suffix.json"
create "$root/sql/sqldb-csherpa-$env$suffix.json"
for queue in cookie-scan-jobs translations-publish shopify-webhooks; do
  create "$root/queues/$queue$suffix.json"
done
