# Changelog

All notable changes to this project will be documented in this file.  
> **Note:** For older releases, see **[CHANGELOG_OLD.md](CHANGELOG_OLD.md)**.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
## 1.1.1 (2026-08-01)

### Added
- Automated AI commit message hook via Gemini (`gemini-2.5-flash`) and Husky (`utils/ai-commit-hook.js`).

## [1.1.0] - 2026-07-31

### Added
- Automatically prefer Windows native `ssh.exe` when running under Git Bash/Windows to seamlessly integrate with Windows SSH Agent.
- SSH ControlMaster connection multiplexing support for faster SSH commands on Linux/macOS.
- Default `(Y/n)` confirmation prompt choice (pressing Enter defaults to `Yes`) in `run-upgrade.bat`.

### Fixed
- Fixed Proxmox HA manager maintenance mode CLI command syntax (`ha-manager crm-command node-maintenance enable/disable`).

## [1.0.0] - 2026-07-31

### Added
- Automated sequential Proxmox VE cluster upgrade workflow with HA maintenance mode.
- Cluster Pre-Flight Health Check (`check_cluster_health`): Verifies cluster quorum and HA status before upgrade.
- Emergency Signal Handler: Catches `SIGINT`/`SIGTERM` interrupts and automatically disables HA maintenance mode for node recovery.
- Smart Upgrade mode (`SMART_UPGRADE`): Pre-checks package availability and pending reboot before guest evacuation.
- Single node targeting (`-n`/`--node`): Upgrade specific individual nodes on demand.
- Non-root SSH support (`USE_SUDO`): Enables execution with unprivileged SSH users (e.g. `username`) using passwordless sudo.
- Multi-channel notification support for Gotify and Telegram.
- Windows 1-click execution helper batch files (`run-dryrun.bat`, `run-upgrade.bat`).
- Detailed multilingual quickstart guides in German and English (`docs/QUICKSTART_de.md`, `docs/QUICKSTART_en.md`).
- GitHub Actions CI workflow for automated ShellCheck linting and syntax verification.
