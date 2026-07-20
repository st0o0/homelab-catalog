# Observability Agent

Collector stack for **remote servers**: Grafana Alloy gathers host metrics, docker logs, and system/fail2ban logs — exactly like the central [observability stack](../observability/README.md) — and ships everything to the central VictoriaMetrics/VictoriaLogs through a **Bifrost WireGuard tunnel**.

```
 remote server                                      central server
┌───────────────────────────────┐                 ┌──────────────────────────┐
│ /proc /sys /var/log docker ──►│                 │                          │
│  ┌───────┐   network_mode     │   WireGuard     │ 10.13.13.1:8428 ── VM    │
│  │ Alloy │ ──────────────────►│═════════════════│ 10.13.13.1:9428 ── VLogs │
│  └───────┘  service:bifrost   │     tunnel      │                          │
└───────────────────────────────┘                 └──────────────────────────┘
```

Alloy runs with `network_mode: service:bifrost`, so **all** telemetry leaves the host through the tunnel — nothing needs to be exposed on the public network on either side.

## Setup

### 1. Central server (once)

The central observability stack binds VictoriaMetrics and VictoriaLogs to `127.0.0.1` by default. To accept agents, set these deploy variables to the central host's **WireGuard IP**:

```
VM_BIND_IP=10.13.13.1
VLOGS_BIND_IP=10.13.13.1
```

The WireGuard endpoint on the central side can be any WireGuard server (a host-level `wg0`, a Bifrost container with a fixed `BIFROST_LISTEN_PORT`, an existing VPN hub, ...). Each agent is one peer.

### 2. Generate a peer

On any machine with wireguard-tools:

```bash
wg genkey | tee agent.key | wg pubkey > agent.pub
```

Add the agent's public key as a peer on the central WireGuard server with its tunnel IP (e.g. `10.13.13.11/32`), and note the central server's public key and endpoint.

### 3. Deploy the agent

Required variables:

| Variable | Example | Purpose |
|---|---|---|
| `HOST_HOSTNAME` | `nas-01` | `host` label on all metrics/logs — **must be unique per server** |
| `BIFROST_PRIVATE_KEY` | contents of `agent.key` | Agent's WireGuard identity |
| `BIFROST_ADDRESS` | `10.13.13.11/32` | Agent's tunnel IP |
| `BIFROST_PEER_PUBLIC_KEY` | central server's pubkey | |
| `BIFROST_PEER_ENDPOINT` | `vpn.example.com:51820` | Central WireGuard endpoint |

Defaults that usually fit:

| Variable | Default |
|---|---|
| `BIFROST_PEER_ALLOWED_IPS` | `10.13.13.0/24` (only tunnel traffic is routed — not a full VPN) |
| `REMOTE_WRITE_URL` | `http://10.13.13.1:8428/api/v1/write` |
| `LOGS_PUSH_URL` | `http://10.13.13.1:9428/insert/loki/api/v1/push` (VictoriaLogs speaks the Loki push protocol) |

### 4. Verify

In Grafana on the central server:

- **Explore → VictoriaMetrics**: `node_load1{host="nas-01"}`
- **Explore → VictoriaLogs**: `{host="nas-01"}`

Since every series carries the `host` label, the imported dashboards (e.g. Node Exporter Full) let you switch between servers with the instance/host variable.

## fail2ban on remote hosts

Identical to the central stack: fail2ban must log to `/var/log/fail2ban.log` (default on most distros — see the [central README](../observability/README.md#fail2ban--host-log-integration)). Ban events arrive with `job="fail2ban"`, `jail`, `action`, and the agent's `host` field, so one Security dashboard covers the whole fleet:

```logsql
_time:24h {job="fail2ban", action="Ban"} | stats by (host, jail) count()
```

## Notes

- Buffering: if the tunnel drops, Alloy retries with a write-ahead log (`alloy-data` volume) — short outages don't lose telemetry.
- Container names are prefixed `obs-agent-*` so the stack can coexist with a standalone Bifrost deployment.
- Non-Debian hosts: adjust log paths in `alloy/config.alloy` (e.g. `/var/log/secure` on RHEL).
- Bifrost needs `NET_ADMIN` and uses the kernel WireGuard module (Linux 5.6+); `/dev/net/tun` is passed for the userspace fallback.
