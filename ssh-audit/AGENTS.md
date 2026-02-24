# ssh-audit Agent Documentation

Docker container for [ssh-audit](https://github.com/jtesta/ssh-audit), an SSH server security auditing tool.

## Core Components

| Component | Value |
|-----------|-------|
| Base Image | `python:3.13.12-slim` |
| Package | `ssh-audit==3.3.0` via pip |

## Build Args

| Arg | Default | Description |
|-----|---------|-------------|
| `PYTHON_VERSION` | `3.13.12-slim` | Python base image tag |
| `SSH_AUDIT_VERSION` | `3.3.0` | ssh-audit package version |

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/ssh-audit:tmp` |
| `test` | Run build-time and integration tests |
| `clean` | Remove images and prune builder |
| `release` | Test + multi-arch build/push to Docker Hub |

## Testing

Tests run in two phases. Goss `v0.4.9` is downloaded from GitHub to a shared `goss-bin` Docker volume:

1. **Build-time tests** — Version check and goss validation of binary/help
2. **Integration tests** — docker-compose spins up hardened + weak sshd containers

### Test Architecture

```
docker-compose.yml
├── test-sshd (hardened config)
│   └── Uses test-configs/secure-sshd_config - must pass with exit code 0
├── weak-sshd (intentionally insecure)
│   └── Uses test-configs/weak-sshd_config - must fail with exit code >= 2
└── ssh-audit
    └── Mounts goss-bin volume, runs tests against both servers
```

**Hardened sshd (test-sshd)** validates a secure baseline:
- Strong KEX only (curve25519, sntrup761, DH group16/18)
- Strong ciphers only (chacha20, AES-GCM, AES-CTR)
- Strong MACs only (SHA-256/512-ETM, umac-128-etm)
- No NIST curves, no SHA-1

**Weak sshd (weak-sshd)** validates detection of issues:
- Weak KEX (diffie-hellman-group1-sha1, NIST curves)
- Weak ciphers (3des-cbc, aes*-cbc)
- Weak MACs (hmac-md5, hmac-sha1-96)

Tests verify hardened returns exit 0, weak returns exit >= 2 with `[fail]` in output.

## Usage

```bash
# Audit a server
docker run --rm timjdfletcher/ssh-audit example.com

# Audit with JSON output
docker run --rm timjdfletcher/ssh-audit --json example.com

# Generate a policy from a known-good server
docker run --rm timjdfletcher/ssh-audit --make-policy example.com > policy.txt
```

## Pitfalls & Gotchas

**ssh-audit doesn't support CIDR notation.** Use `-T` with a targets file. Generate IPs with bash brace expansion: `printf '%s\n' 192.168.1.{1..254} > targets.txt`

**`--version` flag doesn't exist.** ssh-audit prints version in the help output header. The `--version` flag returns exit code 255.

**Exit codes indicate audit severity:**
- 0 = No issues
- 1 = Warnings only  
- 2 = Failures found
- 3 = Critical issues

**`-M/--make-policy` requires a filename argument** that doesn't exist yet. It won't write to `/dev/stdout`. Use a temp file instead.

**Argument order matters.** The target host must come last: `ssh-audit -p 2222 --json hostname` (correct), not `ssh-audit hostname -p 2222`.

**Rate limiting on target servers.** When scanning multiple hosts or running repeated tests, sshd may rate-limit connections. Use `--threads 4` to reduce concurrency or `--skip-rate-test` to suppress DHEat vulnerability checks.

**Volume mounts with Colima/Docker Desktop.** File mounts may fail silently. Mount the parent directory instead: `-v $(pwd):/data:ro` then reference `/data/targets.txt`.

## Updating Dependencies

| Dependency | Where to check | Files to update |
|------------|----------------|-----------------|
| ssh-audit | https://pypi.org/project/ssh-audit/ | `Dockerfile`, `run`, `goss/tests/goss-dockerfile-tests.yaml` |
| Python base | https://hub.docker.com/_/python | `Dockerfile` |

After updating, run `./run test` to validate.
