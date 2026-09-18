# Rootless operation

Status: open
Section: Future Enhancements
Source: `containers/dockerfiles/samba-timemachine/TODO.md` (migrated 2026-09-17, removed from source repo)

**Rootless operation** — Run the container without root privileges. Challenges include backup directory ownership (init container?), UID/GID mapping, and setting smbpasswd without root. One approach: bake a fixed UID/GID user at build time.
