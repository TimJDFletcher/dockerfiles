# TODO

## Medium Priority

- [ ] **Upgrade stale base images** — `offlineimap` and `postfix` use Debian bullseye from 2020-2022; upgrade to bookworm or trixie
- [ ] **Fix checkov Dockerfile style** — Replace `ADD` with `COPY`, use `COPY --chmod=` instead of separate `chmod`

## Low Priority

- [ ] **Add `./run` script** — `media` (optional; uses docker compose directly)
