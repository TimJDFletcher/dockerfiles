# samba-timemachine-docker

This is a docker container based on Debian Trixie with SAMBA configured to provide Apple "Time Capsule" like backups.

The Docker Hub [images](https://hub.docker.com/repository/docker/timjdfletcher/samba-timemachine/tags?page=1&ordering=last_updated)
support AMD64, Raspberry Pi 3/4 and other modern ARM64 based systems.

# Networking

The container by default listens on port 10445, allowing this container to run alongside an existing SAMBA server and to remove 
the need for root access in the container

An example of how to use the container with raw docker

```bash
docker run -d -t \
    -v /backups/timemachine:/backups \
    -p 10445:10445 \
    --restart unless-stopped timjdfletcher/samba-timemachine:latest
```

The repo includes an example [docker compose](https://docs.docker.com/compose/) [file](./docker-compose.yml) that starts the container 
with a local volume and healthchecks enabled.

# Discovery

The container only runs smbd on a nonstandard port, to enable discovery on your local network a tool such as avahi to announce the server over mDNS.  

I do this by running avahi-daemon on the docker host system, for debian type systems install the package avahi-daemon: 

```bash
apt install avahi-daemon
```

And copy the example [service file](avahi.service) to `/etc/avahi/services/timemachine.service`

# Autostart with SystemD

Use the setup script to create a system user and install the systemd service:

```bash
sudo ./scripts/setup-system.sh --backup-dir /mnt/backups
```

The script:
- Creates a `timemachine` system user (in the docker group)
- Sets up the backup directory with correct permissions
- Installs the docker-compose stack to `/opt/samba-timemachine`
- Creates and enables the systemd unit

Options:
- `--uid UID` — UID for timemachine user (default: 999)
- `--gid GID` — GID for timemachine group (default: 999)
- `--backup-dir DIR` — Backup storage directory (default: /data/timemachine)
- `--install-dir DIR` — Installation directory (default: /opt/samba-timemachine)

After setup, edit `/opt/samba-timemachine/.env` to set your password, then start the service:

```bash
systemctl start timemachine
```

For manual installation, see the [example unit file](./systemd-unit.service).

# Settings

| Variable    |              Function               |      Default  |
|-------------|:-----------------------------------:|--------------:|
| `USER`      |        Time Machine Username        | `timemachine` |
| `PASS`      |        Time Machine Password        |    `password` |
| `PUID`      | Unix User ID for Time Machine user  |         `999` |
| `PGID`      | Unix Group ID for Time Machine user |         `999` |
| `LOG_LEVEL` |         SAMBA logging level         |           `1` |

The defaults are embedded in the Dockerfile

# Security

The security design is simple and assumes that timemachine backups are encrypted before leaving the source macOS system. 

The default configuration of the container creates a unix user called `timemachine` with uid and gid 999, and a matching SAMBA user called `timemachine` with a password of `password`.

A custom username can be passed to the container with the environment variable `USER`.

A custom password can be passed to the container with the environment variable `PASS`.

# Quota

Quota management is now handled on the client side using the `tmutil` command. This is more reliable and consistent with modern macOS versions.

To set a quota, you first need to identify the `destination_id` for your Time Machine backup. You can do this by running:

```bash
tmutil destinationinfo
```

This will output information about your backup destination(s), including the ID. Once you have the ID, you can set the quota.

For example, to set a quota of 500GB on a destination with the ID `A1B2C3D4-E5F6-G7H8-I9J0-K1L2M3N4O5P6`, you would run:

```bash
sudo tmutil setquota A1B2C3D4-E5F6-G7H8-I9J0-K1L2M3N4O5P6 500
```

# Building the Docker image

To build the image you need to have docker and docker buildx available, this is included by default in docker desktop but for colime buildx needs to be [installed](https://github.com/abiosoft/colima/issues/44).

# Testing

[Goss](https://github.com/goss-org/goss) tests are [included](goss/tests/), to execute the tests use the run script: `./run test`

Trivy is configured as well to test the container for known vulnerabilities.

# Debugging

The container can be started with SAMBA debugging flags for example: `--debuglevel=4`

There is a utility function in the run script that will print out macOS timemachine logs and then follow them to use it call:
`./run timemachineLogs`

# Storage notes

Generally speaking timemachine backups are heavy metadata workloads.
I have had some performance problems using ZFS as a backing store for the container in Catalina.
I'm not sure if this because of the slow SMR drive I was using or by ZFS's copy on write design interacting badly with APFS.
I have changed the backend storage that I use to ext4 which has been working well.

# Backup Monitoring

The repository includes a `backup-check.sh` script in the `scripts/` directory. This script is designed to monitor the health of your Time Machine backups.

It works by scanning for `.sparsebundle` directories and checking the modification times of the files within them. If no files have been modified within a configurable number of days (default is 14), it is considered "stale," and a notification can be sent.

## Features

- **Stale Backup Detection:** Identifies backups that haven't been updated recently.
- **Webhook Integration:** Can trigger a webhook (e.g., to a service like Healthchecks.io or a custom notification system) by setting the `WEBHOOK_URL` environment variable. If the variable is not set, it performs a dry run.
- **Cron Job Ready:** The script can be scheduled to run automatically. An example cron file, `scripts/backup-check.cron`, is provided to show how to execute it periodically.

# Known Bugs

I have had some macOS kernel watchdogd crashes in smbfs that I think might be related to this container, I've done the following things 
to fix them:

* Switch to using trixie backports for a newer version of SAMBA
* Applied this [fix](https://community.synology.com/enu/forum/1/post/194563) to my MacBook

# Software Used

* [Debian Trixie](https://hub.docker.com/_/debian/tags?page=1&name=trixie)
* [SAMBA](https://packages.debian.org/trixie-backports/samba)
* [Goss](https://github.com/goss-org/goss) — built from source with patched dependencies (see `../goss` project)

