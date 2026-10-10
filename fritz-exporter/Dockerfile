ARG PYTHON_VERSION="3.14.7-alpine"

# Build the wheel from our fork, pinned by commit SHA
FROM python:${PYTHON_VERSION} AS build
ARG FRITZ_EXPORTER_REPO="https://github.com/TimJDFletcher/fritz_exporter.git"
# fritzexporter-v3.5.1-estate.1
ARG FRITZ_EXPORTER_COMMIT="34f597c2a3bd2c60eb2085d91b26afdecca29d4d"

RUN apk add --no-cache build-base libffi-dev openssl-dev rust cargo git && \
    pip install --no-cache-dir --upgrade pip build

WORKDIR /src
RUN git init -q . && \
    git fetch --depth 1 "${FRITZ_EXPORTER_REPO}" "${FRITZ_EXPORTER_COMMIT}" && \
    git checkout -q FETCH_HEAD && \
    test "$(git rev-parse HEAD)" = "${FRITZ_EXPORTER_COMMIT}" && \
    python -m build --wheel

FROM python:${PYTHON_VERSION}

LABEL Name=fritz-exporter
EXPOSE 9787
ENV PIP_NO_CACHE_DIR="true"

COPY --from=build /src/dist/*.whl /tmp/

RUN pip install /tmp/fritz_exporter-*.whl && \
    rm /tmp/fritz_exporter-*.whl

USER 65534:65534
ENTRYPOINT ["python", "-m", "fritzexporter"]
