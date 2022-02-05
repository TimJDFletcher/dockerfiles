# samba-timemachine-docker

This is a docker container based on Ubuntu Focal running SAMBA and configured to provide Apple "Time Capsule" like backups.

The Docker Hub images support x86_64, Raspberry Pi 2/3/4 and other modern ARM based systems.

An example of how to use the container

```bash
docker run -d -t \
    -v /backups/timemachine:/backups \
    -p 10445:445 \
    --restart unless-stopped timjdfletcher/samba-timemachine:timemachine-v2.4
```

This example maps the docker host port 10445 to the container port 445, so the container can be run alongside a normal SAMBA service.

# Discovery

The container only runs smbd, to enable discovery on your local network use multicast DNS such as avahi.  

I do this by running avahi-daemon on the docker host system, for debian systems install the package avahi-daemon: 

```bash
apt install avahi-daemon
```

To enable discovery copy the [service file](timemachine.service) to `/etc/avahi/services/`

There is also a docker [container](https://hub.docker.com/r/solidnerd/avahi) that can be used instead of installing avahi-daemon on the host. 
I have not tested this recently. 

# Settings

| Variable    | Function                                        | Default.    |
| ------------|:-----------------------------------------------:|------------:|
| USER        | Time Machine User                               | timemachine |
| PASS        | User Password                                   | password    |
| PUID        | UserID                                          | 999         |
| PGID        | GroupID                                         | 999         |
| QUOTA       | Time Machine Size in MB                         | 512000      |
| RANDOM_PASS | Generate a random password, printed in the logs | false       |

# Security

The container creates a user timemachine on startup, with by default a password of `password`, and then drops root.

A password can be passed in with the environment variable `PASS`, or by setting the environment variable `RANDOM_PASS` to true the container generates a random password on startup.

# Storage

I have had some problems using ZFS as a backing store for the container in Catalina, I'm not sure if this because of the slow SMR drive I was using or ZFS.
I have changed the backend storage to ext4 which has been working well.

# Quotas

The container supports setting of quota to limit the max size of backups, it defaults to 512GB.
I'm unclear if this works correctly in macOS.

# Testing

Serverspec tests are included, to execute the tests use the run script: `./run test`

# Versions

Base image: [Ubuntu Focal](https://hub.docker.com/_/ubuntu?tab=tags&page=1&name=focal)
[SAMBA](https://packages.ubuntu.com/focal/samba)
[iproute2](https://packages.ubuntu.com/focal/iproute2)

# Docker image builds

Auto builds are disabled to allow for multiarch local builds.

~~Repo is auto built here: https://hub.docker.com/r/timjdfletcher/samba-timemachine/~~
