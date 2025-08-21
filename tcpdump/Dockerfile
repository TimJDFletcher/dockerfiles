FROM debian:trixie-slim
RUN apt-get update && apt-get install --no-install-recommends --yes tcpdump
ENTRYPOINT ["tcpdump"]
CMD ["-i eth0"]
