## Why

This repo has carried three overlapping identities over its history: a Dockhand template catalog (still the stated purpose in README.md), a Komodo GitOps monorepo (the direction ROADMAP.md has been pushing since the Komodo secrets work landed), and — right now — both at once, with two parallel and contradictory deploy paths live in the same tree (`templates/` → `templates.json` → Dockhand UI, and `stacks/` → Komodo ResourceSync). ROADMAP.md §9 already commits to dropping Dockhand once Komodo covers everything, but nothing states this as the repo's actual charter, and the ResourceSync layer that would let Komodo actually cover everything doesn't exist yet. This change settles the identity question once, states it as the repo's charter, and does the structural work needed to make it true.

## What Changes

- **BREAKING**: Remove the Dockhand catalog path entirely: `templates/`, `scripts/build.ps1`, `stacks/dockhand/`, and `docs/` (the VitePress site whose only purpose was publishing `templates.json`)
- **BREAKING**: Remove `stacks/hawser/` — discovered during implementation to be a Dockhand-only companion agent (`ghcr.io/finsys/hawser`, reports to `DOCKHAND_SERVER_URL`), not an independent monitoring tool; it has no purpose once Dockhand is gone and is deployed on every host except the Dockhand host itself per the live inventory
- **BREAKING**: Remove the `templates.json` release-please "catalog" release track and its CI jobs (build/validate templates, publish to GitHub Pages, attach release asset)
- Add the Komodo ResourceSync declarative layer under `komodo/resources/` (server definitions, per-stack host assignment, shared variables) — this was ROADMAP §8, previously unstarted
- Verify `stacks/komodo/` and `stacks/komodo-periphery/` are complete (ROADMAP §1). Deliberately **excluded** from ResourceSync management: Komodo has no native self-update for Core or Periphery, so both remain manually deployed/updated to avoid Komodo managing its own control plane through itself
- Rewrite `README.md` to state the repo's actual charter: a Komodo GitOps monorepo for homelab docker-compose stacks, where `stacks/` defines *what* is deployable (host-agnostic) and `komodo/resources/` defines *where* and *with what values* (host assignment, variables), alongside the existing `komodo/` secrets layer
- Update `ROADMAP.md` to drop the now-obsolete §9 ("Remove Dockhand" becomes done-by-this-change rather than a future step) and reflect the single-identity end state

## Capabilities

### New Capabilities
- `gitops-deployment`: Komodo ResourceSync as the sole deployment mechanism — server definitions, stack-to-host assignment, and shared variables declared as TOML under `komodo/resources/`, with `stacks/<service>/` remaining the host-agnostic definition of what each stack is

### Modified Capabilities
(none — no existing `openspec/specs/` capabilities predate this change)

## Impact

- **Removed**: `templates/`, `scripts/build.ps1`, `stacks/dockhand/`, `stacks/hawser/`, `docs/`, the `templates.json` release-please release track and its CI jobs, all references to Dockhand/hawser in `README.md`/`CONTRIBUTING.md`/ROADMAP.md
- **Added**: `komodo/resources/servers.toml`, `komodo/resources/stacks.toml`, `komodo/resources/variables.toml` (exact split decided in design.md), `komodo/hosts/<host>/` directories for the 9 live hosts (currently only the template exists)
- **Changed**: `README.md` (full rewrite of stated purpose), `ROADMAP.md` (drop §9, mark this work as the resolution of §1 and §8, drop the hawser-specific parts of §5 since hawser is removed)
- **Unaffected**: `komodo/secrets.sops.yaml`, `komodo/hosts/*/secrets.sops.yaml`, `komodo/decrypt.sh`, and every `stacks/<service>/` directory other than `stacks/dockhand/` and `stacks/hawser/` — no compose files change
- **Out of scope**: ROADMAP §2 (CIFS volumes), §3 (media-net), §4 (Alloy refactor), §5 (compose override pattern), §6 (missing config dirs) — separate, already-tracked work untouched by this change
