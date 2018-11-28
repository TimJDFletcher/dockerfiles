# samba-timemachine-docker

This is a docker container that contains the latest (4.8.0-rc2) version of SAMBA built via git and configured to provide Apple "Time Capsule" like backups.

To use the docker container do the following:

```
docker pull timjdfletcher/samba-timemachine
docker run -d -t \
    -v /backups/timemachine:/backups \
    -p 10445:445 \
    --restart unless-stopped timjdfletcher/samba-timemachine
```

Note that due to the use of port 10445 this container can be run along side a normal SAMBA service.

There is a single user called `timemachine` with a password of `password` by default. 

Set the environment variables USER or PASS to override, if PASS is set to `RANDOM` then a random 16 character password will be generated for the user.

The container only runs smbd to find it on the network the best way is avahi (mDNS) there is an example service file included. This can be copied to /etc/avahi/services/timemachine.service or run in a container.

# Quotas

To limit the amount of space the TimeMachine will use to backup to, you can create a .plist file in the root of the backup directory. 

```
/usr/libexec/PlistBuddy -c 'Set :GlobalQuota 500000000000' .com.apple.TimeMachine.quota.plist
```

Taken from: http://movq.us/2017/04/09/time-machine-quotas/

# Docker image builds

Repo is auto built here: https://hub.docker.com/r/timjdfletcher/samba-timemachine/
