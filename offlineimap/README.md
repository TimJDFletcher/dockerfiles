# OfflineIMAP Docker Image

Docker container for [OfflineIMAP](https://www.offlineimap.org/), an IMAP synchronization tool with scheduled sync via [supercronic](https://github.com/aptible/supercronic).

## Usage

```bash
docker run -d \
  -v /path/to/offlineimaprc:/home/offlineimap/.offlineimaprc:ro \
  -v /path/to/mail:/email \
  timjdfletcher/offlineimap
```

The container runs `supercronic` with the built-in crontab by default, executing periodic syncs.

## Configuration

Mount your `.offlineimaprc` configuration file. Example minimal config:

```ini
[general]
accounts = Main

[Account Main]
localrepository = Local
remoterepository = Remote

[Repository Local]
type = Maildir
localfolders = /email

[Repository Remote]
type = IMAP
remotehost = imap.example.com
remoteuser = user@example.com
remotepasseval = "password"
ssl = yes
```

## Volumes

| Path | Purpose |
|------|---------|
| `/home/offlineimap/.offlineimaprc` | OfflineIMAP configuration |
| `/email` | Local maildir storage |

## Build

```bash
./run build
```

## Test

```bash
./run test
```

Runs rspec tests (requires Ruby and Bundler).
