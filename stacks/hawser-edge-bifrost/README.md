# Hawser Edge + Bifrost

Hawser agent in edge mode routed through a Bifrost WireGuard tunnel. All Dockhand traffic goes through the VPN.

## Quick start

```bash
cp .env .env.local   # set Dockhand + WireGuard credentials
docker compose up -d
```

## Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `DOCKHAND_SERVER_URL` | yes | — | Dockhand server WebSocket URL |
| `TOKEN` | yes | — | Agent token from Dockhand |
| `BIFROST_PRIVATE_KEY` | yes | — | WireGuard private key |
| `BIFROST_PEER_PUBLIC_KEY` | yes | — | Remote peer's public key |
| `BIFROST_PEER_ENDPOINT` | yes | — | Remote peer's endpoint |
| `AGENT_NAME` | no | — | Display name in Dockhand UI |
| `BIFROST_ADDRESS` | no | `10.77.32.2/32` | Tunnel IP |
| `TZ` | no | `Europe/Berlin` | Timezone |
