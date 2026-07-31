@echo off
title Proxmox Cluster Upgrade - Real Upgrade
echo ==================================================
echo PROXMOX VE CLUSTER UPGRADE
echo ==================================================
echo.
echo WARNING: This will upgrade packages and reboot all configured cluster nodes sequentially!
echo.
set "CONFIRM=y"
set /p CONFIRM="Are you sure you want to run the REAL upgrade? (Y/n): "
if /i "%CONFIRM%"=="y" (
    echo.
    echo Starting upgrade...
    bash ./cluster-upgrade.sh
) else (
    echo.
    echo Upgrade cancelled by user.
)
echo.
pause
