ARG PYTHON_VERSION="3.13.15-slim"
ARG GAM_VERSION="7.48.14"

FROM python:${PYTHON_VERSION}

ARG GAM_VERSION

RUN pip install --no-cache-dir gam7==${GAM_VERSION}

COPY --chmod=0755 entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]

CMD ["--help"]
