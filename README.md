# homelab-catalog

Dockhand template catalog for homelab services. Each service is defined as an individual JSON file under `templates/` and automatically merged into a single `templates.json`, published as a [GitHub Release](https://github.com/st0o0/homelab-catalog/releases) asset via CI.

**Related repos:** [homelab-ansible](https://github.com/st0o0/homelab-ansible) (server provisioning) · [dotfiles](https://github.com/st0o0/dotfiles) (shell toolchain)

## Quick Start

### 1. Connect to Dockhand

In the Dockhand UI go to **Templates → Sources** and add a new source:

| Field | Value |
|---|---|
| Name | `Homelab` |
| URL | `https://raw.githubusercontent.com/st0o0/homelab-catalog/stable/templates.json` |

Dockhand fetches template sources from the browser, and GitHub Release assets don't
send an `Access-Control-Allow-Origin` header — that fetch fails with a CORS error
(`NetworkError when attempting to fetch resource`). `raw.githubusercontent.com` does
send that header, so `templates.json` is committed to the `stable` branch (fast-forwarded
to the release tag on every release) and served from there instead.

The `.../releases/latest/download/templates.json` and `.../releases/download/vX.Y.Z/templates.json`
release-asset URLs still exist for pinned downloads via `curl`/scripts, just not for
browser-based sources.

Dockhand fetches and caches the catalog for one hour. After adding the source, switch to the **Templates** tab to browse and deploy.

### 2. Deploy a Service

Click any template card to open the deploy modal. Review or adjust image, ports, volumes, and environment variables, then deploy. The container is created on whichever Docker environment is selected in the Dockhand header.

## Adding a New Template

### Create the file

Add a JSON file under `templates/<category>/` with a kebab-case filename:

```
templates/media/my-service.json
```

Minimal template for a single container:

```json
{
  "type": 1,
  "title": "My Service",
  "description": "One-line description of what it does",
  "image": "registry/image:tag",
  "categories": ["Media"],
  "ports": ["8080:8080/tcp"],
  "volumes": [
    { "bind": "/data/my-service", "container": "/config" }
  ],
  "env": [
    { "name": "TZ", "label": "Timezone", "default": "Europe/Berlin" }
  ],
  "restart_policy": "unless-stopped"
}
```

For a multi-container compose stack, use `type: 3` with a repository reference:

```json
{
  "type": 3,
  "title": "My Stack",
  "description": "Multi-container application",
  "categories": ["Productivity"],
  "repository": {
    "url": "https://github.com/user/repo",
    "stackfile": "path/to/docker-compose.yml"
  }
}
```

### Validate locally

```powershell
./scripts/build.ps1              # validate + build templates.json
./scripts/build.ps1 -ValidateOnly  # validate without writing output
```

### Commit and push

Only commit your template file — CI handles the rest. Commit messages must
follow [Conventional Commits](https://www.conventionalcommits.org/) (see
[CONTRIBUTING.md](CONTRIBUTING.md)) so [release-please](https://github.com/googleapis/release-please)
can pick it up correctly:

```bash
git add templates/media/my-service.json
git commit -m "feat(catalog): add my-service template"
git push
```

CI validates every template on each push/PR. Merging to `main` lets
release-please open (or update) a "catalog" release PR with a generated
CHANGELOG entry; merging *that* PR cuts a GitHub Release, which triggers a
second job that rebuilds `templates.json` and attaches it as a release
asset.

## Field Reference

| Field | Required | Type | Notes |
|---|---|---|---|
| `type` | yes | `1` or `3` | `1` = single container, `3` = compose stack |
| `title` | yes | string | Display name in Dockhand |
| `description` | no | string | Short description shown on the card |
| `image` | yes (type 1) | string | Docker image reference (e.g. `jellyfin/jellyfin:10.11`) |
| `logo` | no | string | URL to an icon/logo image |
| `categories` | no | string[] | Used for filtering in the Dockhand UI |
| `ports` | no | string[] | Format: `"host:container/proto"` (e.g. `"8080:8080/tcp"`) |
| `volumes` | no | object[] | `{ "bind": "/host/path", "container": "/container/path" }` |
| `env` | no | object[] | `{ "name": "VAR_NAME", "label": "Display Label", "default": "value" }` |
| `restart_policy` | no | string | Default: `unless-stopped` |
| `note` | no | string | Deployment notes (not shown in Dockhand, for documentation) |
| `repository` | yes (type 3) | object | `{ "url": "https://...", "stackfile": "docker-compose.yml" }` |

## Categories

| Category | Templates |
|---|---|
| Monitoring | Hawser, Hawser Edge, Hawser Edge + Bifrost |
| Networking | Bifrost |
| Observability | Observability (central), Observability Agent, UPS Monitor |
| Photos | Immich |

## How It Works

```
main branch                    release-please PR              GitHub Release          stable branch
┌───────────────────────┐      ┌──────────────────────┐      ┌────────────────────┐  ┌────────────────────┐
│ templates/             │ CI   │ chore(catalog): rel.  │ merge │ tag vX.Y.Z          │  │ (fast-forwarded to │
│   media/jellyfin.json  │ ───► │ CHANGELOG.md          │ ───► │ templates.json      │─►│  the tag) +         │
│   ...                  │ open │ (version bump)        │       │ (release asset)    │  │ templates.json      │
│ scripts/build.ps1      │  PR  │                       │      └────────────────────┘  │ commit              │
└───────────────────────┘      └──────────────────────┘                                └────────────────────┘
                                                                                                 │
                                                                                          Dockhand fetches
                                                                                          raw.githubusercontent.com/…/stable/templates.json
```

- **`main`** holds the source files: individual templates, the build script, CI config, and docs — never the merged `templates.json`
- Every push to `main` updates release-please's standing "catalog" release PR (CHANGELOG + version bump), it doesn't publish anything by itself
- Merging that release PR cuts the actual GitHub Release, rebuilds `templates.json`, attaches it as a release asset, and fast-forwards `stable` to the tag with `templates.json` committed on top
- The Portainer v2 template format requires a single JSON file, so the build step is necessary
- `stable` exists purely to serve `templates.json` with CORS headers via `raw.githubusercontent.com` — Dockhand (and any other browser-based fetch) needs that, GitHub Release assets don't provide it
- Server provisioning lives in a separate repo: [homelab-ansible](https://github.com/st0o0/homelab-ansible)

## Guidelines

- Pin image tags where possible (e.g. `jellyfin:10.11` not `jellyfin:latest`) for reproducibility
- Always include a `TZ` env var so timezone is configurable
- Use `/data/<service-name>` as the default host bind path convention
- Keep descriptions concise — one sentence
- Add a `note` field for important deployment caveats (VPN routing, host network, USB passthrough)

See [CONTRIBUTING.md](CONTRIBUTING.md) for additional details.
