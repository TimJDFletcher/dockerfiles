# `backup-check.sh` depends on `curl` but `curl` is purged from the image

Status: open
Section: Ease of Use
Source: `containers/dockerfiles/samba-timemachine/TODO.md` (migrated 2026-09-17, removed from source repo)

**`backup-check.sh` depends on `curl` but `curl` is purged from the image** — The script is copied into the backup volume but will fail if run inside the container since `curl` is removed during build. Document that this script is meant to be run from the host.

## Live check (2026-09-17)

Confirmed on both sulphur and carbon: `backup-check.sh` present in the
running container at `/backups/backup-check.sh` and `/scripts/
backup-check.sh`, and `curl` is genuinely absent (`which curl` empty) in
both. Confirmed still fully open, exactly as described, on both live
deployments.
