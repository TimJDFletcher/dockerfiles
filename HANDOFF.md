# Handoff: dependency refresh (in progress)

Branch: `claude/handoff-continuation-mw9zd6` (continues `claude/repo-overview-ag67db`). Delete this file once the work is merged.

## Already done on this branch (committed)

1. `3c4fe36` docs: root `AGENTS.md` Known Issues now points at `TODO/`; README lists `goss` and `spf-flattener`.
2. `9624bf2` goss: switched every project to the official `ghcr.io/goss-org/goss:v0.4.10@sha256:8d3924f722a04a660e9e6c2403be0399d737c0187fc065714d26b992286c3f0a`, removed the local `goss/` project and TODO 08. See root `AGENTS.md` → "Goss Distribution".
   - **Not fully tested.** The previous sandbox couldn't pull ghcr.io image data or run apt inside containers. Only the goss copy/extract logic was checked, against a stand-in image built from the checksum-verified v0.4.10 release binary. **Run `./run test` for every project that has one.** The list is in `.cursor/skills/dockerfiles-repo-upgrade/SKILL.md`.

## Pin bumps: committed, mostly untested

All pins in the table below were bumped to "Latest", and Samba backports went `2:4.24.5` → `2:4.24.7+dfsg-1~bpo13+1` (checked with `apt-cache policy` on `trixie-20260918-slim`).

Test status (2026-09-26 sandbox):
- `samba-timemachine`: `./run test` **passes** (build-time 22, healthcheck 43, live 27+3+3). This also validates the official goss image in the embedded pattern.
- Every other project: **not tested**. Their `./run` scripts build with the docker-container buildx `builder`, which in the cloud sandbox can't verify the TLS-intercepting proxy's certificate, so registry pulls fail. pip, curl and Go downloads inside builds hit the same CA problem. These have to be run on a normal machine.
- `trivy` isn't installed in the sandbox, so the `.trivyignore` check below is still open.

### Original findings

Latest versions found on 2026-09-26:

| Pin | Current | Latest | Where to change |
|---|---|---|---|
| Debian base | `trixie-20260406-slim` (offlineimap, postfix, tcpdump, toolbox), `trixie-20260824-slim` (samba-timemachine) | `trixie-20260918-slim` | Each `Dockerfile` `ARG DEBIAN_VERSION`; `postfix/AGENTS.md`, `tcpdump/AGENTS.md`, `offlineimap/AGENTS.md`, `samba-timemachine/AGENTS.md:126` |
| Python base | `3.13.13-slim` (checkov, gam, ssh-audit) | `3.13.15-slim` (3.14.7-slim also exists; ask before moving minors) | `Dockerfile` + `AGENTS.md` in each |
| checkov | `3.2.523` | `3.3.19` | `checkov/Dockerfile`, `checkov/run`, `checkov/goss/tests/goss-dockerfile-tests.yaml`, `checkov/AGENTS.md` |
| gam7 | `7.41.0` | `7.48.14` | `gam/Dockerfile`, `gam/run:52` (`grep "GAM 7.41"`), `gam/goss/tests/goss-dockerfile-tests.yaml` (lines 11, 15, 29), `gam/AGENTS.md` |
| ssh-audit | `3.3.0` | `3.9.0` (needs Python >= 3.10, fine) | `ssh-audit/Dockerfile`, `ssh-audit/run`, `ssh-audit/goss/tests/goss-dockerfile-tests.yaml` (`v3.3.0`), `ssh-audit/AGENTS.md` |
| supercronic | `v0.2.44` | `v0.2.49` | `offlineimap/Dockerfile`, `offlineimap/run`, `offlineimap/goss/tests/goss-dockerfile-tests.yaml:30`, `offlineimap/AGENTS.md` |
| Go builder | `1.26` | `1.27` | `yajsv/Dockerfile`, `yajsv/AGENTS.md`; `spf-flattener/Dockerfile`, `spf-flattener/run` (lines 18, 119), `spf-flattener/AGENTS.md` |
| Alpine runtime | `3.23` | `3.24` | `spf-flattener/Dockerfile:25` |
| yajsv | `v1.4.1` | `v1.4.1` | up to date |
| goss | `v0.4.10` | `v0.4.10` | up to date |

### Still to check (the old sandbox couldn't reach these)

- **Samba backports** (`samba-timemachine/Dockerfile` `SAMBA_VERSION="2:4.24.5+dfsg-1~bpo13+1"`): check https://packages.debian.org/trixie-backports/samba and bump `samba` and `smbclient` together.
- **`samba-timemachine/.trivyignore`**: CVE-2026-14456 is ignored until the base image picks up the openssl fix. After moving to `trixie-20260918-slim`, re-run trivy and remove the ignore if the scan is clean.
- **Ruby gems** (`postfix/Gemfile.lock`, `offlineimap/Gemfile.lock`): `bundle outdated` shows updates, including rubocop 1.50→1.91, json 2→3, excon 0→1 and rspec-its 1→2. The upgrade skill says to run `bundle update` in both directories. Nothing in `run` or the Dockerfiles appears to use these files (tests are goss-based), so ask the user whether to update them or delete the Gemfiles.
- **Unpinned images** (not changed; mention to the user): `media/docker-compose.yml` (all `linuxserver/*`, `dperson/torproxy`), `ssh-audit/docker-compose.yml` (`linuxserver/openssh-server:latest`), `tcpdump/docker-compose.yml` (`nginx:alpine`).
- `spf-flattener` builds `SPF_FLATTENER_VERSION="main"`, which is unpinned. It needs Apple's `container` CLI, so it can't be tested on Linux; say so in the summary.

## How to do it

Follow `.cursor/skills/dockerfiles-repo-upgrade/SKILL.md`:

1. Bump the pins.
2. Update the version strings the tests assert.
3. Update the `AGENTS.md` tables.
4. Run `./run test` for yajsv, checkov, gam, ssh-audit, offlineimap, postfix, tcpdump and samba-timemachine, and `./run build` for toolbox.

Run the tests after the version bumps, not before. Don't run `./run release` and don't open a PR unless the user asks.
