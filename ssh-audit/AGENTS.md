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
├── test-sshd (linuxserver/openssh-server)
│   └── Healthcheck: nc -z localhost 2222
└── ssh-audit
    └── Runs goss tests against test-sshd
```

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
