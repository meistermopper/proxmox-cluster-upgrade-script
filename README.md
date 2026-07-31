# Proxmox VE Cluster Upgrade Script

Automated, safe, sequential upgrade script for Proxmox VE (PVE) clusters with High Availability (HA) maintenance mode management, guest evacuation checks, package updates, autoremove cleanup, automatic reboots, and multi-channel notifications (Gotify & Telegram).

## Features

- **Smart Upgrade Mode**: Checks whether package updates or a reboot are actually required before enabling maintenance mode. If a node is already up to date, guest evacuation and node reboot are automatically skipped.
- **HA Maintenance Mode Evacuation**: Enables node maintenance mode before upgrading (`ha-manager node-maintenance enable <node>`), allowing PVE HA to live-migrate VMs and LXCs off the node.
- **Evacuation Monitoring**: Waits for running QEMU VMs and LXC containers to evacuate before proceeding.
- **System Upgrades & Autoremove**: Executes `apt-get update`, `apt-get dist-upgrade -y`, and `apt-get autoremove -y`.
- **Safe Reboot & Quorum Wait**: Reboots the node and polls SSH reachability and cluster quorum (`pvecm status`) before resuming.
- **Automatic Recovery**: Disables node maintenance mode after successful reboot so guests can be migrated back.
- **Multi-Channel Notifications**:
  - **Gotify**: Push notifications with priority tagging (Info, Success, Warning, Error).
  - **Telegram**: Formatted HTML message updates sent directly to your Telegram chat or channel.
- **Dry-Run Mode**: Test your configuration and SSH connectivity safely without performing upgrades or reboots (`--dry-run`).

---

## Architecture & Prerequisites

### Execution Location
You can run this script from:
1. **A central management/bastion server / admin workstation (Recommended)** with SSH access to all cluster nodes.
2. **One of your Proxmox cluster nodes (e.g., Node 1)**:
   > **Important Note:** If running directly on a node that is listed inside the `NODES` array, the script process will be terminated when that node reboots. In this case, place the host node at the **very end** of the `NODES` array or run the script from an external host / HA VM.

### SSH & Sudo Prerequisites
- **SSH Key Authentication**: Public key login without password prompts set up on all target nodes.
- **User Privileges**:
  - **Option A (`root` - Default)**: `SSH_USER="root"` in `config.env`. SSH key placed in `/root/.ssh/authorized_keys` across all nodes.
  - **Option B (Non-Root Sudo User, e.g. `thomas`)**: `SSH_USER="thomas"` and `USE_SUDO=true` in `config.env`.
    The user must be configured on all target nodes in `/etc/sudoers.d/<username>` with passwordless sudo:
    ```bash
    thomas ALL=(ALL) NOPASSWD: ALL
    ```
- `curl` installed on the host running the script (for notifications).
- Proxmox VE HA configured (for automatic live-migration during maintenance mode).

---

## Installation & Setup

1. Clone or download this repository:
   ```bash
   git clone https://github.com/your-username/proxmox-cluster-upgrade.sh.git
   cd proxmox-cluster-upgrade.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x cluster-upgrade.sh
   ```

3. Create your configuration file from the example:
   ```bash
   cp config.env.example config.env
   ```

4. Edit `config.env` with your cluster details:
   ```bash
   NODES=("192.168.1.7" "192.168.1.17" "192.168.1.27")

   # SSH Settings
   SSH_USER="thomas"        # 'root' or a sudo-enabled user
   USE_SUDO=true           # Set to 'true' if SSH_USER is non-root (requires NOPASSWD in sudoers)
   SSH_PORT="22"
   SSH_KEY_PATH=""         # Path to SSH key or leave empty for default SSH agent

   # Enable Gotify (optional)
   GOTIFY_ENABLED=true
   GOTIFY_URL="https://gotify.yourdomain.com"
   GOTIFY_TOKEN="your_token"

   # Enable Telegram (optional)
   TELEGRAM_ENABLED=true
   TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
   TELEGRAM_CHAT_ID="-100123456789"
   ```

---

## Usage

For a detailed quickstart guide, see **[docs/QUICKSTART_en.md](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/docs/QUICKSTART_en.md)**.

### Windows 1-Click Batch Files (In Explorer)
- **[dry-run.bat](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/dry-run.bat)**: Double-click to run dry-run simulation.
- **[run-upgrade.bat](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/run-upgrade.bat)**: Double-click to execute full cluster upgrade (with prompt confirmation).

---

### Terminal (PowerShell / Git Bash)

#### Dry-Run Test
Run in dry-run mode to verify SSH connectivity and script flow without making changes:
```bash
bash ./cluster-upgrade.sh --dry-run
```

#### Full Cluster Upgrade
Run the automated upgrade across all configured nodes:
```bash
bash ./cluster-upgrade.sh
```

### Custom Config File
Use a specific configuration file:
```bash
./cluster-upgrade.sh --config /path/to/custom-config.env
```

---

## Command Line Options

| Option | Long Option | Description |
| :--- | :--- | :--- |
| `-c` | `--config FILE` | Specify path to custom `config.env` file |
| `-d` | `--dry-run` | Simulate operations without making changes or rebooting |
| `-h` | `--help` | Display script usage instructions |

---

## License

MIT License. Free to use and modify.
