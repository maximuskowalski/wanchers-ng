#!/usr/bin/env bash

# https://github.com/maximuskowalski/wanchers-ng
# https://github.com/maximuskowalski/wanchers-ng/blob/main/install-wanchors-ng.sh

# Dynamically set INSTALL_DIR to the directory from which the script is run
INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Define other constants
SERVICE_DIR="/etc/systemd/system"
LOGROTATE_DIR="/etc/logrotate.d"
LOGROTATE_NAME="wanchors-ng"
SERVICE_NAME="wanchors-ng.service"
TIMER_NAME="wanchors-ng.timer"
LOGROTATE_CONF="logrotate.conf.sample"
ENV_SAMPLE=".env.sample"
ENV_FILE=".env"

# Function to check if running as root
check_root() {
  if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script as root. Exiting."
    exit 1
  fi
}

# Function to ensure .env file exists and source it
source_env() {
  if [ ! -f "$INSTALL_DIR/$ENV_FILE" ]; then
    echo ".env file does not exist. Creating one from the sample. Please edit the .env file as necessary and re-run this script."
    cp "$INSTALL_DIR/$ENV_SAMPLE" "$INSTALL_DIR/$ENV_FILE"
    exit 1  # Exit the script to allow the user to edit the .env file
  fi
  # shellcheck source=/dev/null
  source "$INSTALL_DIR/$ENV_FILE"
}

# Function to copy files to their respective locations and set .sh files as executable
copy_files() {
  sudo chmod +x "$INSTALL_DIR/"*.sh
  sudo cp "$INSTALL_DIR/$SERVICE_NAME" "$SERVICE_DIR/"
  sudo cp "$INSTALL_DIR/$TIMER_NAME" "$SERVICE_DIR/"
  sudo cp "$INSTALL_DIR/$LOGROTATE_CONF" "$LOGROTATE_DIR/$LOGROTATE_NAME"
}

# Function to replace placeholders in configuration files
modify_configs() {
  # Update service file to point to the correct script location
  sudo sed -i "s|ExecStart=SCRIPT_LOCATION|ExecStart=$INSTALL_DIR/wanchors-ng.sh|g" "$SERVICE_DIR/$SERVICE_NAME"

  # Update User and Group in service file
  sudo sed -i "s|User=PLACEHOLDER|User=$USER_NAME|g" "$SERVICE_DIR/$SERVICE_NAME"
  sudo sed -i "s|Group=PLACEHOLDER|Group=$USER_NAME|g" "$SERVICE_DIR/$SERVICE_NAME"

  # Update TIMER_INTERVAL in timer file
  sudo sed -i "s|TIMER_INTERVAL|$TIMER_INTERVAL|g" "$SERVICE_DIR/$TIMER_NAME"

  # Update logrotate configuration
  sudo sed -i "s|LOGFILE_PLACEHOLDER|$LOG_FILE|g" "$LOGROTATE_DIR/$LOGROTATE_NAME"
  sudo sed -i "s|create 644 USER_GROUP_PLACEHOLDER|create 644 $USER_NAME $USER_NAME|g" "$LOGROTATE_DIR/$LOGROTATE_NAME"
}

# Function to reload systemd daemon and start timer
start_services() {
  sudo systemctl daemon-reload
  sudo systemctl enable "$TIMER_NAME"
  sudo systemctl start "$TIMER_NAME"
  echo "Installation complete. The timer has been enabled and started."
}

# Main function to execute all steps
main() {
  check_root
  source_env
  copy_files
  modify_configs
  start_services
}



main
