# Build spf-flattener from source
# Usage: docker run --rm timjdfletcher/spf-flattener --domain example.com

ARG GO_VERSION="1.24"
ARG SPF_FLATTENER_VERSION="main"

FROM golang:${GO_VERSION} AS builder

ARG SPF_FLATTENER_VERSION

WORKDIR /build

RUN git clone --depth 1 --branch ${SPF_FLATTENER_VERSION} \
        https://github.com/letsencrypt/spf-flattener.git . && \
    CGO_ENABLED=0 go build \
        -ldflags "-s -w" \
        -o /spf-flatten \
        ./cmd/spf-flatten

# Verify the build
RUN /spf-flatten --help

# Minimal final image with just the binary
FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=builder /spf-flatten /spf-flatten

ENTRYPOINT ["/spf-flatten"]
