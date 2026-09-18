# Update to the latest goss release and drop the patched-build workaround

Status: open
Section: Future Enhancements
Source: `containers/dockerfiles/samba-timemachine/TODO.md` (migrated 2026-09-17, removed from source repo)

**Update to the latest goss release and drop the patched-build workaround** — The `../goss` sibling project exists solely because goss `v0.4.9` (pinned in `GOSS_VERSION`) shipped vulnerable Go dependencies (`golang.org/x/crypto`), so it's compiled from source with `go get golang.org/x/crypto@latest` applied before build. Check https://github.com/goss-org/goss/releases for a version where those deps are already current upstream — if one exists, this whole multi-stage `COPY --from=goss` build (a separate Dockerfile, its own `./run build`/`test`/`release`, and the `GOSS_IMAGE`/`GOSS_VER` ARGs here) can likely be replaced with a plain pinned-and-checksummed download of the official release binary, same as most other consumers of goss do. Note: this project's own checksum-verification concern (see the completed "No checksum verification for goss binary" item above) was solved *by* switching to a from-source build — reverting to a prebuilt binary means re-adding explicit checksum verification, not just deleting the `../goss` project outright.
