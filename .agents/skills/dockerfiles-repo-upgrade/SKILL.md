---
name: dockerfiles-repo-upgrade
description: >-
  Upgrades pinned Docker base images, pip/GitHub/apt dependencies, Ruby lockfiles,
  and matching tests/docs across this dockerfiles monorepo, then runs the full
  ./run test (and ./run build where applicable) suite before considering the work
  done. Use when the user asks to upgrade all dependencies, bump images to latest,
  refresh pins, run a repo-wide dependency refresh, or validate after version bumps.
  After `goss`, fan out parallel `./run test` / `./run build` for independent projects.
---

# Dockerfiles monorepo — full dependency upgrade

## Preconditions (read first)

1. **Read** repository [`.cursorrules`](../../../.cursorrules) and the relevant [`AGENTS.md`](../../../AGENTS.md) / `<project>/AGENTS.md` for conventions (pins, `./run`, security).
2. **Docker on this machine uses Colima.** If `docker info`, `docker build`, or `docker buildx imagetools inspect` fails with *Cannot connect to the Docker daemon* (or Colima not running), run:

   ```bash
   colima start
   ```

   Wait until it reports ready. Default socket is typically `~/.colima/default/docker.sock` (context may switch to `colima` automatically).

## Scope of “upgrade everything”

Touch every place versions are pinned or asserted:

| Kind | Where to look |
|------|----------------|
| Base images | Each `<project>/Dockerfile` — `ARG DEBIAN_VERSION`, `ARG PYTHON_VERSION`, `ARG GO_VERSION`, `FROM` lines |
| Pip / GitHub releases | Same Dockerfiles; `<project>/run` when it duplicates a version for tests |
| Goss / integration | `<project>/goss/tests/*.yaml`, `run` scripts that `grep` version strings |
| Docs | `<project>/AGENTS.md` tables that mirror pins; root [`AGENTS.md`](../../../AGENTS.md) / [`.cursorrules`](../../../.cursorrules) only if they cite example tags |
| Ruby tests | `postfix/Gemfile.lock`, `offlineimap/Gemfile.lock` — run `bundle update` from those directories |

Projects with Dockerfiles (inventory may drift): `checkov`, `gam`, `goss`, `postfix`, `samba-timemachine`, `spf-flattener`, `ssh-audit`, `tcpdump`, `toolbox`, `offlineimap`, `yajsv`.

**Build order:** build **`goss`** before **`samba-timemachine`** (timemachine copies `timjdfletcher/goss:tmp` / `latest`).

## How to resolve “latest” versions

- **PyPI** (checkov, gam7, ssh-audit): `curl -fsSL "https://pypi.org/pypi/<package>/json"` → `info.version`. Prefer **`/usr/bin/python3`** for one-line JSON parsing if `python3` is hijacked by asdf and fails in pipes.
- **GitHub releases** (e.g. supercronic, yajsv, goss): `https://api.github.com/repos/<org>/<repo>/releases/latest` → `tag_name`.
- **Docker Hub tags / digests** (Debian dated slim, Python slim): `docker buildx imagetools inspect <image:tag>` — read `org.opencontainers.image.version` / manifest dates. For Debian **dated** tags (`trixie-YYYYMMDD-slim`), probe tags with `imagetools inspect` until “not found”; pick the newest **existing** dated tag (not every calendar day is published).
- **Debian apt pins** (e.g. Samba in backports): confirm the full package version string still exists, e.g. packages.debian.org trixie-backports page or `apt-cache policy` **inside** a container built from the target Debian tag. Bump **both** `samba` and `smbclient` to the same source version when both are pinned.

## Edit checklist (per bump)

1. Update **`Dockerfile`** `ARG` defaults (and any duplicated pins in `run`).
2. Update **goss** / **run** assertions so expected version substrings match real CLI output (`gam version`, `checkov --version`, `supercronic --version`, etc.).
3. Update **`AGENTS.md`** tables that document the same pins (avoid stale docs).
4. **`bundle update`** in `postfix/` and `offlineimap/` when Ruby deps should move forward; commit resulting **`Gemfile.lock`** changes.

## Mandatory: test after every upgrade

**Do not treat an upgrade as finished until tests have been run and pass** (or you have fixed failures and re-run). Guessing version strings or skipping Docker because the daemon was down is not acceptable: start Colima (`colima start`), then execute the suite below.

### Full matrix (run in this order)

1. **`goss`** — `./run test` (other images copy or extract this binary.)
2. **`yajsv`**, **`checkov`**, **`gam`**, **`ssh-audit`**, **`offlineimap`**, **`postfix`**, **`tcpdump`**, **`samba-timemachine`** — each: `./run test`
3. **`toolbox`** — no `test` target; run **`./run build`**
4. **`spf-flattener`** — `./run test` uses Apple’s **`container`** CLI (not Docker). Start the system service first: **`container system start`** (see [`spf-flattener/AGENTS.md`](../../../spf-flattener/AGENTS.md)). If the CLI or service is unavailable, state explicitly that spf-flattener was not tested and why.

### Fan-out testing (parallel)

To save wall-clock time, **fan out** independent test jobs after dependencies are satisfied—e.g. launch multiple terminal/agent tasks in parallel, or run several `(cd … && ./run test) &` then `wait`.

**Dependency waves (do not parallelize across these boundaries):**

| Wave | Projects | Notes |
|------|-----------|--------|
| 1 | `goss` | Must complete first; other images extract or `COPY --from` this build. |
| 2 | `yajsv`, `checkov`, `gam`, `ssh-audit`, `offlineimap`, `postfix`, `tcpdump`, `toolbox` (`./run build` only) | No ordering among these; safe to run **in parallel**. |
| 3 | `samba-timemachine` | Run after wave 1 (needs `timjdfletcher/goss:tmp` or equivalent). |
| 4 | `spf-flattener` | Apple Container only; can run in parallel with wave 2–3 **if** `container system start` has been run and the host has capacity. |

Re-run any failed project alone (then its dependents) after fixing; optionally re-run the full matrix for confidence.

Example loop (Docker projects only):

```bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel)"
for d in goss yajsv checkov gam ssh-audit offlineimap postfix tcpdump samba-timemachine; do
  echo "========== $d =========="
  (cd "$REPO/$d" && ./run test)
done
(cd "$REPO/toolbox" && ./run build)
```

### Rules

- Run **`./run test`** for **every** project that defines it, not only projects whose files you edited (shared bases or goss can surface regressions elsewhere).
- If a test fails, fix pins, goss expectations, or scripts, then **re-run the full matrix** (or at minimum the failed project and any upstream dependency such as `goss`).
- Do not **`./run release`** or push unless the user asks.

## Repo-specific gotchas

- **`spf-flattener`**: Apple **`container`** + **`container system start`**; Colima DNS issues for Docker are documented in [`spf-flattener/AGENTS.md`](../../../spf-flattener/AGENTS.md). Keep builder/final image pins explicit (avoid bare `alpine:latest` for reproducibility).
- **Pins over floating tags**: Prefer dated Debian tags and explicit Python slim tags over bare `trixie-slim` / `python:3-slim` in Dockerfiles unless the project intentionally documents otherwise.
- **Cost / plan rules**: If the workspace requires a cost estimate in a *plan*, follow that rule separately; this skill does not replace workspace rules.

## After the upgrade

Summarize what changed (images, pip versions, GitHub tags, Gem major bumps), **list which `./run test` / `./run build` commands succeeded**, and note anything skipped (e.g. spf-flattener without `container`, already-latest pins, unpinned stacks like `media/`).
