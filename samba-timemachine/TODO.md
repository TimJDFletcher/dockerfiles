# TODO

## Bugs

- [ ] **Port mapping mismatch in compose files** — `docker-compose.yml` and `docker-compose-autoheal.yml` both map `target: 445` but Samba listens on port `10445` inside the container (`smb ports = 10445` in `samba.conf.tmpl`). `target` should be `10445`. The goss tests don't catch this because they run inside the container via `docker compose exec` and connect to `127.0.0.1:10445` directly, bypassing Docker's port mapping.

## Security

- [ ] **Password visible via `docker inspect`** — The `PASS` environment variable is readable by anyone with access to `docker inspect`. Support reading the password from a file (e.g. `/run/secrets/samba_password`) as a Docker secrets alternative.
- [ ] **Password exposed in healthcheck commands** — The goss healthcheck runs `smbclient -U user%password` which is visible in `/proc/*/cmdline` and `docker inspect`. Use an `smbclient` credentials file (`-A /tmp/.smbcredentials`) instead.
- [ ] **Default password baked into image layers** — `ENV PASS="password"` in the Dockerfile embeds a trivially guessable default into every layer. Consider removing the default to force users to set one, or generating a random default at container start.
- [ ] **No checksum verification for goss binary** — `goss/goss-installer` downloads the goss binary over HTTPS but does not verify a SHA256 checksum. Adding verification would guard against supply-chain attacks.
- [ ] **No capability dropping in compose files** — The container runs with full default Linux capabilities. Add `cap_drop: [ALL]` and add back only what Samba needs.

## Speed

- [ ] **`.dockerignore` is empty** — The entire build context (including `AGENTS.md`, `README.md`, `run`, `docker-compose*.yml`, `.git/`, `docs/`) is sent to the Docker daemon on every build. Populate `.dockerignore` to exclude unnecessary files.
- [ ] **Goss copy invalidates apt layer cache** — `COPY goss/ /goss` happens before `RUN apt-get install`, so any change to a goss test file busts the entire package install cache. Consider splitting: copy only `goss/goss-installer` first for the install step, then copy test files in a later layer.

## Ease of Use

- [ ] **External volume requires manual pre-creation** — `docker-compose.yml` declares the backups volume as `external: true`, meaning users must run `docker volume create samba-timemachine_backups` before `docker compose up`. Remove `external: true` for the dev compose file or document the requirement prominently.
- [ ] **Duplicate `[Install]` section in `systemd-unit.service`** — The file has two identical `[Install]` blocks.
- [ ] **Stale `QUOTA` env var in `docker-compose-autoheal.yml`** — References a `QUOTA` variable that no longer exists in the codebase.
- [ ] **Inconsistency between compose files** — `docker-compose.yml` uses env var substitution with defaults; `docker-compose-autoheal.yml` hardcodes values and uses a non-external volume.
- [ ] **`backup-check.sh` depends on `curl` but `curl` is purged from the image** — The script is copied into the backup volume but will fail if run inside the container since `curl` is removed during build.
