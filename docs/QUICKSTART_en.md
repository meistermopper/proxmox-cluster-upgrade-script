# Proxmox VE Cluster Upgrade - Quick Start & Command Guide

This guide provides a quick overview of all execution methods for the upgrade script.

> **💡 Smart Upgrade Mode:** The script automatically checks whether package updates or a reboot are pending before processing each node. Nodes that are already up to date are skipped automatically (no guest evacuation, no reboot).

---

## 🖱️ 1. Double-Click Execution on Windows (Easiest)

You can launch the script on Windows directly by double-clicking helper batch files in File Explorer:

* **[dry-run.bat](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/dry-run.bat)**:
  Executes a **dry-run** simulation. No actual package upgrades or node reboots will be performed. The terminal window stays open after execution so you can review the logs.
  
* **[run-upgrade.bat](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/run-upgrade.bat)**:
  Initiates the **real cluster upgrade**. Prompts for confirmation (`y/N`) before running to prevent accidental execution.

---

## 💻 2. Terminal Commands (PowerShell / Git Bash)

Open your terminal in the script directory and run:

### Dry-Run Test Mode
```powershell
bash ./cluster-upgrade.sh --dry-run
```

### Real Cluster Upgrade
```powershell
bash ./cluster-upgrade.sh
```

### Custom Configuration File
```powershell
bash ./cluster-upgrade.sh --config /path/to/your_config.env
```

---

## ⚡ 3. PowerShell Function Shortcuts (Optional)

If you prefer shorter commands in your PowerShell session, add these functions temporarily or to your PowerShell profile:

```powershell
# Shortcut for dry-run simulation:
function pve-dry { bash ./cluster-upgrade.sh --dry-run }

# Shortcut for real cluster upgrade:
function pve-upgrade { bash ./cluster-upgrade.sh }
```

After adding these, simply run `pve-dry` or `pve-upgrade` in your terminal!
