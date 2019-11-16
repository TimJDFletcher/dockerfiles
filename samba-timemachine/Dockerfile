FROM debian:buster-20191014-slim

ENV SAMBA_VERSION "2:4.9.5+dfsg-5+deb10u1"
ENV BACKUPDIR /backups

RUN apt-get update && \
    apt-get --no-install-recommends --yes install \
        samba="$SAMBA_VERSION" \
        samba-vfs-modules="$SAMBA_VERSION" \
        iproute2 && \ 
    rm -rf /var/lib/apt/lists/* && \
    touch /etc/samba/users.map

ADD samba.conf /etc/samba/smb.conf
ADD TimeMachine.quota.tmpl /etc/TimeMachine.quota.tmpl

EXPOSE 445/tcp

ADD entrypoint /entrypoint
RUN chmod 0755 /entrypoint

ENTRYPOINT ["/entrypoint"]
