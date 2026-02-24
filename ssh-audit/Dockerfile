FROM python:3-slim

ARG SSH_AUDIT_VERSION="3.3.0"
ARG GOSS_VER="v0.4.9"
ARG GOSS_DST="/goss"

COPY goss/ ${GOSS_DST}

RUN apt-get update && \
    apt-get install --no-install-recommends --yes curl ca-certificates && \
    pip install --no-cache-dir ssh-audit==${SSH_AUDIT_VERSION} && \
    sh ${GOSS_DST}/goss-installer && \
    apt-get purge --yes curl ca-certificates && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

RUN ${GOSS_DST}/goss --gossfile ${GOSS_DST}/tests/goss-dockerfile-tests.yaml validate

ENTRYPOINT ["ssh-audit"]
CMD ["--help"]
