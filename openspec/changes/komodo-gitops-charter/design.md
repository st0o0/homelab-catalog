## Context

See proposal.md - Why. Concretely, today's tree has two coexisting deploy paths and their CI:

- `validate.yml` runs `scripts/build.ps1` on any push touching `templates/**` or `stacks/**`
- `release-please.yml` releases a single root "catalog" component, then chains three jobs: `publish-catalog` (rebuilds `templates.json`, attaches to the GitHub Release), `promote-stable` (force-pushes the `stable` branch to the release tag — exists so non-browser consumers can `curl` a stable URL), `deploy-pages` (builds the VitePress site in `docs/` with `templates.json` as a static asset, deploys to GitHub Pages)
- `komodo/` already has a working secrets layer (`secrets.sops.yaml`, `hosts/<host>/secrets.sops.yaml`, `decrypt.sh`) but no ResourceSync declarations — nothing yet tells Komodo which stacks go where
- `stacks/hawser/` (`ghcr.io/finsys/hawser`) is a remote-management agent that reports to `DOCKHAND_SERVER_URL` — it is Dockhand-only infrastructure, not independent monitoring, discovered via a live inventory of the 9 real hosts (see Decisions)
- Live inventory (pasted by the user from a `docker compose ls`-style report across all 9 hosts) is the source of truth for host names and current stack placement, since `komodo/hosts/` only has the per-host secrets template today, no real host directories yet

## Goals / Non-Goals

**Goals:**
- One deployment mechanism, stated as such in README.md
- `komodo/resources/` fully declares the ResourceSync layer (servers, stack-to-server assignment, shared variables)
- All Dockhand-only code paths and CI jobs removed, not just the UI stack

**Non-Goals:**
- Restructuring `stacks/<service>/` internals (compose/env layout stays as-is)
- Any of ROADMAP §2–§6 (CIFS volumes, media-net, Alloy refactor, compose overrides, missing config dirs) — separate work
- Assigning every currently-running-but-uncataloged service (`actualbudget`, `duplicati`, `paperless`, `pinchflat`, `uptime-kuma`, `pangolin`, standalone `tracearr`) to `stacks/` — those aren't part of this repo's catalog yet; only mapping what already has a `stacks/<service>/` entry
- Deciding a host for `backrest` — left unassigned in `stacks.toml` (commented placeholder) pending a future decision

## Decisions

