#!/usr/bin/env bash
# Usage: main.sh <env>
#
# Everything permanent in one environment, standing in for main.bicep. Run by 9 · Infra.
#   staging: main data, the production slot, the registry, LOCKS on main data
#   prod:    the same, plus the preprod slot and its data, and LOCKS on everything
# Plus the dashboard and the four Shopify app records. Safe to run again: it writes settings and
# creates what is missing, but never touches code already deployed to a slot.
set -euo pipefail
cd "$(dirname "$0")/.."

env=$1
root="azure/$env"
mkdir -p "$root/registry"

bash infrastructure/data.sh "$env"

if [[ $env == staging ]]; then
  bash infrastructure/settings.sh staging production staging
  # Stands in for CanNotDelete locks on main data. Real locks are enforced by Azure; this one only
  # by slot/down reading it (see README).
  printf '%s\n' data/cosmos/ConsentSherpa.json data/sql/sqldb-csherpa-staging.json \
    data/queues/cookie-scan-jobs.json data/queues/translations-publish.json \
    data/queues/shopify-webhooks.json slots/production >"$root/LOCKS"
else
  bash infrastructure/data.sh prod preprod
  bash infrastructure/settings.sh prod production prod
  bash infrastructure/settings.sh prod preprod preprod
  echo '*' >"$root/LOCKS"
fi

mkdir -p azure/shopify
for app in staging pr preprod prod; do
  [[ -f azure/shopify/$app.json ]] || jq -n --arg app "$app" '{app: $app, pointsAt: null}' >"azure/shopify/$app.json"
done

cp infrastructure/dashboard.html azure/index.html
touch azure/.nojekyll
