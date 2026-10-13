#!/bin/bash
# Write Time Machine backup metrics in Prometheus text format.
#
# Usage: backup-metrics.sh <output-file> <backup-dir> [client-address]
#
# Run by the entrypoint at start and by Samba's postexec when a client
# disconnects from the share. A loopback client-address (the container's own
# healthcheck) exits without writing, so the healthcheck doesn't rewrite the
# file each minute.
#
# The file is written to a unique temp file in the same directory and renamed
# into place, so readers and concurrent runs never see a partial file. If the
# backup directory can't be read, only the success gauge (0) and the previous
# last-success time are written (no bundle or volume values), and the script
# exits 1.

set -u -o pipefail

OUTPUT_FILE="$1"
BACKUP_DIR="$2"
CLIENT_ADDRESS="${3:-}"

case "${CLIENT_ADDRESS}" in
    127.*|::1|::ffff:127.*) exit 0 ;;
esac

TMP_FILE=$(mktemp "${OUTPUT_FILE}.XXXXXX") || exit 1
trap 'rm -f "${TMP_FILE}"' EXIT

# Escape a Prometheus label value: backslash, double quote, newline
escape_label() {
    local value="${1//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "${value//$'\n'/\\n}"
}

# Each sparsebundle is read from the plists the Mac keeps at its top level
# and a listing of its bands; the band files themselves are never opened or
# stat'd, so a run costs the same however large the backups are.

# Print the completion time (epoch seconds) of the bundle's newest snapshot,
# or nothing if it has no completed backup. If the history can't be parsed,
# fall back to when it was last written.
last_backup() {
    local history="$1/com.apple.TimeMachine.SnapshotHistory.plist" newest

    [ -r "${history}" ] || return 0
    newest=$(grep -o '<date>[^<]*' "${history}" | cut -c7- | sort | tail -n 1)
    if [ -n "${newest}" ] && date -u -d "${newest}" +%s 2>/dev/null; then
        return 0
    fi
    stat -c %Y "${history}" 2>/dev/null
}

# Print the bundle's size as its band count times the band size in
# Info.plist, or nothing if either can't be read. Bands are sparse, so this
# is an upper bound on the disk space used.
bundle_size() {
    local band_size bands

    band_size=$(sed -n '/<key>band-size<\/key>/{n;s/.*<integer>\([0-9][0-9]*\)<\/integer>.*/\1/p;}' "$1/Info.plist" 2>/dev/null)
    [[ "${band_size}" =~ ^[0-9]+$ && -d "$1/bands" ]] || return 0
    bands=$(find "$1/bands" -ignore_readdir_race -type f 2>/dev/null | wc -l)
    echo $((band_size * bands))
}

collect_bundle_metrics() {
    local bundles bundle name value count=0
    local backup="" size=""

    bundles=$(find "${BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d -name '*.sparsebundle' -printf '%f\n' | sort) || return 1

    while IFS= read -r bundle; do
        [ -n "${bundle}" ] || continue
        name=$(escape_label "${bundle%.sparsebundle}")
        value=$(last_backup "${BACKUP_DIR}/${bundle}")
        [ -z "${value}" ] || backup+="timemachine_bundle_last_backup_timestamp_seconds{bundle=\"${name}\"} ${value}"$'\n'
        value=$(bundle_size "${BACKUP_DIR}/${bundle}")
        [ -z "${value}" ] || size+="timemachine_bundle_size_bytes{bundle=\"${name}\"} ${value}"$'\n'
        count=$((count + 1))
    done <<< "${bundles}"

    echo "# HELP timemachine_bundle_last_backup_timestamp_seconds Completion time of the newest snapshot in the sparsebundle."
    echo "# TYPE timemachine_bundle_last_backup_timestamp_seconds gauge"
    printf '%s' "${backup}"
    echo "# HELP timemachine_bundle_size_bytes Size of the sparsebundle, estimated as its band count times its band size."
    echo "# TYPE timemachine_bundle_size_bytes gauge"
    printf '%s' "${size}"
    echo "# HELP timemachine_bundles Number of sparsebundles in the backup directory."
    echo "# TYPE timemachine_bundles gauge"
    echo "timemachine_bundles ${count}"
}

collect_volume_metrics() {
    local available size

    read -r available size < <(df -B1 --output=avail,size "${BACKUP_DIR}" | tail -n 1) || return 1
    [[ "${available}" =~ ^[0-9]+$ && "${size}" =~ ^[0-9]+$ ]] || return 1

    echo "# HELP timemachine_volume_available_bytes Space available to the backups on the filesystem holding the backup directory."
    echo "# TYPE timemachine_volume_available_bytes gauge"
    echo "timemachine_volume_available_bytes ${available}"
    echo "# HELP timemachine_volume_size_bytes Size of the filesystem holding the backup directory."
    echo "# TYPE timemachine_volume_size_bytes gauge"
    echo "timemachine_volume_size_bytes ${size}"
}

now=$(date +%s)

if metrics=$(collect_bundle_metrics 2>/dev/null && collect_volume_metrics 2>/dev/null); then
    success=1
    last_success="${now}"
else
    success=0
    metrics=""
    last_success=$(awk '$1 == "timemachine_metrics_last_success_timestamp_seconds" { print $2 }' "${OUTPUT_FILE}" 2>/dev/null)
    last_success="${last_success:-0}"
fi

{
    [ -z "${metrics}" ] || printf '%s\n' "${metrics}"
    echo "# HELP timemachine_metrics_success Whether the last metrics run could read the backup directory."
    echo "# TYPE timemachine_metrics_success gauge"
    echo "timemachine_metrics_success ${success}"
    echo "# HELP timemachine_metrics_last_success_timestamp_seconds Time of the last metrics run that could read the backup directory."
    echo "# TYPE timemachine_metrics_last_success_timestamp_seconds gauge"
    echo "timemachine_metrics_last_success_timestamp_seconds ${last_success}"
} > "${TMP_FILE}" || exit 1

chmod 0644 "${TMP_FILE}" && mv -f "${TMP_FILE}" "${OUTPUT_FILE}" || exit 1

[ "${success}" -eq 1 ]
