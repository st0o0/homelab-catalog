# Alloy

Grafana Alloy agent that collects host metrics, Docker container logs, and system logs, then ships everything to a remote VictoriaMetrics / VictoriaLogs.

```
 host
┌──────────────────────────────────────┐
│ /proc /sys /var/log docker ────────► │
│  ┌───────┐                           │    central server
│  │ Alloy │ ─────────────────────────────► VictoriaMetrics
│  └───────┘                           │──► VictoriaLogs
└──────────────────────────────────────┘
```

## Quick start

```bash
cp .env .env.local   # edit with your values
docker compose up -d
```

## Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `HOST_HOSTNAME` | yes | — | `host` label on all metrics/logs (must be unique per server) |
| `REMOTE_WRITE_URL` | yes | — | VictoriaMetrics remote write endpoint |
| `LOGS_PUSH_URL` | yes | — | VictoriaLogs Loki push endpoint |
| `SCRAPE_INTERVAL` | no | `30s` | Prometheus scrape interval |

## Bifrost overlay

To route all telemetry through a WireGuard tunnel, deploy alongside Bifrost's compose file and stack the overlay:

```bash
docker compose -f compose.yml -f ../bifrost/compose.yml -f compose.bifrost.yml up -d
```

This sets `network_mode: service:bifrost` so all traffic leaves through the tunnel.

## Verify

Check metrics are arriving on the central server:

```promql
node_load1{host="<HOST_HOSTNAME>"}
```
