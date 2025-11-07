FROM golang:1.25 AS builder

RUN go install --ldflags '-linkmode external -extldflags "-static"' github.com/neilpa/yajsv@latest

FROM scratch 
ARG TOOL

COPY --from=builder  "/go/bin/yajsv" /yajsv

ENTRYPOINT ["/yajsv"]
