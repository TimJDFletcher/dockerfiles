# TODO

## Bugs

None currently tracked.

## Security

- [ ] **Password visible via `docker inspect`** — The `PASS` environment variable is readable by anyone with access to `docker inspect`. Support reading the password from a file (e.g. `/run/secrets/samba_password`) as a Docker secrets alternative.
- [ ] **Default password baked into image layers** — `ENV PASS="password"` in the Dockerfile embeds a trivially guessable default into every layer. Consider removing the default to force users to set one, or generating a random default at container start.
- [ ] **No capability dropping in compose files** — The container runs with full default Linux capabilities. Add `cap_drop: [ALL]` and add back only what Samba needs.

## Speed

- [ ] **`.dockerignore` is empty** — The entire build context (including `AGENTS.md`, `TODO.md`, `run`, `docker-compose*.yml`, `.git/`) is sent to the Docker daemon on every build. Populate `.dockerignore` to exclude unnecessary files.

## Ease of Use

- [ ] **External volume requires manual pre-creation** — `docker-compose.yml` declares the backups volume as `external: true`, meaning users must run `docker volume create samba-timemachine_backups` before `docker compose up`. Remove `external: true` for the dev compose file or document the requirement prominently.
- [ ] **`backup-check.sh` depends on `curl` but `curl` is purged from the image** — The script is copied into the backup volume but will fail if run inside the container since `curl` is removed during build. Document that this script is meant to be run from the host.

## Completed

- [x] **No checksum verification for goss binary** — Fixed: goss is now built from source via the `../goss` project with patched Go dependencies.
- [x] **Goss copy invalidates apt layer cache** — Fixed: goss binary is copied from pre-built image, tests are copied after apt install.
- [x] **Duplicate `[Install]` section in `systemd-unit.service`** — Fixed and improved: added RestartSec, TimeoutStartSec, non-fatal pull, journal logging, cleanup on stop.
- [x] **Stale `QUOTA` env var in `docker-compose-autoheal.yml`** — Fixed: file removed.
- [x] **Inconsistency between compose files** — Fixed: removed `docker-compose-autoheal.yml`.
- [x] **Port mapping mismatch in compose file** — Fixed: `target` is now `10445` (container), `published` is now `445` (host).
- [x] **Password exposed in healthcheck commands** — Fixed: entrypoint creates `/run/samba/credentials` file, goss tests use `-A` flag instead of `-U user%pass`.
