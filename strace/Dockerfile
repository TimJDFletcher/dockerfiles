FROM debian:trixie-slim
ARG TOOL 
RUN apt-get update && apt-get install --no-install-recommends --yes ${TOOL}
ENTRYPOINT ["${TOOL}"]
CMD ["--help"]
