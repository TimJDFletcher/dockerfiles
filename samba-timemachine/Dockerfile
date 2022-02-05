FROM ubuntu:focal-20220113

ENV SAMBA_VERSION="2:4.13.17~dfsg-0ubuntu0.21.04.1" \
    IPROUTE2_VERSION="5.5.0-1ubuntu1"

ENV BACKUPDIR=/backups
VOLUME /backups

RUN apt-get update && \
    apt-get --no-install-recommends --yes install \
        samba="$SAMBA_VERSION" \
        samba-vfs-modules="$SAMBA_VERSION" \
        iproute2=${IPROUTE2_VERSION} && \
    rm -rf /var/lib/apt/lists/*

ADD samba.conf.tmpl /etc/samba/smb.conf.tmpl
ADD TimeMachine.quota.tmpl /etc/TimeMachine.quota.tmpl

EXPOSE 445/tcp

ADD entrypoint /entrypoint
RUN chmod 0755 /entrypoint

ENTRYPOINT ["/entrypoint"]