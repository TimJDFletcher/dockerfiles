# `.dockerignore` is empty

Status: open
Section: Speed
Source: `containers/dockerfiles/samba-timemachine/TODO.md` (migrated 2026-09-17, removed from source repo)

**`.dockerignore` is empty** — The entire build context (including `AGENTS.md`, `TODO.md`, `run`, `docker-compose*.yml`, `.git/`) is sent to the Docker daemon on every build. Populate `.dockerignore` to exclude unnecessary files.
