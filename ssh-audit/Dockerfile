ARG PYTHON_VERSION="3.13.12-slim"
ARG SSH_AUDIT_VERSION="3.3.0"

FROM python:${PYTHON_VERSION}

ARG SSH_AUDIT_VERSION

RUN pip install --no-cache-dir ssh-audit==${SSH_AUDIT_VERSION}

ENTRYPOINT ["ssh-audit"]
CMD ["--help"]
