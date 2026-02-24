ARG GO_VERSION="1.25"
FROM golang:${GO_VERSION} AS builder

ARG YAJSV_VERSION="v1.4.1"

RUN go install -ldflags "-linkmode external -extldflags '-static' -X main.version=${YAJSV_VERSION}" github.com/neilpa/yajsv@${YAJSV_VERSION}
RUN /go/bin/yajsv -v

FROM scratch

COPY --from=builder "/go/bin/yajsv" /yajsv

ENTRYPOINT ["/yajsv"]
CMD ["-v"]
