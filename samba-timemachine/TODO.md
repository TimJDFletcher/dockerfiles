# TODO

## Bugs

None currently tracked.

## Security

- [ ] **Password visible via `docker inspect`** — The `PASS` environment variable is readable by anyone with access to `docker inspect`. Support reading the password from a file (e.g. `/run/secrets/samba_password`) as a Docker secrets alternative.
- [ ] **Default password baked into image layers** — `ENV PASS="password"` in the Dockerfile embeds a trivially guessable default into every layer. Consider removing the default to force users to set one, or generating a random default at container start.

## Speed

- [ ] **`.dockerignore` is empty** — The entire build context (including `AGENTS.md`, `TODO.md`, `run`, `docker-compose*.yml`, `.git/`) is sent to the Docker daemon on every build. Populate `.dockerignore` to exclude unnecessary files.

## Ease of Use

- [ ] **External volume requires manual pre-creation** — `docker-compose.yml` declares the backups volume as `external: true`, meaning users must run `docker volume create samba-timemachine_backups` before `docker compose up`. Remove `external: true` for the dev compose file or document the requirement prominently.
- [ ] **`backup-check.sh` depends on `curl` but `curl` is purged from the image** — The script is copied into the backup volume but will fail if run inside the container since `curl` is removed during build. Document that this script is meant to be run from the host.

## Future Enhancements

- [ ] **Rootless operation** — Run the container without root privileges. Challenges include backup directory ownership (init container?), UID/GID mapping, and setting smbpasswd without root. One approach: bake a fixed UID/GID user at build time.
- [ ] **Configurable listen port** — Make the SMB port configurable via environment variable. Requires templating the port in `smb.conf.tmpl` and goss tests.
- [ ] **Update to the latest goss release and drop the patched-build workaround** — The `../goss` sibling project exists solely because goss `v0.4.9` (pinned in `GOSS_VERSION`) shipped vulnerable Go dependencies (`golang.org/x/crypto`), so it's compiled from source with `go get golang.org/x/crypto@latest` applied before build. Check https://github.com/goss-org/goss/releases for a version where those deps are already current upstream — if one exists, this whole multi-stage `COPY --from=goss` build (a separate Dockerfile, its own `./run build`/`test`/`release`, and the `GOSS_IMAGE`/`GOSS_VER` ARGs here) can likely be replaced with a plain pinned-and-checksummed download of the official release binary, same as most other consumers of goss do. Note: this project's own checksum-verification concern (see the completed "No checksum verification for goss binary" item above) was solved *by* switching to a from-source build — reverting to a prebuilt binary means re-adding explicit checksum verification, not just deleting the `../goss` project outright.

## Completed

- [x] **No checksum verification for goss binary** — Fixed: goss is now built from source via the `../goss` project with patched Go dependencies.
- [x] **Goss copy invalidates apt layer cache** — Fixed: goss binary is copied from pre-built image, tests are copied after apt install.
- [x] **Duplicate `[Install]` section in `systemd-unit.service`** — Fixed and improved: added RestartSec, TimeoutStartSec, non-fatal pull, journal logging, cleanup on stop.
- [x] **Stale `QUOTA` env var in `docker-compose-autoheal.yml`** — Fixed: file removed.
- [x] **Inconsistency between compose files** — Fixed: removed `docker-compose-autoheal.yml`.
- [x] **Port mapping mismatch in compose file** — Fixed: both `target` and `published` are now `10445` to allow running alongside existing Samba servers.
- [x] **Password exposed in healthcheck commands** — Fixed: entrypoint creates `/run/samba/credentials` file, goss tests use `-A` flag instead of `-U user%pass`.
- [x] **No capability dropping in compose files** — Fixed: `cap_drop: ALL` with only CHOWN, DAC_OVERRIDE, FOWNER, SETGID, SETUID added back. Drops 9 default capabilities.
