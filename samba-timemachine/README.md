# samba-timemachine-docker

This is a docker container based on Debian bookworm with SAMBA configured to provide Apple "Time Capsule" like backups.

The Docker Hub [images](https://hub.docker.com/repository/docker/timjdfletcher/samba-timemachine/tags?page=1&ordering=last_updated)
support x86_64, Raspberry Pi 2/3/4 and other modern ARM based systems.

An example of how to use the container

```bash
docker run -d -t \
    -v /backups/timemachine:/backups \
    -p 10445:445 \
    --restart unless-stopped timjdfletcher/samba-timemachine:latest
```

This example maps the docker host port 10445 to the container port 445, so the container can be run alongside a normal SAMBA service.

# Discovery

The container only runs smbd, to enable discovery on your local network use multicast DNS such as avahi.  

I do this by running avahi-daemon on the docker host system, for debian type systems install the package avahi-daemon: 

```bash
apt install avahi-daemon
```

To enable discovery copy the [service file](timemachine.service) to `/etc/avahi/services/`

# Settings

| Variable    |                   Function                    | Default.    |
| ------------|:---------------------------------------------:|------------:|
| `USER`        |               Time Machine User               | `timemachine` |
| `PASS`        |                 User Password                 | `password`    |
| `PUID`        |                    UserID                     | `999`         |
| `PGID`        |                    GroupID                    | `999`         |
| `QUOTA`       |           Time Machine Quota in MB            | `512000`      |

# Security

The security design is basic, I assume that Timemachine backups are encrypted from the source macOS device. 
The container creates a user timemachine on startup, with by default a password of `password`, and then drops root.

A custom password can be passed to the container with the environment variable `PASS`.

# Storage

I have had some performance problems using ZFS as a backing store for the container in Catalina. 
I'm not sure if this because of the slow SMR drive I was using or by ZFS's copy on write design interacting badly with APFS.
I have changed the backend storage that I use to ext4 which has been working well.

# Quotas

The container supports setting of quota to limit the max size of backups, it defaults to 512GB.
I'm unclear if this works correctly in modern versions of macOS.

The SAMBA setting of `disk max size` is also configured to limit the reported size of the disk to the same as the configured quota. 
This is a soft limit not a hard limit.

# Building the Docker image

To build the image you need to have docker and docker buildx available, this is included by default in docker desktop 
but for colime buildx needs to be [installed](https://github.com/abiosoft/colima/issues/44).

# Testing

Serverspec tests are included, to execute the tests use the run script: `./run test`

Trivy is configured as well to test the container for known vulnerabilities.

# Debugging

The container can be started with SAMBA debugging flags for example: `--debuglevel=8 --debug-stdout`

# Versions

* [Debian Bookworm Slim](https://hub.docker.com/_/debian?tab=tags&page=1&name=bookworm-slim)
* [SAMBA](https://packages.debian.org/bookworm/samba) [4.16.4](https://www.samba.org/samba/history/samba-4.16.4.html)