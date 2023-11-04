#!/usr/bin/env bash

# https://github.com/maximuskowalski/wanchers-ng
# https://github.com/maximuskowalski/wanchers-ng/blob/main/wanchers-ng.sh


# Determine script directory dynamically
INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load environment variables
# shellcheck source=/dev/null
source "$INSTALL_DIR/.env"

# Configuration
notification_count_file="/tmp/notification_count"  # To persist notification_count
mount_missing_file="/tmp/mount_missing"  # To persist mount_missing flag

# Function to send Apprise notifications
send_notification() {
  local msg="$1"
  if [[ -z "$webhook_url" || "$webhook_url" == "YOUR_WEBHOOK_URL_HERE" ]]; then
    echo "Time: $(date). ERROR: webhook URL is not set or is invalid." >> "${LOGFILE}"
    return 1
  fi
  echo "Time: $(date). Sending notification: $msg" >> "${LOGFILE}"
  if ! apprise "$webhook_url" --title "wancherALERT $thisserver" --input-format=html --body "$msg"; then
    echo "Time: $(date). ERROR: Failed to send notification with apprise." >> "${LOGFILE}"
    return 1
  fi
}

# Function to manage Docker containers
manage_docker() {
  local action=$1
  for container in "${docker_containers[@]}"; do
    local args=("$action" "$container")
    [[ -n $2 ]] && args+=("-t" "$2")
    error_msg=$(docker "${args[@]}" 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "Time: $(date). ERROR: Failed to ${action} container ${container}. Error: ${error_msg}" >> "${LOGFILE}"
    else
      echo "Time: $(date). SUCCESS: Successfully ${action}ed container ${container}." >> "${LOGFILE}"
    fi
  done
}

# Function to handle recovery actions
handle_recovery() {
  manage_docker "stop" 120
  if ! sudo mount -a; then
    echo "Time: $(date). ERROR: Failed to remount filesystems." >> "${LOGFILE}"
  fi

  if (( notification_count % 6 == 0 )); then
    send_notification "Mounts are down. Attempting to fix."
  fi

  ((++notification_count))
  echo "true" > "$mount_missing_file"  # Save the mount_missing flag
}

# Function to check and remount fstab mounts
check_and_remount_fstab_anchors() {
  for anchor in "${!fstab_anchors[@]}"; do
    if [[ ! -f "$anchor" ]]; then
      local mount_point="${fstab_anchors[$anchor]}"
      echo "Time: $(date). Missing anchor file for fstab mount $mount_point, attempting to remount." >> "${LOGFILE}"
      if ! sudo mount "$mount_point"; then
        echo "Time: $(date). ERROR: Failed to remount fstab mount point: $mount_point." >> "${LOGFILE}"
        # Optionally, send a notification about the failure here
      else
        echo "Time: $(date). SUCCESS: Successfully remounted fstab mount point: $mount_point." >> "${LOGFILE}"
        # Optionally, send a notification about the success here
      fi
    fi
  done
}

# Function to manage systemd mounts
restart_systemd_mount() {
  local mount_unit=$1
  echo "Time: $(date). Attempting to restart systemd mount: ${mount_unit}" >> "${LOGFILE}"
  if ! sudo systemctl restart "${mount_unit}"; then
    echo "Time: $(date). ERROR: Failed to restart systemd mount unit: ${mount_unit}." >> "${LOGFILE}"
    return 1
  fi
  echo "Time: $(date). SUCCESS: Successfully restarted systemd mount unit: ${mount_unit}." >> "${LOGFILE}"
}

# Main function
main() {
  if [[ -e "$LOCKFILE" ]]; then
    echo "Time: $(date). Lock file exists, exiting." >> "${LOGFILE}"
    exit 1
  fi

  touch "$LOCKFILE"

  # Load previous notification_count and mount_missing flag if available
  if [[ -f "$notification_count_file" ]]; then
    notification_count=$(<"$notification_count_file")
  else
    notification_count=0
  fi

  if [[ -f "$mount_missing_file" ]]; then
    was_mount_missing=$(<"$mount_missing_file")
  else
    was_mount_missing=false
  fi

  # Quick exit if anchor exists and no recovery needed
  if [[ -f "$anchorfile" && "$was_mount_missing" == "false" ]]; then
    rm -f "$LOCKFILE"
    exit 0
  fi

  # Check new anchor file
  if [[ ! -f "$anchorfile" ]]; then
    handle_recovery
  else
    if [[ "$was_mount_missing" == "true" ]]; then
      manage_docker "restart"
      send_notification "Mounts were down but have been successfully recovered."
      notification_count=0  # Reset the count
    fi
    echo "false" > "$mount_missing_file"  # Save the mount_missing flag
  fi

  # Save notification_count
  echo "$notification_count" > "$notification_count_file"

  rm -f "$LOCKFILE"
}

echo "Script run at $(date)"  >> "${LOGFILE}"
main
