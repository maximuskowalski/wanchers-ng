# Wanchers-NG

## Description

Wanchers-NG is a Linux utility that monitors the state of a mount by checking for a user-defined anchor file at specified intervals. It can automatically manage Docker containers based on the mount's state and notify you if any issues are detected and rectified.

## Table of Contents

- [Wanchers-NG](#wanchers-ng)
  - [Description](#description)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Configuration](#configuration)
    - [Understanding the .env File](#understanding-the-env-file)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Contributing](#contributing)
  - [License](#license)

## Prerequisites

- Linux-based Operating System
- Bash shell
- [Docker](https://www.docker.com/)
- [Apprise](https://github.com/caronc/apprise)

## Configuration

1. Create Installation Directory

The suggested location for the installation is /opt/scripts/misc/wanchers-ng/. You can change this to a directory of your choosing.

    ```bash
    sudo mkdir -p /opt/scripts/misc/
    sudo chown $USER:$USER /opt/scripts/misc/ -R`
    ```

Clone the Repository

    ```bash
    git clone https://github.com/maximuskowalski/wanchers-ng.git /opt/scripts/misc/
    ```

1. Navigate to the directory containing the script.

        ```bash
        cd /opt/scripts/misc/wanchers-ng/
        ```

2. Copy `.env.sample` to `.env`.

        ```bash
        cp .env.sample .env
        ```

3. Edit `.env` and fill in the necessary variables.
    To edit the .env file or any script, you can use a text editor like nano:

        ```bash
        nano .env
        ```

### Understanding the .env File

Here is a breakdown of each setting in the `.env` file:

- `USER_NAME`: User for the systemd service (e.g., `john`) Default is fine and will use your current username.
- `LOGFILE`: Path for the log file (e.g., `/opt/scripts/misc/wanchers-ng/newwanchors.log`)
- `webhook_url`: Webhook URL for notifications (e.g., `https://discord.com/api/webhooks/123/abc`)
- `thisserver`: Hostname for Discord notification (e.g., `myServer`)
- `new_anchor`: Path to the anchor file (e.g., `/mnt/storage/.mystorage`)
- `docker_containers`: Array of Docker container names to manage (e.g., `("plex" "emby")`)
- `TIMER_INTERVAL`: Interval for the systemd timer (e.g., `5min`)

## Installation

1. Ensure that the installer script is executable:

        ```bash
        chmod +x install-wanchors-ng.sh
        ```

2. Run the installer script.

        ```bash
        ./install-wanchors-ng.sh
        ```

## Usage

Once the installation is complete, the timer will start automatically.

To check the log file in real-time, you can use:

    ```bash
    tail -f /opt/scripts/misc/wanchers-ng/wanchorsng.log
    ```

To check the status:

    ```bash
    sudo systemctl status wanchors.timer
    ```

## Contributing

Feel free to open issues or pull requests to improve the project.

## License

This project is licensed under the MIT License. See the LICENSE.md file for details.
