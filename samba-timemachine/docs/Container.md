# samba-timemachine-docker

This is a docker container based on Debian Trixie with SAMBA configured to provide Apple "Time Capsule" like backups.

The Docker Hub [images](https://hub.docker.com/repository/docker/timjdfletcher/samba-timemachine/tags?page=1&ordering=last_updated)
support AMD64, Raspberry Pi 3/4 and other modern ARM64 based systems.

# Current Container Settings

| Variable    |              Function               |     Setting   |
|-------------|:-----------------------------------:|--------------:|
| `USER`      |        Time Machine Username        |   `${USER}`   |
| `PASS`      |        Time Machine Password        |   `${PASS}`   |
| `PUID`      | Unix User ID for Time Machine user  |   `${PUID}`   |
| `PGID`      | Unix Group ID for Time Machine user |   `${PGID}`   |
| `LOG_LEVEL` |         SAMBA logging level         | `${LOG_LEVEL}`|
| `QUOTA`     |      Time Machine Quota in GB       |  `${QUOTA}`   |
| `BACKUPDIR` | Filesystem path exported as /data   |`${BACKUPDIR}` |


# Security

The security design is simple and assumes that timemachine backups are encrypted before leaving the source macOS system. 

# Known Bugs

I have had some macOS kernel watchdogd crashes in smbfs that I think might be related to this container, I've done the following things 
to fix them:

* Switch to using trixie backports for a newer version of SAMBA
* Applied this [fix](https://community.synology.com/enu/forum/1/post/194563) to my MacBook

# Software Used

* [Debian Trixie](https://hub.docker.com/_/debian/tags?page=1&name=trixie-packports)
* [SAMBA](https://packages.debian.org/trixie/samba)
* [GOSS](https://github.com/goss-org/goss/releases)

