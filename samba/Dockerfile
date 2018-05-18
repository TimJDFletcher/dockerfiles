FROM debian:stable-20180213

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends --yes install \
        acl \
        attr \
        autoconf \
        bind9utils \
        bison \
        build-essential \
        ca-certificates \
        debhelper \
        dnsutils \
        docbook-xml \
        docbook-xsl \
        flex \
        gdb \
        git \
        krb5-user \
        libacl1-dev \
        libaio-dev \
        libarchive-dev \
        libattr1-dev \
        libblkid-dev \
        libbsd-dev \
        libcap-dev \
        libcups2-dev \
        libgnutls28-dev \
        libgpgme11-dev \
        libjansson-dev \
        libjson-perl \
        libldap2-dev \
        libncurses5-dev \
        libpam0g-dev \
        libparse-yapp-perl \
        libpopt-dev \
        libreadline-dev \
        nettle-dev \
        perl \
        perl-modules \
        pkg-config \
        python-all-dev \
        python-crypto \
        python-dbg \
        python-dev \
        python-dnspython \
        python-gpgme \
        python-markdown \
        python3-dev \
        python3-dnspython \
        python3-gpgme \
        python3-markdown \
        xsltproc \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ENV SMBPATH /samba
ENV GITTAG samba-4.8.2

RUN mkdir -p $SMBPATH
RUN git clone https://git.samba.org/samba.git $SMBPATH/source \
        && cd $SMBPATH/source \
        && git checkout tags/$GITTAG \
    && ./configure --prefix=$SMBPATH --disable-cups --without-ad-dc \
        && make -j$(nproc) \
        && make -j$(nproc) install \
    && rm -rf $SMBPATH/source

ADD samba.conf $SMBPATH/etc/smb.conf
RUN $SMBPATH/bin/testparm -s

EXPOSE 445/tcp
ENV BACKUPDIR /backups

ADD entrypoint /entrypoint
RUN chmod 0755 /entrypoint

ENTRYPOINT ["/entrypoint"]
