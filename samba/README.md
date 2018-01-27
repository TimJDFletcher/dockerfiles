# samba-timemachine-docker

This is a docker container that contains the latest (4.8.0-rc2) version of SAMBA built via git and configured to provide Apple "Time Capsule" like backups.

To use the docker container do the following:

```
docker build -t . timemachine
docker run -d -t -v /backups/timemachine:/backups -p 445:445 --restart unless-stopped timemachine
```

There is a single user called `timemachine` with a password of `password` this could be improved.

The container only runs smbd to find it on the network the best way is avahi (mDNS) there is an example service file included. This can be copied to /etc/avahi/services/timemachine.service or run in a container.
