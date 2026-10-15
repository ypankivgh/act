#!/usr/bin/env bash
# Usage: settings.sh <env> <slot> <shopify app>
#
# A slot's settings, standing in for settings.bicep: which data set and which Shopify app the slot
# uses. Written to azure/<env>/slots/<slot>/settings.json, which a swap never moves (sticky), so
# only code changes slot. The production slot uses main data (no suffix); every other slot uses the
# data set of its own name.
set -euo pipefail

env=$1
slot=$2
app=$3
suffix=""
if [[ $slot != production ]]; then suffix="--$slot"; fi

mkdir -p "azure/$env/slots/$slot"
jq -n --arg env "$env" --arg slot "$slot" --arg app "$app" --arg s "$suffix" '{
  environment: $env,
  slot: $slot,
  cosmosDatabase: ("ConsentSherpa" + $s),
  sqlDatabase: ("sqldb-csherpa-" + $env + $s),
  scanQueue: ("cookie-scan-jobs" + $s),
  shopifyApp: $app
}' >"azure/$env/slots/$slot/settings.json"
