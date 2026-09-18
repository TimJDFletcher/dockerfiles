# Default password baked into image layers

Status: open
Section: Security
Source: `containers/dockerfiles/samba-timemachine/TODO.md` (migrated 2026-09-17, removed from source repo)

**Default password baked into image layers** — `ENV PASS="password"` in the Dockerfile embeds a trivially guessable default into every layer. Consider removing the default to force users to set one, or generating a random default at container start.

## Live check (2026-09-17) — confirmed live on both deployments

This isn't just a theoretical default — both live deployments (sulphur
and carbon) are actually still running with `PASS=password`, the
un-overridden Dockerfile default (see the sibling `docker inspect`
ticket). Recommend prioritizing a real password on both hosts alongside
whatever code fix lands here — changing the compose file's env var on
each host is independent of, and faster than, redesigning the
secrets-file mechanism this ticket is really about.

## Live check (2026-09-18)

Re-checked both hosts: still `PASS=password` on sulphur and carbon.
Unchanged, still fully open.
