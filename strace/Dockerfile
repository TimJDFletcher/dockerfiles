FROM debian:trixie-slim
ARG TOOL
ENV TOOL=${TOOL}
RUN apt-get update && apt-get install --no-install-recommends --yes ${TOOL}
COPY --chmod=0755 entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]
CMD ["--help"]
