# Build goss from source with updated dependencies
# Usage: COPY --from=timjdfletcher/goss:latest /goss /path/to/goss

ARG GO_VERSION="1.26"
ARG GOSS_VERSION="v0.4.9"

FROM golang:${GO_VERSION} AS builder

ARG GOSS_VERSION

WORKDIR /build

# Clone goss and update vulnerable dependencies before building
RUN git clone --depth 1 --branch ${GOSS_VERSION} https://github.com/goss-org/goss.git . && \
    go get golang.org/x/crypto@latest && \
    go mod tidy && \
    CGO_ENABLED=0 go build \
        -ldflags "-s -w -X github.com/goss-org/goss/util.Version=${GOSS_VERSION}-patched" \
        -o /goss \
        ./cmd/goss

# Verify the build
RUN /goss --version

# Minimal final image with just the binary
FROM scratch

COPY --from=builder /goss /goss

ENTRYPOINT ["/goss"]
