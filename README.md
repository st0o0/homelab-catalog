# homelab-catalog

Dockhand template catalog for homelab services. Each service is defined as an individual JSON file under `templates/` and automatically merged into a single `templates.json` on the `release` branch via CI.

## Quick Start

### 1. Connect to Dockhand

In the Dockhand UI go to **Templates → Sources** and add a new source:

| Field | Value |
|---|---|
| Name | `Homelab` |
| URL | `https://raw.githubusercontent.com/st0o0/homelab-catalog/release/templates.json` |

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
    { "name": "TZ", "label": "Timezone", "default": "Europe/Vienna" }
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

Only commit your template file — CI handles the rest:

```bash
git add templates/media/my-service.json
git commit -m "feat: add my-service template"
git push
```

CI validates all templates and deploys the merged `templates.json` to the `release` branch automatically.

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

| Category | Services |
|---|---|
| Media | Jellyfin, Sonarr, Radarr, Prowlarr, SABnzbd, Audiobookshelf, Pinchflat, Seerr, FlareSolverr, Tracearr, Recyclarr, Mediathekarr, Arr Dashboard |
| Smart Home | Home Assistant, Zigbee2MQTT, Mosquitto, MQTT UI, Matter Server |
| Photos | Immich Server, Immich ML |
| Auth & Security | Authentik, Vaultwarden |
| Networking | Traefik, Gluetun, Pangolin, Gerbil, Bifrost, Hawser |
| Monitoring | Uptime Kuma, Dockhand |
| Productivity | Mealie, Actual Budget |
| Backup | Duplicati |
| Data | PostgreSQL, Redis, Valkey |
| Observability | Grafana, VictoriaMetrics, VictoriaLogs, Grafana Alloy |

## How It Works

```
main branch                              release branch
┌─────────────────────────────┐          ┌──────────────────┐
│ templates/                  │          │ templates.json    │
│   media/jellyfin.json       │  CI      │   (merged output) │
│   media/sonarr.json         │ ──────►  │                  │
│   ...                       │  build   │                  │
│ scripts/build.ps1           │  + push  │                  │
└─────────────────────────────┘          └──────────────────┘
                                                  │
                                           Dockhand fetches
                                           via raw URL
```

- **`main`** holds the source files: individual templates, the build script, CI config, and docs
- **`release`** holds only the merged `templates.json` — auto-updated by CI on every push to `main`
- The Portainer v2 template format requires a single JSON file, so the build step is necessary

## Guidelines

- Pin image tags where possible (e.g. `jellyfin:10.11` not `jellyfin:latest`) for reproducibility
- Always include a `TZ` env var so timezone is configurable
- Use `/data/<service-name>` as the default host bind path convention
- Keep descriptions concise — one sentence
- Add a `note` field for important deployment caveats (VPN routing, host network, USB passthrough)

See [CONTRIBUTING.md](CONTRIBUTING.md) for additional details.
