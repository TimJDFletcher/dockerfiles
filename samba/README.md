# samba-timemachine-docker

This is a docker container that contains the latest (4.8.0-rc2) version of SAMBA built via git and configured to provide Apple "Time Capsule" like backups.

To use the docker container do the following:

```docker build -t . timemachine

docker run -d -t -v /backups/timemachine:/backups -p 445:445 --restart unless-stopped timemachine```

There is a single user called `timemachine` with a password of `password` this could be improved.
