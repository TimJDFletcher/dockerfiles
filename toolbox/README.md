
# Tools container

Howto to run the container

```shell
docker run --cap-add SYS_PTRACE --cap-add SYS_ADMIN \
    -v /tmp/dump:/dump \
    --pid="container:$ID" --net="container:$ID" -it  debian:trixie-slim /bin/bash
```
