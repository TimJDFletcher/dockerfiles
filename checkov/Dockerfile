ARG PYTHON_VERSION="3.13.12-slim"
ARG CHECKOV_VERSION="3.2.506"

FROM python:${PYTHON_VERSION}

ARG CHECKOV_VERSION

RUN pip install --no-cache-dir checkov==${CHECKOV_VERSION}

COPY --chmod=0755 entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]

CMD ["--help"]
