#!/bin/bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

USERNAME="timemachine"
TM_UID=999
TM_GID=999
INSTALL_DIR="/opt/samba-timemachine"
BACKUP_DIR="/data/timemachine"
SYSTEMD_UNIT="timemachine.service"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Install samba-timemachine as a systemd service.

Options:
  --uid UID         UID for timemachine user (default: $TM_UID)
  --gid GID         GID for timemachine group (default: $TM_GID)
  --install-dir DIR Installation directory (default: $INSTALL_DIR)
  --backup-dir DIR  Backup storage directory (default: $BACKUP_DIR)
  --help            Show this help

Example:
  $0 --backup-dir /mnt/backups --uid 1000 --gid 1000
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --uid) TM_UID="$2"; shift 2 ;;
        --gid) TM_GID="$2"; shift 2 ;;
        --install-dir) INSTALL_DIR="$2"; shift 2 ;;
        --backup-dir) BACKUP_DIR="$2"; shift 2 ;;
        --help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

echo "=== Samba Time Machine Setup ==="
echo ""
echo "Configuration:"
echo "  User:        $USERNAME (UID: $TM_UID, GID: $TM_GID)"
echo "  Install dir: $INSTALL_DIR"
echo "  Backup dir:  $BACKUP_DIR"
echo ""

echo "Creating system user: $USERNAME"
if id "$USERNAME" &>/dev/null; then
    echo "  User $USERNAME already exists, skipping creation"
else
    if getent group "$TM_GID" &>/dev/null; then
        echo "  GID $TM_GID already exists, reusing"
    else
        groupadd --system --gid "$TM_GID" "$USERNAME"
    fi
    useradd --system --uid "$TM_UID" --gid "$TM_GID" \
        --home-dir "$BACKUP_DIR" --no-create-home \
        --shell /usr/sbin/nologin "$USERNAME"
    echo "  User $USERNAME created"
fi

echo "Adding $USERNAME to docker group"
usermod -aG docker "$USERNAME"

echo "Creating directories"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BACKUP_DIR"

echo "Setting ownership"
chown "$USERNAME":"$USERNAME" "$INSTALL_DIR"
chown "$TM_UID":"$TM_GID" "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

echo "Copying files to $INSTALL_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cp "$SCRIPT_DIR/docker-compose.yml" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/systemd-unit.service" "$INSTALL_DIR/"
chown -R "$USERNAME":"$USERNAME" "$INSTALL_DIR"

echo "Creating .env file"
cat > "$INSTALL_DIR/.env" <<EOF
PUID=$TM_UID
PGID=$TM_GID
USER=timemachine
# PASS=changeme
LOG_LEVEL=1
FORCE_PERMISSIONS_RESET=false
EOF
chown "$USERNAME":"$USERNAME" "$INSTALL_DIR/.env"
chmod 600 "$INSTALL_DIR/.env"

echo "Updating docker-compose.yml for local paths"
sed -i "s|external: true|external: false|" "$INSTALL_DIR/docker-compose.yml"

echo "Creating Docker volume for backups"
if docker volume inspect samba-timemachine_backups &>/dev/null; then
    echo "  Volume already exists, skipping"
else
    docker volume create \
        --driver local \
        --opt type=none \
        --opt device="$BACKUP_DIR" \
        --opt o=bind \
        samba-timemachine_backups
    echo "  Volume created"
fi

echo "Installing systemd unit"
cat > "/etc/systemd/system/$SYSTEMD_UNIT" <<EOF
[Unit]
Description=Time Machine backup server (Docker)
Documentation=https://github.com/TimJDFletcher/dockerfiles/tree/main/samba-timemachine
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=10
TimeoutStartSec=300
TimeoutStopSec=120
WorkingDirectory=$INSTALL_DIR
User=$USERNAME
Group=docker

ExecStartPre=-/usr/bin/docker compose pull
ExecStart=/usr/bin/docker compose up --remove-orphans
ExecStop=/usr/bin/docker compose down --remove-orphans
ExecReload=/usr/bin/docker compose up --detach --remove-orphans

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SYSTEMD_UNIT"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Summary:"
echo "  User:       $USERNAME (UID: $TM_UID, GID: $TM_GID, in docker group)"
echo "  Install:    $INSTALL_DIR"
echo "  Backups:    $BACKUP_DIR"
echo "  Service:    $SYSTEMD_UNIT (enabled)"
echo ""
echo "Next steps:"
echo "  1. Edit $INSTALL_DIR/.env to set PASS=<your-password>"
echo "  2. Run 'systemctl start $SYSTEMD_UNIT' to start the service"
echo "  3. Configure avahi for mDNS discovery (see avahi.service)"
echo ""
echo "Useful commands:"
echo "  systemctl status $SYSTEMD_UNIT"
echo "  journalctl -u $SYSTEMD_UNIT -f"
