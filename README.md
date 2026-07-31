# homelab-catalog

A Komodo GitOps monorepo for homelab services. Every service is a Docker
Compose stack under `stacks/<service>/`, deployed and kept in sync across
hosts by [Komodo](https://komo.do/) — no manual `docker compose up`, no
separate catalog UI.

**Related repos:** [homelab-ansible](https://github.com/st0o0/homelab-ansible) (server provisioning) · [dotfiles](https://github.com/st0o0/dotfiles) (shell toolchain)

## How it's organized

```
stacks/<service>/            WHAT is deployable — compose file, .env.example,
                              optional README. Host-agnostic: nothing in here
                              says which server it runs on.

komodo/resources/            WHERE and WITH WHAT VALUES — ResourceSync TOML:
├── servers.toml               every host Komodo manages
├── stacks.toml                which stack runs on which server, with which
│                               variables/secrets
└── variables.toml             shared non-secret values (TZ, PUID/PGID, ...)

komodo/                      Secrets, SOPS-encrypted and committed:
├── secrets.sops.yaml           shared secrets, available as [[SECRET_NAME]]
├── hosts/<host>/
│   └── secrets.sops.yaml       per-host secrets, available as [[<host>_KEY]]
└── decrypt.sh                  merges both into Komodo Core's config
```

A stack's server assignment lives in `komodo/resources/stacks.toml`, not in
its directory path — reassigning a stack to a different host is a one-line
TOML edit, not a file move. See [ROADMAP.md](ROADMAP.md) for what's still
being built out and [komodo/README.md](komodo/README.md) for the full
secrets workflow.

## Quick Start

### 1. Set up secrets

```bash
just setup            # generates/restores your AGE key, registers it in komodo/.sops.yaml
just secrets          # edit shared secrets (komodo/secrets.sops.yaml)
just secrets <host>   # edit per-host secrets (komodo/hosts/<host>/secrets.sops.yaml)
```

See [komodo/README.md](komodo/README.md) for the full secrets workflow,
including first-time Core host setup and secret rotation.

### 2. Deploy Komodo Core

Deploy `stacks/komodo/` on the host that will run Komodo Core (see that
stack's `.env.example`). Once running, decrypt secrets into its config:

```bash
just decrypt           # writes /etc/komodo/core.secrets.toml on the Core host
```

### 3. Point Komodo at this repo

In the Komodo UI, add a ResourceSync pointed at `komodo/resources/` in this
repo. Komodo reads `servers.toml`, `stacks.toml`, and `variables.toml` and
shows you the resulting sync plan — review it, then execute.

### 4. Deploy `komodo-periphery` to remaining hosts

Every host other than Core needs a `komodo-periphery` agent so Core can
manage it — deploy `stacks/komodo-periphery/` there manually (see that
stack's `.env.example`).

`stacks/komodo/` and `stacks/komodo-periphery/` are deliberately **not**
declared in `komodo/resources/stacks.toml` — Komodo has no native
self-update for either component, so managing its own control plane
through itself would be a chicken-and-egg risk. Deploy and update both
manually (`docker compose pull && docker compose up -d`, Core first, then
Periphery on every host).

## Adding a Stack

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full walkthrough: creating a
`stacks/<service>/` directory, validating it locally, and wiring it into
`komodo/resources/stacks.toml`.

## Guidelines

- Pin image tags where possible (e.g. `jellyfin:10.11` not `jellyfin:latest`) for reproducibility
- Always support a `TZ` env var so timezone is configurable
- Use `/data/<service-name>` as the default host bind path convention
- Guard required env vars in compose with `${VAR:?VAR is required}` so `docker compose config` fails loudly instead of deploying with an empty value

See [CONTRIBUTING.md](CONTRIBUTING.md) for additional details.
