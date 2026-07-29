# Hawser Edge

Dockhand agent in edge mode — initiates outbound WebSocket connection to the Dockhand server. No inbound port needed, ideal for NAT/VPS.

## Quick start

```bash
cp .env .env.local   # set DOCKHAND_SERVER_URL and TOKEN
docker compose up -d
```

## Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `DOCKHAND_SERVER_URL` | yes | — | Dockhand server WebSocket URL |
| `TOKEN` | yes | — | Agent token from Dockhand |
| `AGENT_NAME` | no | — | Display name in Dockhand UI |
| `HEARTBEAT_INTERVAL` | no | `30` | Heartbeat interval in seconds |
| `TZ` | no | `Europe/Berlin` | Timezone |
