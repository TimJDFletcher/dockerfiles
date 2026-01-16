# Samba-TimeMachine Agent Documentation

This document provides a comprehensive technical overview of the `samba-timemachine` project for AI agents. It covers the container's architecture, configuration, developer workflow, and testing methodology.

## 1. Project Goal

The project provides a Docker container running a Samba server configured to emulate an Apple Time Capsule. This allows macOS clients to perform Time Machine backups to a network share provided by the container.

## 2. Core Components & Technology

*   **Base Image:** `debian:trixie-slim`
*   **Core Service:** `samba` (from `trixie-backports` for a newer version)
*   **Templating:** `envsubst` (from `gettext-base`) is used to generate configuration files from templates.
*   **Testing & Health Checks:** `goss` is used for build-time validation, live integration tests, and runtime health checks.
*   **Orchestration:** The project is managed via the `./run` shell script and Docker Compose.

## 3. Container Configuration (Runtime)

The container's behavior is controlled by environment variables, which are substituted into templates by the `entrypoint` script.

| Variable    | Description                                     | Default       | Used In                               |
|-------------|-------------------------------------------------|---------------|---------------------------------------|
| `USER`      | The username for the Time Machine share.        | `timemachine` | `entrypoint`, `smb.conf.tmpl`         |
| `PASS`      | The password for the Time Machine user.         | `password`    | `entrypoint` (for `smbpasswd`)        |
| `PUID`      | The Unix User ID (UID) of the user.             | `999`         | `entrypoint` (for `useradd`, `chown`) |
| `PGID`      | The Unix Group ID (GID) of the user.            | `999`         | `entrypoint` (for `groupadd`, `chown`)|
| `LOG_LEVEL` | The Samba logging level.                        | `1`           | `smb.conf.tmpl`                       |
| `BACKUPDIR` | The internal path for the backup volume.        | `/backups`    | `entrypoint`, `smb.conf.tmpl`         |

## 4. Container Initialization (`entrypoint` script)

The `entrypoint` script is responsible for setting up the container environment at startup. The order of operations is critical:

1.  **`checkBackupDir`:** Ensures the `${BACKUPDIR}` directory exists.
2.  **`configureSAMBA`:** Uses `envsubst` to create `/etc/samba/smb.conf` from `/templates/smb.conf.tmpl`. This must happen before user creation.
3.  **`createUser`:** Creates the group and user with the specified `PGID` and `PUID`. It then sets the user's Samba password using `smbpasswd`.
4.  **`configureBackupDir`:**
    *   Sets ownership of `${BACKUPDIR}` to `${PUID}:${PGID}`.
    *   Creates metadata files: `.com.apple.TimeMachine.supported` and `.metadata_never_index`.
    *   Generates a `README.md` inside the backup directory.
5.  **`startSMB`:** Starts the `smbd` process in the foreground, passing any additional command-line arguments.

## 5. Developer Workflow (`./run` script)

The `./run` script is the primary interface for managing the project.

*   **`./run build`**: Builds the Docker image locally with the tag `timjdfletcher/samba-timemachine:tmp`.
*   **`./run up`**: Builds the image and starts the container using `docker compose up`.
*   **`./run down`**: Stops and removes the container using `docker compose down`.
*   **`./run exec`**: Starts the container (if not running) and opens a `bash` shell inside it.
*   **`./run test`**: The main testing command. It performs the following steps:
    1.  Sets specific test environment variables (`PUID=1234`, `USER=testuser`, etc.).
    2.  Calls `./run up` to start the container with these variables.
    3.  Waits for the container to pass its health check.
    4.  Executes the `goss-live-tests.yaml` and `goss-healthcheck-tests.yaml` suites inside the running container.
    5.  Calls `./run down` to clean up.
*   **`./run trivy`**: Builds the image and runs a `trivy` scan for high/critical vulnerabilities.
*   **`./run release`**: The release process. It runs the `test` and `trivy` commands, then builds and pushes a multi-platform (`linux/amd64`, `linux/arm64`) image to Docker Hub, tagged with the current Git tag and `latest`.

## 6. Testing & Validation (`goss`)

The project uses `goss` to define the expected state of the container in different phases. The tests act as executable specifications.

### `goss-dockerfile-tests.yaml` (Build-time)
This runs during `docker build` to validate the image itself, *before* the entrypoint has run.
*   **Verifies:** `entrypoint` script and template files exist with correct permissions.
*   **Ensures:** Generated config files like `/etc/samba/smb.conf` do *not* exist yet.
*   **Checks:** Required packages (`samba`) are installed and build-time packages (`curl`) have been removed.

### `goss-healthcheck-tests.yaml` (Runtime Health)
This is used for the `HEALTHCHECK` instruction in the `Dockerfile`. It performs a lightweight check to ensure the service is operational.
*   **Verifies:** The `smbd` process is running.
*   **Checks:** Port `10445` is listening.
*   **Validates:** The generated `smb.conf` is syntactically correct via `testparm`.
*   **Integration Test:** Performs an `smbclient` loopback connection to create and delete a directory, proving that authentication, networking, and permissions are working correctly.

### `goss-live-tests.yaml` (Live Integration)
This is a more comprehensive test suite run by the `./run test` command. It validates the container's state against the specific test variables set by the `run` script.
*   **Verifies:** Correct user/group creation with the test `PUID`/`PGID`.
*   **Validates:** The `smb.conf` contains the correct values for `log level`, `path`, etc.
*   **Integration Test:** Similar to the health check, it uses `smbclient` to confirm write access to the share.
