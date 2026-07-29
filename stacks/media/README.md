# Media

Media consumption stack with Jellyfin (video) and Audiobookshelf (audiobooks/podcasts).

```
 host
┌──────────────────────────────────────┐
│  ┌──────────────┐                    │
│  │   Jellyfin    │ :8096             │
│  │   /dev/dri    │ HW transcoding    │
│  │   media_smb   │ movies/shows      │
│  └──────────────┘                    │
│                                      │
│  ┌────────────────┐                  │
│  │ Audiobookshelf  │ :13378          │
│  │   audios_smb    │ audiobooks      │
│  └────────────────┘                  │
│                                      │
│  Network: media-net (external)       │
└──────────────────────────────────────┘
```

## Prerequisites

- `media-net` Docker network: `docker network create media-net`
- CIFS volume mounts for `media_smb` and `audios_smb`
- `/dev/dri` for hardware transcoding (Intel/AMD GPU)

## Quick start

```bash
cp .env .env.local   # edit if needed
mkdir -p data/jellyfin/{config,cache,preview} data/audiobookshelf/{config,metadata}
docker compose up -d
```

## Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `JELLYFIN_PORT` | no | `8096` | Jellyfin web UI port |
| `AUDIOBOOKSHELF_PORT` | no | `13378` | Audiobookshelf web UI port |
| `JELLYFIN_VIDEO_PATH` | no | `./data/jellyfin/video` | Local video directory |
| `TZ` | no | `Europe/Berlin` | Timezone |

## Verify

- Jellyfin: `http://localhost:8096`
- Audiobookshelf: `http://localhost:13378`
