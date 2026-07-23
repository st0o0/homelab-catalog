# Contributing

## Commit convention

This repo uses [release-please](https://github.com/googleapis/release-please)
to generate CHANGELOGs and version tags for two independently-versioned
components — `ansible` (everything under `ansible/`) and `catalog`
(everything else, mainly `templates/` and `stacks/`). It parses commit
messages on `main` by walking the git log, so with this repo's
rebase/merge workflow **every individual commit** (not just a PR title)
must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <description>

feat(ansible): add fail2ban role
fix(catalog): correct jellyfin volume bind path
docs: clarify template field reference
```

Common types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`,
`ci`, `chore`, `revert`. A CI check (`commitlint.yml`) lints every commit
in a PR against this format and fails if any of them don't match — clean
these up (`git rebase -i`) before merging.

## Project Structure

```
templates/                        One JSON file per service, grouped by category
├── media/
│   ├── jellyfin.json
│   ├── sonarr.json
│   └── ...
├── smart-home/
├── photos/
├── auth/
├── networking/
├── monitoring/
├── productivity/
├── backup/
├── data/
└── observability/
scripts/
└── build.ps1                     Validates all templates and merges into templates.json
.github/workflows/
└── validate.yml                  CI pipeline: validate → build → deploy to release branch
```

The `templates.json` consumed by Dockhand lives only on the `release` branch. It is auto-generated — never edit it directly.

## Adding a Template

### 1. Pick the right category

Choose an existing subdirectory under `templates/`. If no category fits, create a new one — the build script picks up any subdirectory automatically.

### 2. Create the JSON file

File name should be lowercase kebab-case matching the service name (e.g. `uptime-kuma.json`, `home-assistant.json`).

**Single container** (`type: 1`):

```json
{
  "type": 1,
  "title": "My Service",
  "description": "One-line description of what it does",
  "image": "registry/image:tag",
  "categories": ["Category"],
  "ports": ["8080:8080/tcp"],
  "volumes": [
    { "bind": "/data/my-service/config", "container": "/config" },
    { "bind": "/data/my-service/data", "container": "/data" }
  ],
  "env": [
    { "name": "TZ", "label": "Timezone", "default": "Europe/Berlin" },
    { "name": "PUID", "label": "User ID", "default": "1000" },
    { "name": "PGID", "label": "Group ID", "default": "1000" }
  ],
  "restart_policy": "unless-stopped"
}
```

**Compose stack** (`type: 3`) — references a `docker-compose.yml` in a Git repository:

```json
{
  "type": 3,
  "title": "My Stack",
  "description": "Multi-container application with database and cache",
  "categories": ["Productivity"],
  "repository": {
    "url": "https://github.com/user/repo",
    "stackfile": "stacks/my-stack/docker-compose.yml"
  }
}
```

### 3. Validate locally

```powershell
# Validate and build templates.json locally
./scripts/build.ps1

# Validate only — no output file written
./scripts/build.ps1 -ValidateOnly
```

The build script checks:
- Valid JSON syntax
- Required fields present (`type`, `title`, `image` for type 1)
- Valid type value (1 or 3)
- Type 3 templates have `repository.url` and `repository.stackfile`
- All `env` entries have a `name`
- All `volumes` entries have `bind` and `container`
- No duplicate `title` values across the catalog

### 4. Commit and push

Only commit your template file under `templates/`. CI handles building and deploying:

```bash
git add templates/media/my-service.json
git commit -m "feat: add my-service template"
git push
```

On push to `main`, CI validates all templates, merges them, and deploys `templates.json` to the `release` branch. Dockhand picks up the change within one hour (its cache interval).

## Field Reference

| Field | Required | Type | Notes |
|---|---|---|---|
| `type` | yes | `1` or `3` | `1` = single container, `3` = compose stack |
| `title` | yes | string | Display name shown in Dockhand |
| `description` | no | string | Short description on the template card |
| `image` | yes (type 1) | string | Docker image reference (e.g. `jellyfin/jellyfin:10.11`) |
| `logo` | no | string | URL to an icon/logo image for the card |
| `categories` | no | string[] | Used for filtering in the Dockhand UI |
| `ports` | no | string[] | Format: `"host:container/proto"` (e.g. `"8080:8080/tcp"`) |
| `volumes` | no | object[] | `{ "bind": "/host/path", "container": "/container/path" }` |
| `env` | no | object[] | `{ "name": "VAR_NAME", "label": "Display Label", "default": "value" }` |
| `restart_policy` | no | string | Defaults to `unless-stopped` if omitted |
| `note` | no | string | Deployment caveats — not shown in Dockhand, for documentation only |
| `repository` | yes (type 3) | object | `{ "url": "https://...", "stackfile": "path/to/docker-compose.yml" }` |

## Guidelines

- **Pin image tags** where possible (`jellyfin:10.11` not `jellyfin:latest`) for reproducibility
- **Always include `TZ`** as an env var so timezone is configurable
- **Use `/data/<service-name>`** as the default host bind path convention
- **Keep descriptions concise** — one sentence, no period
- **Add a `note` field** for important deployment caveats (VPN routing, host network mode, USB passthrough, required companion services)
- **One file per service** — even if services are related (e.g. Immich Server and Immich ML are separate files)
