# Handoff: test dependency refresh locally

Delete this file before merging.

## State

- Goss switched to the official `ghcr.io/goss-org/goss:v0.4.10` image (pinned by digest).
- Pins bumped: Debian `trixie-20260918-slim`, Samba `2:4.24.7+dfsg-1~bpo13+1`, Python `3.13.15-slim`, checkov `3.3.19`, gam7 `7.48.14`, ssh-audit `3.9.0`, supercronic `v0.2.49`, Go `1.27`, Alpine `3.24`.
- `samba-timemachine ./run test` passes. Nothing else has been run yet: the cloud sandbox's TLS proxy breaks registry pulls and downloads inside buildx builds.

## To do (on a local machine with Docker/Colima)

1. Run the test matrix. Fix any failures (usually version strings in `run` or `goss/tests/*.yaml`):
   ```bash
   for d in yajsv checkov gam ssh-audit offlineimap postfix tcpdump; do (cd "$d" && ./run test) || echo "FAIL $d"; done
   (cd toolbox && ./run build)
   (cd spf-flattener && container system start && ./run test)   # macOS only
   ```
2. `cd samba-timemachine && ./run trivy`. If CVE-2026-14456 no longer shows up, remove it from `.trivyignore`.
3. Ask the user: run `bundle update` in `postfix/` and `offlineimap/`, or delete their unused Gemfiles?
4. Delete this file and mark the PR ready.

Don't run `./run release`.
