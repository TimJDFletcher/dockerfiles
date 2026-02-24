# ssh-audit Agent Documentation

Docker container for [ssh-audit](https://github.com/jtesta/ssh-audit), an SSH server security auditing tool.

## Core Components

* **Base Image:** `python:3-slim`
* **Package:** `ssh-audit` via pip (pinned version)
* **Testing:** `goss` for build-time and integration validation

## Environment Variables

None required. ssh-audit is stateless.

## Developer Workflow (`./run`)

| Command | Description |
|---------|-------------|
| `build` | Build local image tagged `timjdfletcher/ssh-audit:tmp` |
| `test` | Run integration tests against a test sshd container |
| `clean` | Remove images and prune builder |
| `release` | Test + multi-arch build/push to Docker Hub |

## Testing (`goss`)

Two test suites:

* **`goss-dockerfile-tests.yaml`** (build-time) — Validates ssh-audit binary exists, version matches, help works
* **`goss-integration-tests.yaml`** (integration) — Runs ssh-audit against a live sshd container (standard and JSON output modes)

### Test Architecture

```
docker-compose.yml
├── test-sshd (hardened config)
│   └── Uses test-configs/secure-sshd_config - must pass with exit code 0
├── weak-sshd (intentionally insecure)
│   └── Uses test-configs/weak-sshd_config - must fail with exit code >= 2
└── ssh-audit
    └── Runs goss tests against both servers
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

The `./run test` command:
1. Builds the ssh-audit image
2. Starts both containers via docker-compose
3. Waits for test-sshd healthcheck
4. Runs goss integration tests from inside ssh-audit container
5. Tears down the environment

## Usage

```bash
# Audit a server
docker run --rm timjdfletcher/ssh-audit example.com

# Audit with JSON output
docker run --rm timjdfletcher/ssh-audit --json example.com

# Generate a policy from a known-good server
docker run --rm timjdfletcher/ssh-audit --make-policy example.com > policy.txt
```

## Updating Dependencies

| Dependency | ARG | Where to check latest |
|------------|-----|----------------------|
| ssh-audit | `SSH_AUDIT_VERSION` | https://pypi.org/project/ssh-audit/ |
| Goss | `GOSS_VER` | https://github.com/goss-org/goss/releases/latest |

After updating, run `./run test` to validate.
