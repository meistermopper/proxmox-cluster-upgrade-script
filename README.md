# Proxmox VE Cluster Upgrade Script

Automated, safe, sequential upgrade script for Proxmox VE (PVE) clusters with High Availability (HA) maintenance mode management, guest evacuation checks, package updates, autoremove cleanup, automatic reboots, and multi-channel notifications (Gotify & Telegram).

## Features

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
1. One of your Proxmox cluster nodes (e.g., Node 1).
2. A central management/bastion server (e.g. Ansible host or admin workstation) with network access to all nodes.

### Prerequisites
- SSH key authentication set up for `root` (or sudoer) access across all cluster nodes without password prompts.
- `curl` installed on the host running the script.
- Proxmox VE HA configured (for automatic guest evacuation during maintenance mode).

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

### Dry-Run Test
Run in dry-run mode to verify SSH connectivity and script flow without making changes:
```bash
./cluster-upgrade.sh --dry-run
```

### Full Cluster Upgrade
Run the automated upgrade across all configured nodes:
```bash
./cluster-upgrade.sh
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