**Keep `stacks/` flat and host-agnostic, reject per-host folders.**
Real-world Komodo repos (e.g. foxxmd's `stacks/<server>/<service>/` + `stacks/common/`) fold host assignment into the path. Rejected here because stacks in this repo are not host-bound — assignment can change without the stack itself changing. Encoding host in the path would force a file move for what is really a ResourceSync config edit. Host assignment lives entirely in `komodo/resources/stacks.toml`.

**Split `komodo/resources/` into `servers.toml`, `stacks.toml`, `variables.toml` rather than one `main.toml`.**
Single-file examples exist in the wild (simpler for small setups) but this repo already has ~20 stacks; one file per resource type keeps diffs scoped (adding a server doesn't touch the stack-assignment diff) and mirrors the existing `komodo/hosts/<host>/` per-host split used for secrets. Komodo's Resource Sync supports multiple files/folders under one sync path, so this doesn't cost anything mechanically.

**Remove `docs/` entirely rather than repurpose it for general repo docs.**
`docs/` (VitePress) exists solely to host `templates.json` and a catalog landing page. Keeping a Node/VitePress toolchain alive just in case general docs are wanted later isn't justified — `README.md` and `komodo/README.md` already carry the documentation this repo needs. If a docs site is wanted in the future, that's a new, separate proposal.

**Retire the `stable` branch and the release-please "catalog" component along with Dockhand.**
`promote-stable` exists only so non-browser consumers can fetch a stable `templates.json` URL — a Dockhand-catalog-only need. Once `templates.json` no longer exists, this job (and the rationale for a `stable` branch at all) goes with it. `release-please-config.json`'s `catalog` component name should be reconsidered as part of this change (e.g. rename to something identity-neutral, or keep `simple` release-type for repo-level CHANGELOG/tag purposes only — no longer tied to a "catalog").

**Remove `stacks/hawser/` alongside Dockhand rather than keep it as generic monitoring.**
`hawser`'s only integration point is `DOCKHAND_SERVER_URL`; it has no independent heartbeat/health-check surface documented anywhere in the repo, and the live inventory confirms it runs precisely on the hosts that are *not* the Dockhand host — i.e. it exists to be managed by Dockhand, not to monitor independently of it. Confirmed with the user rather than assumed. `stacks/bifrost/` is unaffected: it's a general WireGuard overlay also used by `alloy` and `backrest`'s bifrost compose overrides, not hawser-specific.

**Do not put `stacks/komodo/` or `stacks/komodo-periphery/` under Komodo's own ResourceSync management.**
Researched whether Komodo can self-update Core and Periphery: it cannot, natively. Periphery has no built-in auto-update at all (community solves it with external Ansible playbooks); Core can be redeployed through itself but that's a manual UI action, not automatic, and Core/Periphery versions must be bumped in lockstep (Core first, then every Periphery). Given there's no automation payoff, having Komodo manage its own control plane via itself is pure downside: a broken Core sync could try to redeploy the very Core that's supposed to execute it. `stacks/komodo/` and `stacks/komodo-periphery/` stay in the repo as source/documentation and are deployed and updated manually (`docker compose pull && docker compose up -d`); they are intentionally absent from `komodo/resources/stacks.toml`. Confirmed with the user.

**Real host inventory (from live `docker compose` report across all 9 hosts), confirmed with the user:**

| Host | ResourceSync-managed stacks | Notes |
|---|---|---|
| FeelsCozyMan | `homeassistant`, `vaultwarden` | Currently runs Dockhand server itself; becomes the Komodo Core host. `komodo` (Core) also runs here, deployed manually — see the ResourceSync-exclusion decision above |
| FeelsDataMan | `postgres`, `immich-postgres` | |
| FeelsNoSponsorMan | `pihole` | |
| FeelsPrivateMan | `bifrost`, `authentik` (secondary) | Live `authentik` here is `exited(3)`; the running instance is on FeelsStrongMan — treat FeelsStrongMan as primary |
| FeelsStrongMan | `arr`, `media`, `authentik`, `immich`, `mealie`, `downloader` | |
| FeelsUPSMan | `nut-upsd`, `ups-monitor` | |
| FeelsWatchMan | `observability`, `alloy` | |
| FeelsAmazingMan | (none) | Inactive/reserve host — declare as a server, assign no stacks yet |
| FeelsTestingMan | (none) | Inactive/staging host — declare as a server, assign no stacks yet |
| all except FeelsCozyMan | — | Run `komodo-periphery` manually (not ResourceSync-managed — see decision above) |

`backrest` has no confirmed host — declared in `komodo/resources/stacks.toml` as a commented-out placeholder pending a decision. `stacks/dockhand/` and `stacks/hawser/` are removed entirely, not assigned to any host.

## Risks / Trade-offs

- **[Risk]** Removing `stable` branch / release asset breaks any external consumer still pulling `templates.json` from this repo → **Mitigation**: this repo's only stated consumers are Dockhand (being removed) and the user's own hosts (moving to Komodo); confirm no other integration depends on the release asset before deleting the workflow jobs
- **[Risk]** `komodo/resources/stacks.toml` becomes a single large file assigning ~20 stacks to hosts, error-prone to hand-edit → **Mitigation**: not addressed by this change; if it becomes unwieldy, splitting `stacks.toml` further (e.g. by host) is a future, independent change
- **[Risk]** CI validation (`validate.yml`) currently also builds/checks nothing for `komodo/` — removing the catalog validation leaves stacks with no automated check at all → **Mitigation**: out of scope here, but flagged; a follow-up could add `docker compose config` validation for `stacks/**` once this change lands

## Migration Plan

1. Add `komodo/resources/{servers,stacks,variables}.toml` (additive, no removals yet) and verify Komodo picks up the sync against the current hosts in `komodo/hosts/`
2. Verify `stacks/komodo/` and `stacks/komodo-periphery/` deploy cleanly via the new ResourceSync
3. Remove `templates/`, `scripts/build.ps1`, `stacks/dockhand/`, `docs/`, and the corresponding CI jobs/workflow triggers in one change, once step 1–2 are confirmed working, so there's no window where neither path works
4. Rewrite `README.md` and `ROADMAP.md` last, once the tree matches what they describe
