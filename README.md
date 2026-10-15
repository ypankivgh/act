# Learning: the monorepo proposal on GitHub Pages

The `monorepo/` proposal, adapted to run for free in a public repository
([ypankivgh/act](https://github.com/ypankivgh/act)) so you can watch it in the GitHub UI. Same six
workflows, same actions, same WHEN / DOES / NEVER headers; Azure is replaced by the `_azure_`
branch, which GitHub Pages serves.

## Set up (once)

1. Copy everything in this folder (including `.github/`) to the root of the repo's `main` and push.
   Workflows you run by hand only appear once they are on the default branch.
2. **Settings → Pages:** Source "Deploy from a branch", branch `_azure_`, folder `/ (root)`.
3. **Settings → Environments** (optional, to see approvals): open `production` after its first run,
   or create it now, add yourself as a required reviewer, and restrict it to `main`. Do the same
   for `preprod` if Release should wait too.
4. **Actions → 9 · Infra:** run with `env: staging`, read the summary, run again with `apply`.
   Then the same for `prod`. Open `https://ypankivgh.github.io/act/`: the dashboard.

## Things to try

| Try | Watch |
|---|---|
| **1 · Local** with `ypankiv`, then `refresh`, then `down` | data files `--ypankiv` appear, get recreated, disappear on the dashboard |
| Open a PR that edits `app/web/index.html` | PR checks run as parallel jobs; the PR shows "deployed to pr-preview" with a View button; a comment with the link; `shopify/pr.json` points at `pr-<N>` |
| Push again to the PR | same slot, redeployed; its data files untouched |
| Change something outside `app/worker/` | **build-worker** says "Reusing" and finishes in seconds |
| Change `app/worker/worker.txt` | **build-worker** "builds" for 30 s: a new image in the registry |
| Remove `__COMMIT__` from `app/web/index.html` in a PR | build goes red; deploy never runs |
| Open two PRs | each gets its own slot; `shopify/pr.json` points at whichever deployed last |
| Close a PR | its slot and `--pr-<N>` data disappear; staging's main data stays |
| Merge | **3 · Main** deploys staging production; Deployments tab shows `staging` |
| **4 · Release**, then **5 · Swap** | preprod gets the version, then production; each slot's `settings.json` stays put while the code moves (compare the two slot pages before and after) |
| **5 · Swap** again | rollback: the previous commit is live again |
| A hotfix: branch `hotfix/x` from a `prod-*` tag, fix it via a PR into that branch, **4 · Release** with `ref: hotfix/x` | the release ships the hotfix commit, not main's |
| **4 · Release** with a branch that is neither `main` nor `hotfix/*` | **check** refuses it |
| **4 · Release** started from a branch other than main | every job is skipped |

## Real thing vs simulation

| Real (monorepo proposal) | Here |
|---|---|
| Resource group `rg-csherpa-<env>` | folder `<env>/` on `_azure_` |
| `azure/login` as an identity with rights on one group | checkout of `_azure_` + job permission `contents: write` |
| Calls to Azure | `azure/save`: commit and push `_azure_` |
| `main.bicep`, `data.bicep`, `settings.bicep` | `infrastructure/main.sh`, `data.sh`, `settings.sh` |
| App Service slot | folder `<env>/slots/<slot>/` |
| Sticky slot settings | `settings.json`, which deploy and swap never move |
| Cosmos database, SQL database, queues | JSON files under `<env>/data/`, named `--<slot>` like the real ones |
| Container registry image, reused when the worker is unchanged | `<env>/registry/worker-<tag>.txt`; a 30 s sleep stands in for the build |
| Swap with preview + health check | a file check on preprod, then the two slots' files trade places |
| Commit tag on the slot resource | `commit.txt`, which moves with the code |
| Shopify app deploy | `shopify/<app>.json` records where the app points |
| `CanNotDelete` locks, enforced by Azure | `LOCKS` file, enforced only by `slot/down` reading it |
| Prod identity trusts only `main` | `if: github.ref == 'refs/heads/main'` + environment `production` (add a reviewer) |

Every workflow has the same jobs, and every action the same named steps, as `monorepo/`, with one
exception: `slot/up` leaves out two Azure-only steps (choosing copy or skip for a new SQL database,
and reading the worker's current image), which mean nothing here.

What the simulation cannot show: **real enforcement.** Here every job with `contents: write` could
write anything on `_azure_`; the protection is only the code's own checks. In Azure, the staging
identity has no rights in prod and locks refuse deletes whatever the code does.
