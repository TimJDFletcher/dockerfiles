
# yajsv container

Docker packaged build of [yajsv](https://github.com/neilpa/yajsv)

Howto to run the container

```shell
docker run -it \
	-v ./:/scan \
	timjdfletcher/yajsv:latest -s /scan/schema.json -r /scan/doc.yaml

```
