@echo off
title Proxmox Cluster Upgrade - Dry Run
echo ==================================================
echo Starting Proxmox Cluster Upgrade (DRY-RUN MODE)
echo ==================================================
echo.
bash ./cluster-upgrade.sh --dry-run
echo.
pause
