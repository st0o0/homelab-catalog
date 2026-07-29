# Hawser

Dockhand agent for managing remote Docker environments. Runs on each host and connects to the central Dockhand server.

```
 remote host                          central server
┌──────────────────────┐           ┌──────────────────┐
│  ┌──────────┐        │           │                  │
│  │ Hawser   │ :2376 ─│──────────►│    Dockhand      │
│  │          │        │           │                  │
│  │ docker.  │        │           └──────────────────┘
│  │  sock    │        │
│  └──────────┘        │
└──────────────────────┘
```

## Quick start

```bash
cp .env .env.local   # set TOKEN from Dockhand
docker compose up -d
```

## Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `TOKEN` | yes | — | Agent token from Dockhand |
| `AGENT_NAME` | no | — | Display name in Dockhand UI |
| `HAWSER_PORT` | no | `2376` | Published port |
| `DOCKER_SOCKET` | no | `/var/run/docker.sock` | Docker socket path |
| `STACKS_PATH` | no | `hawser-stacks` | Stack storage (host path or named volume) |
| `TZ` | no | `Europe/Berlin` | Timezone |

## Verify

In Dockhand UI, the host should appear as an environment within a few seconds.
