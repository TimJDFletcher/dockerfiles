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

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `up` | Start all services in background |
| `down` | Stop all services |
| `logs` | Follow logs (optionally specify service) |
| `status` | Show running services |
| `pull` | Pull latest images |
| `restart` | Restart services (optionally specify service) |
| `clean` | Stop and remove volumes |

## Usage

```bash
cd media
./run up        # Start stack
./run logs      # Follow all logs
./run logs transmission  # Follow specific service
./run status    # Check what's running
./run down      # Stop everything
```

## Notes

- All services use `PUID=109` and `PGID=109` — adjust for your system
- Timezone set to `Europe/Berlin`
- No custom images to build or maintain
