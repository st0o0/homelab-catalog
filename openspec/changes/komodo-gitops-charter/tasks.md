## 1. ResourceSync layer

- [x] 1.0 ~~Create `komodo/hosts/<host>/` for each of the 9 live hosts~~ — **manual follow-up required**: needs real `host_ip` values and the user's local sops/age key via `just secrets <hostname>` per host; not something that can be automated here
- [x] 1.1 Create `komodo/resources/servers.toml` declaring all 9 hosts per the design.md inventory table
- [x] 1.2 Create `komodo/resources/variables.toml` with shared non-secret variables (timezone, image tags, container name conventions per `README.md` Guidelines)
- [x] 1.3 Create `komodo/resources/stacks.toml` assigning every existing `stacks/<service>/` (except `stacks/dockhand/` and `stacks/hawser/`, both removed — see §3; and `stacks/komodo/`/`stacks/komodo-periphery/`, deliberately excluded — see design.md) to a server per the design.md inventory table; leave `backrest` as a commented placeholder; use `[[SECRET_NAME]]` references for secret-backed env values
- [ ] 1.4 Point a Komodo ResourceSync resource at `komodo/resources/` and confirm a dry-run/preview shows the expected set of stacks and servers with no unresolved references — **manual follow-up**: requires a running Komodo Core and the secrets from 1.0 to be populated first

## 2. Verify Komodo core stacks

- [x] 2.1 Verify `stacks/komodo/compose.yml` and `.env.example` are complete and deploy cleanly (Core + MongoDB + local Periphery) — reviewed statically: complete, required vars guarded
- [x] 2.2 Verify `stacks/komodo-periphery/compose.yml` and `.env.example` are complete and deploy cleanly on a remote host — reviewed statically: complete
- [ ] 2.3 Confirm the ResourceSync from task 1.4 actually applies successfully against real hosts (not just preview) for at least one stack — **manual follow-up**: needs real host access

## 3. Remove Dockhand catalog path

- [x] 3.1 Delete `templates/`, `scripts/build.ps1`, `stacks/dockhand/`, `stacks/hawser/`
- [x] 3.2 Delete `docs/` (VitePress site)
- [x] 3.3 Remove the `publish-catalog`, `promote-stable`, `deploy-pages` jobs from `release-please.yml`; rewrite `validate.yml` to validate `stacks/**` via `just lint-compose` instead of the removed catalog build
- [ ] 3.4 Remove or repoint GitHub Pages settings so the repo no longer expects a `github-pages` deployment — **manual follow-up**: requires GitHub repo admin access
- [ ] 3.5 Delete the `stable` branch (confirm no other consumer relies on it first) — **manual follow-up**: destructive, requires explicit confirmation at execution time
- [x] 3.6 Update `release-please-config.json` component name away from `catalog` (renamed to `homelab-catalog`)

## 4. Confirm no dangling references

- [x] 4.1 Searched the repo for remaining mentions of Dockhand, hawser, `templates.json`, `templates/`, `stable` branch, VitePress outside of `CHANGELOG.md`/git history; updated `CONTRIBUTING.md` (full rewrite for stacks/), `stacks/bifrost/README.md`, `stacks/observability/README.md`, `justfile` (removed `build`/`validate` recipes)
- [x] 4.2 Removed unused `docs:*` scripts from `package.json` (no VitePress devDependency existed to remove — CI installed it via `npx`)

## 5. Rewrite charter documentation

- [x] 5.1 Rewrote `README.md` to state the repo's purpose as a Komodo GitOps monorepo
- [x] 5.2 Updated `ROADMAP.md`: removed §9, marked §1 and §8 done (except the two items that need a live Komodo instance), dropped hawser from §5
- [x] 5.3 Automated validation replaced: `validate.yml` now runs `just lint-compose` against `stacks/**` — no gap left to document

## Manual follow-ups (cannot be completed from this environment)

- 1.0 — populate real per-host secrets via `just secrets <hostname>` for all 9 hosts
- 1.4 / 2.3 — point a live Komodo Core at this repo's `komodo/resources/` and verify the sync
- 3.4 — GitHub Pages settings (repo admin UI)
- 3.5 — delete the `stable` branch (confirm nothing else consumes it first)
