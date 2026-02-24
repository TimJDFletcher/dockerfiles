ARG PYTHON_VERSION="3.13.12-slim"
ARG GAM_VERSION="7.34.6"

FROM python:${PYTHON_VERSION}

ARG GAM_VERSION

RUN pip install --no-cache-dir gam7==${GAM_VERSION}

COPY --chmod=0755 entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]

CMD ["--help"]
