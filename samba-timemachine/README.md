# samba-timemachine-docker

This is a docker container that contains the latest (4.9.5+dfsg-3) version of SAMBA from Debian Buster configured to provide Apple "Time Capsule" like backups.

To use the docker container do the following:

```
docker pull timjdfletcher/samba-timemachine
docker run -d -t \
    -v /backups/timemachine:/backups \
    -p 10445:445 \
    --restart unless-stopped timjdfletcher/samba-timemachine
```

Note that due to the use of port 10445 this container can be run along side a normal SAMBA service.

# Settings

| Variable  | Function                | Default.    |
| ----------|:-----------------------:|-------------:|
| USER      | Time Machine User       | timemachine |
| PASS      | User  Password          | password    |
| PUID      | UserID                  | 999         |
| PGID      | GroupID                 | 999         |
| QUOTA     | Time Machine Size in MB | 512000      |

# Connecting

There is a single user called `timemachine` with a password of `password` by default. 

The container only runs smbd to find it on the network the best way is avahi (mDNS) there is an example service file included. This can be copied to /etc/avahi/services/timemachine.service or run in a container.

# Quotas

The container supports setting of quota to limit the max size of backups, it defaults to 512GB

# Testing

Serverspec tests are included, to run them use the run script: `./run test`

# Docker image builds

Repo is auto built here: https://hub.docker.com/r/timjdfletcher/samba-timemachine/
