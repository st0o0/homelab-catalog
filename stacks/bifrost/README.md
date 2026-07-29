# Bifrost

WireGuard tunnel sidecar. Other containers can route their traffic through the tunnel using `network_mode: service:bifrost`.

```
 host                                        remote peer
┌──────────────────────────┐              ┌──────────────────┐
│  ┌──────────┐            │  WireGuard   │                  │
│  │ Bifrost  │════════════│══════════════│  endpoint        │
│  │  wg0     │            │   tunnel     │                  │
│  └──────────┘            │              └──────────────────┘
│       ▲                  │
│  network_mode:           │
│  service:bifrost         │
│  ┌──────────┐            │
│  │ Alloy    │            │
│  │ Backrest │            │
│  └──────────┘            │
└──────────────────────────┘
```

## Quick start

```bash
cp .env .env.local   # set private key and peer details
docker compose up -d
```

## Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `BIFROST_PRIVATE_KEY` | yes | — | WireGuard private key |
| `BIFROST_ADDRESS` | yes | — | Tunnel IP (e.g. `10.77.32.2/32`) |
| `BIFROST_PEER_PUBLIC_KEY` | yes | — | Remote peer's public key |
| `BIFROST_PEER_ENDPOINT` | yes | — | Remote peer's endpoint (e.g. `vpn.example.com:51820`) |
| `BIFROST_PEER_ALLOWED_IPS` | yes | — | Allowed IPs for the tunnel |
| `BIFROST_LISTEN_PORT` | no | `0` | WireGuard listen port (0 = random) |
| `BIFROST_MTU` | no | `1420` | Tunnel MTU |
| `BIFROST_PEER_KEEPALIVE` | no | `25` | Keepalive interval in seconds |
| `BIFROST_PEER_PRESHARED_KEY` | no | — | Optional preshared key |
| `BIFROST_INTERFACE` | no | `wg0` | WireGuard interface name |
| `BIFROST_CHECK_INTERVAL` | no | `30` | Health check interval |
| `BIFROST_STALE_AFTER` | no | `135` | Seconds before connection is stale |
| `BIFROST_RESOLVE` | no | `on` | Re-resolve DNS for endpoint |
| `BIFROST_RECONNECT` | no | `on` | Auto-reconnect on failure |
| `BIFROST_HEALTHCHECK` | no | `on` | Enable health checking |
| `BIFROST_PROBE` | no | `off` | Enable probe mode |

## Generate a WireGuard keypair

```bash
wg genkey | tee private.key | wg pubkey > public.key
```

## Verify

```bash
docker exec bifrost wg show
```
