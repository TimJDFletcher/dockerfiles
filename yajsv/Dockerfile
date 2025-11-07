FROM golang:1.25 AS builder

RUN go install --ldflags '-linkmode external -extldflags "-static"' github.com/neilpa/yajsv@latest
RUN /go/bin/yajsv -v

FROM scratch 
ARG TOOL

COPY --from=builder  "/go/bin/yajsv" /yajsv

ENTRYPOINT ["/yajsv"]
CMD ["-v"]
