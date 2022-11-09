FROM debian:bookworm-20221024-slim

ENV SAMBA_VERSION="2:4.17.2+dfsg-8"

ENV BACKUPDIR=/backups
VOLUME /backups

RUN apt update && \
    apt --no-install-recommends --yes install \
        samba="$SAMBA_VERSION" \
        samba-vfs-modules="$SAMBA_VERSION"  && \
    rm -rf /var/lib/apt/lists/*

ADD samba.conf.tmpl /etc/samba/smb.conf.tmpl
ADD TimeMachine.quota.tmpl /etc/TimeMachine.quota.tmpl

EXPOSE 445/tcp

ADD entrypoint /entrypoint
RUN chmod 0755 /entrypoint

ENTRYPOINT ["/entrypoint"]
