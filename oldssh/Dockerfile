FROM debian:11

RUN apt-get update && \
    apt-get install --no-install-recommends --yes \
        openssh-client && \
    rm -rf /var/cache/apt/*

RUN adduser --disabled-password -u 501 --gecos '' oldssh
USER oldssh

ENTRYPOINT ["/usr/bin/ssh"]
CMD ["-V"]
