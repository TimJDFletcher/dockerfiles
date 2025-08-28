
# Tools container

Howto to run the container

```shell
docker run --privileged \
    -v /tmp/dump:/dump \
    --pid="container:$ID" --net="container:$ID" -it  timjdfletcher/toolbox:latest /bin/bash
```
