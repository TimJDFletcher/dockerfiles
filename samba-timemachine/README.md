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

There is an [example](./systemd-unit.service) of a systemd unit file that auto starts the docker compose stack.

To enable the systemd unit, copy the file to `/etc/systemd/system/timemachine.service` and then run `systemd enable timemachine`

# Settings

| Variable    |              Function               |      Default  |
|-------------|:-----------------------------------:|--------------:|
| `USER`      |        Time Machine Username        | `timemachine` |
| `PASS`      |        Time Machine Password        |    `password` |
| `PUID`      | Unix User ID for Time Machine user  |         `999` |
| `PGID`      | Unix Group ID for Time Machine user |         `999` |
| `LOG_LEVEL` |         SAMBA logging level         |           `1` |
| `QUOTA`     |      Time Machine Quota in GB       |        `1024` |

The defaults are embedded in the Dockerfile

# Security

The security design is simple and assumes that timemachine backups are encrypted before leaving the source macOS system. 

The default configuration of the container creates a unix user called `timemachine` with uid and gid 999, and a matching SAMBA user called `timemachine` with a password of `password`.

A custom username can be passed to the container with the environment variable `USER`.

A custom password can be passed to the container with the environment variable `PASS`.

# Quota

The container supports setting of quota, in Gigabytes to limit the max size of backups, it defaults to 1024GB (1TB).
I'm unclear if this works correctly in modern versions of macOS.

The SAMBA setting of `disk max size` is also configured to limit the reported size of the disk to the same as the configured quota. 
This is a soft limit not a hard limit.

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

# Known Bugs

I have had some macOS kernel watchdogd crashes in smbfs that I think might be related to this container, I've done the following things 
to fix them:

* Switch to using trixie backports for a newer version of SAMBA
* Applied this [fix](https://community.synology.com/enu/forum/1/post/194563) to my MacBook

# Software Used

* [Debian Trixie](https://hub.docker.com/_/debian/tags?page=1&name=trixie-packports)
* [SAMBA](https://packages.debian.org/trixie/samba)
* [GOSS](https://github.com/goss-org/goss/releases)

# Areas for improvement

* Figure out how to run rootless (WIP)
  * Backup directory ownership config
  * User configuration, maybe bake the user into the container but how to support UID/GID mapping?
  * Maybe just a hard set UID/GID, and add docs about fixing directory perms, rely on healthcheck tests to capture incorrect config
* Experiment with https://github.com/GoogleContainerTools/container-structure-test
* Make listen port configurable, needs to pass in env var and templete config and tests
* Add docs to the container to auto populate the SMB share
* Switch to envsubst for templating
