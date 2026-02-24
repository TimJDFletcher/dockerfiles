# Media Server Stack

Docker Compose stack for a home media server using third-party images.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Transmission | 9091 | BitTorrent client |
| Kodi Headless | 8080 | Media library management |
| MariaDB | 3306 | Database for Kodi |
| CouchPotato | 5050 | Movie automation |
| Medusa | 8081 | TV show automation |
| Tor Proxy | — | Anonymized traffic |

## Usage

```bash
cd media
docker compose up -d
```

## Configuration

All services use LinuxServer.io images with common environment variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `PUID` | 109 | User ID for file permissions |
| `PGID` | 109 | Group ID for file permissions |
| `TZ` | Europe/Berlin | Timezone |

Adjust `PUID` and `PGID` to match your system's media user.

## Volume Mounts

Create the following directory structure:

```
/media/
├── transmission/
│   ├── config/
│   ├── torrents/
│   └── downloads/
├── kodi/
│   ├── config/
│   └── mariadb/
├── couchpotato/
│   └── config/
├── sickrage/
│   └── config/
├── movies/
└── tv/
```

## Networks

The stack uses two isolated networks:
- **external** (192.168.100.0/24) — Internet-facing services
- **internal** (192.168.101.0/24) — Internal communication with IP masquerade
