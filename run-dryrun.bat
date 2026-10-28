@echo off
title Proxmox Cluster Upgrade - Dry Run
echo ==================================================
echo Starting Proxmox Cluster Upgrade (DRY-RUN MODE)
echo ==================================================
echo.
if exist "%ProgramFiles%\Git\bin\bash.exe" (
    "%ProgramFiles%\Git\bin\bash.exe" ./cluster-upgrade.sh --dry-run
) else (
    bash ./cluster-upgrade.sh --dry-run
)
echo.
pause
