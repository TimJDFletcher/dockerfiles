# media Agent Documentation

Docker Compose stack for a home media server. Uses third-party images only — no custom Dockerfiles.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `tor` | `dperson/torproxy` | — | Tor proxy for anonymized traffic |
| `transmission` | `linuxserver/transmission` | 9091 | BitTorrent client |
| `mariadb` | `linuxserver/mariadb` | 3306 | Database for Kodi |
| `kodi-headless` | `linuxserver/kodi-headless` | 8080 | Kodi library management |
| `couchpotato` | `linuxserver/couchpotato` | 5050 | Movie automation |
| `medusa` | `linuxserver/medusa` | 8081 | TV show automation |

## Networks

| Network | Subnet | Purpose |
|---------|--------|---------|
| `external` | 192.168.100.0/24 | Internet-facing services |
| `internal` | 192.168.101.0/24 | Internal communication with IP masquerade |

## Volume Mounts

All services expect data at `/media/`:

- `/media/transmission/config`, `/media/transmission/torrents`, `/media/transmission/downloads`
- `/media/kodi/mariadb`, `/media/kodi/config`
- `/media/couchpotato/config`
- `/media/sickrage/config`
- `/media/movies`, `/media/tv`

## Usage

```bash
cd media
docker compose up -d
```

## Notes

- All services use `PUID=109` and `PGID=109` — adjust for your system
- Timezone set to `Europe/Berlin`
- No `./run` script — use `docker compose` directly
- No custom images to build or maintain
