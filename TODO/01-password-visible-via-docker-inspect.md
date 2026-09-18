# Password visible via `docker inspect`

Status: open
Section: Security
Source: `containers/dockerfiles/samba-timemachine/TODO.md` (migrated 2026-09-17, removed from source repo)

**Password visible via `docker inspect`** — The `PASS` environment variable is readable by anyone with access to `docker inspect`. Support reading the password from a file (e.g. `/run/secrets/samba_password`) as a Docker secrets alternative.

## Live check (2026-09-17) — elevated priority, live security exposure

Checked both live deployments: `docker inspect` on the running
`timemachine-samba-timemachine-1` container on **both sulphur and
carbon** shows `PASS=password` in plain env — not just readable in
principle, but actually still set to the Dockerfile's literal default
value on both production backup targets (see the sibling ticket,
"Default password baked into image layers" — the two issues compound
here: nobody has ever overridden the default on either live deployment).
Anyone with `docker inspect` access to sulphur or carbon (or shell
access as a user in the `docker` group) can currently read this
password in one command. Recommend treating this as higher priority than
a general code-quality backlog item — it's a live, unremediated exposure
on two hosts, not just a hypothetical.

## Live check (2026-09-18)

Re-checked both hosts: `docker inspect timemachine-samba-timemachine-1`
still shows `PASS=password` on sulphur and carbon. Unchanged, still
fully open, still a live exposure.
