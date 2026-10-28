#!/usr/bin/env bash
# ==============================================================================
# Proxmox VE Cluster Upgrade Script
# Automated sequential upgrade of Proxmox VE nodes with HA maintenance,
# guest evacuation, reboot, autoremove, and Gotify/Telegram notifications.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.env"
DRY_RUN=false
SINGLE_NODE=""

# Default settings (can be overridden by config.env)
NODES=("192.168.1.7" "192.168.1.17" "192.168.1.27")
SSH_USER="root"
SSH_PORT="22"
SSH_KEY_PATH=""
USE_SUDO=false
SMART_UPGRADE=true

EVACUATION_TIMEOUT=300
EVACUATION_CHECK_INTERVAL=10

REBOOT_TIMEOUT=600
REBOOT_CHECK_INTERVAL=15

GOTIFY_ENABLED=false
GOTIFY_URL=""
GOTIFY_TOKEN=""
GOTIFY_PRIORITY=5

TELEGRAM_ENABLED=false
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# Helper function: Print Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -c, --config FILE    Path to custom configuration file (default: ./config.env)
  -d, --dry-run        Simulate commands without executing changes/reboots
  -n, --node NODE      Target a specific single node (IP or hostname)
  -h, --help           Show this help message and exit

EOF
    exit 0
}

# Parse Command Line Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift 1
            ;;
        -n|--node)
            SINGLE_NODE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Load configuration file if present
if [[ -f "$CONFIG_FILE" ]]; then
    # Source configuration safely
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    echo "[WARNING] Configuration file '$CONFIG_FILE' not found. Using script defaults."
fi

# Override NODES array if single node option (-n/--node) was passed
if [[ -n "$SINGLE_NODE" ]]; then
    NODES=("$SINGLE_NODE")
fi

# Determine SSH Binary (prefer ssh.exe under Windows/Git Bash to leverage Windows SSH Agent)
SSH_BINARY="ssh"
if command -v ssh.exe >/dev/null 2>&1; then
    SSH_BINARY="ssh.exe"
fi

# Determine curl Binary (prefer curl.exe under Windows/WSL/Git Bash to leverage Windows network stack)
CURL_BINARY="curl"
if command -v curl.exe >/dev/null 2>&1; then
    CURL_BINARY="curl.exe"
fi

# SSH Options Builder
get_ssh_opts() {
    local opts=(-p "$SSH_PORT" -o "StrictHostKeyChecking=accept-new" -o "ConnectTimeout=10")
    
    # Enable ControlMaster multiplexing on Linux/macOS or MSYS ssh (skip for native Windows ssh.exe)
    if [[ "$SSH_BINARY" != "ssh.exe" ]]; then
        local cm_dir="${HOME}/.ssh/sockets"
        mkdir -p "$cm_dir" 2>/dev/null || true
        opts+=(
            -o "ControlMaster=auto"
            -o "ControlPath=${cm_dir}/cm-%r@%h-%p"
            -o "ControlPersist=10m"
        )
    fi

    if [[ -n "$SSH_KEY_PATH" ]]; then
        opts+=("-i" "$SSH_KEY_PATH")
    fi
    echo "${opts[@]}"
}

# Execute SSH Command
run_ssh() {
    local target="$1"
    shift
    local cmd="$*"
    local ssh_opts
    read -r -a ssh_opts <<< "$(get_ssh_opts)"

    local remote_cmd="$cmd"
    if [[ "${USE_SUDO:-false}" == true ]]; then
        remote_cmd="sudo $cmd"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] SSH to ${SSH_USER}@${target}: ${remote_cmd}"
        return 0
    fi

    # shellcheck disable=SC2029
    "$SSH_BINARY" "${ssh_opts[@]}" "${SSH_USER}@${target}" "$remote_cmd"
}

# Notification Service
send_notification() {
    local level="$1"   # INFO, WARNING, ERROR, SUCCESS
    local title="$2"
    local message="$3"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    local full_title="[PVE Upgrade] [${level}] ${title}"
    local formatted_msg="[${timestamp}] ${message}"

    # Gotify Notification
    if [[ "${GOTIFY_ENABLED}" == true ]] && [[ -n "${GOTIFY_URL}" ]] && [[ -n "${GOTIFY_TOKEN}" ]]; then
        local priority="${GOTIFY_PRIORITY}"
        case "$level" in
            WARNING) priority=7 ;;
            ERROR)   priority=10 ;;
            SUCCESS) priority=5 ;;
            INFO)    priority=3 ;;
        esac

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY-RUN] Gotify Notification -> Priority: ${priority} | Title: ${full_title} | Msg: ${formatted_msg}"
        else
            "$CURL_BINARY" -s -f --connect-timeout 5 --max-time 10 -X POST "${GOTIFY_URL}/message?token=${GOTIFY_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{\"title\": \"${full_title}\", \"message\": \"${formatted_msg}\", \"priority\": ${priority}}" > /dev/null || \
                echo "[WARNING] Failed to send Gotify notification."
        fi
    fi

    # Telegram Notification
    if [[ "${TELEGRAM_ENABLED}" == true ]] && [[ -n "${TELEGRAM_BOT_TOKEN}" ]] && [[ -n "${TELEGRAM_CHAT_ID}" ]]; then
        local icon="ℹ️"
        case "$level" in
            WARNING) icon="⚠️" ;;
            ERROR)   icon="🚨" ;;
            SUCCESS) icon="✅" ;;
            INFO)    icon="ℹ️" ;;
        esac

        local tg_text="${icon} <b>${full_title}</b>%0A${formatted_msg}"

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY-RUN] Telegram Notification -> Title: ${full_title} | Msg: ${formatted_msg}"
        else
            "$CURL_BINARY" -s -f --connect-timeout 5 --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -d "chat_id=${TELEGRAM_CHAT_ID}" \
                -d "text=${tg_text}" \
                -d "parse_mode=HTML" > /dev/null || \
                echo "[WARNING] Failed to send Telegram notification."
        fi
    fi
}

# Logging Helper
log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    case "$level" in
        INFO)    echo -e "\e[34m[INFO] [${timestamp}] ${msg}\e[0m" ;;
        SUCCESS) echo -e "\e[32m[SUCCESS] [${timestamp}] ${msg}\e[0m" ;;
        WARNING) echo -e "\e[33m[WARNING] [${timestamp}] ${msg}\e[0m" ;;
        ERROR)   echo -e "\e[31m[ERROR] [${timestamp}] ${msg}\e[0m" ;;
    esac

    # Dispatch warnings and errors automatically via notification
    if [[ "$level" == "WARNING" ]] || [[ "$level" == "ERROR" ]]; then
        send_notification "$level" "Cluster Upgrade Event" "$msg"
    fi
}

# Resolve Node Name from Node IP/Host
get_nodename() {
    local target="$1"
    if [[ "$DRY_RUN" == true ]]; then
        echo "node-${target//./-}"
        return 0
    fi
    local name
    name=$(run_ssh "$target" "hostname" 2>/dev/null | tr -d '\r\n')
    if [[ -z "$name" ]]; then
        return 1
    fi
    echo "$name"
}
# Active maintenance state tracking for emergency signal cleanup
CURRENT_MAINTENANCE_NODE=""
CURRENT_MAINTENANCE_TARGET=""

cleanup_on_interrupt() {
    echo ""
    log "WARNING" "Script execution interrupted by user (SIGINT/SIGTERM)."
    if [[ -n "$CURRENT_MAINTENANCE_NODE" ]] && [[ -n "$CURRENT_MAINTENANCE_TARGET" ]]; then
        log "WARNING" "Attempting emergency recovery: disabling HA maintenance mode on '${CURRENT_MAINTENANCE_NODE}' (${CURRENT_MAINTENANCE_TARGET})..."
        run_ssh "$CURRENT_MAINTENANCE_TARGET" "ha-manager crm-command node-maintenance disable ${CURRENT_MAINTENANCE_NODE}" >/dev/null 2>&1 || true
    fi
    exit 1
}

trap cleanup_on_interrupt SIGINT SIGTERM

# Enable HA Maintenance Mode on Node
enable_maintenance() {
    local target="$1"
    local nodename="$2"

    log "INFO" "Enabling HA maintenance mode for node '${nodename}' (${target})..."
    run_ssh "$target" "ha-manager crm-command node-maintenance enable ${nodename}" || {
        log "ERROR" "Failed to enable HA maintenance mode on '${nodename}'."
        return 1
    }

    CURRENT_MAINTENANCE_NODE="$nodename"
    CURRENT_MAINTENANCE_TARGET="$target"

    send_notification "INFO" "Maintenance Enabled" "HA maintenance mode enabled for node '${nodename}' (${target}). Evacuating guests..."

    log "INFO" "Waiting for guest evacuation on node '${nodename}' (Timeout: ${EVACUATION_TIMEOUT}s)..."
    local elapsed=0
    while [[ $elapsed -lt $EVACUATION_TIMEOUT ]]; do
        if [[ "$DRY_RUN" == true ]]; then
            log "INFO" "[DRY-RUN] Evacuation simulation completed for '${nodename}'."
            return 0
        fi

        # Count active running QEMU VMs and LXC containers on target node
        local running_vms running_cts total_running
        running_vms=$(run_ssh "$target" "qm list 2>/dev/null | grep -c 'running' || true" | tr -cd '0-9')
        running_cts=$(run_ssh "$target" "pct list 2>/dev/null | grep -c 'running' || true" | tr -cd '0-9')
        running_vms="${running_vms:-0}"
        running_cts="${running_cts:-0}"
        total_running=$((running_vms + running_cts))

        if [[ $total_running -eq 0 ]]; then
            log "SUCCESS" "All guests successfully migrated off node '${nodename}'."
            send_notification "SUCCESS" "Migration Completed" "All VMs and LXC containers migrated off node '${nodename}' (${target})."
            return 0
        fi

        log "INFO" "Node '${nodename}' still has ${total_running} running guest(s) (${running_vms} VMs, ${running_cts} LXCs). Waiting..."
        sleep "$EVACUATION_CHECK_INTERVAL"
        elapsed=$((elapsed + EVACUATION_CHECK_INTERVAL))
    done

    log "WARNING" "Evacuation timeout reached for node '${nodename}'. Active guests may remain."
    send_notification "WARNING" "Evacuation Timeout" "Node '${nodename}' (${target}) still has active guests after ${EVACUATION_TIMEOUT}s."
    return 0
}

# Check if Node has Pending Updates or Required Reboot
node_needs_update() {
    local target="$1"
    local nodename="$2"

    log "INFO" "Checking for available updates on node '${nodename}' (${target})..."

    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY-RUN] Simulating package update check for '${nodename}' (assume updates available)."
        return 0
    fi

    # Check via SSH if apt dist-upgrade has packages to install/upgrade or if reboot is required
    local check_cmd="apt-get update >/dev/null 2>&1 && (apt-get --just-print dist-upgrade 2>/dev/null | grep -E '^(Inst|Conf)' >/dev/null 2>&1 || test -f /var/run/reboot-required)"
    if run_ssh "$target" "$check_cmd" >/dev/null 2>&1; then
        log "INFO" "Updates or pending reboot detected for node '${nodename}' (${target}). Proceeding with upgrade..."
        return 0
    else
        log "SUCCESS" "Node '${nodename}' (${target}) is already up to date. No reboot required. Skipping."
        send_notification "INFO" "Node Up to Date" "Node '${nodename}' (${target}) is already up to date. Skipping evacuation & reboot."
        return 1
    fi
}

# Perform Pre-Flight Cluster Health Check before upgrade workflow
check_cluster_health() {
    log "INFO" "Performing Pre-Flight Cluster Health Check..."

    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY-RUN] Simulating Cluster Pre-Flight Health Check (Quorum: OK, HA Manager: OK)."
        return 0
    fi

    local primary_node=""
    for n in "${NODES[@]}"; do
        if run_ssh "$n" "hostname" >/dev/null 2>&1; then
            primary_node="$n"
            break
        fi
    done

    if [[ -z "$primary_node" ]]; then
        log "ERROR" "Cluster Health Check FAILED. None of the target nodes (${NODES[*]}) are reachable via SSH!"
        return 1
    fi

    # Check Cluster Quorum Status
    log "INFO" "Checking cluster quorum status on '${primary_node}'..."
    if ! run_ssh "$primary_node" "pvecm status" >/dev/null 2>&1; then
        log "ERROR" "Cluster Quorum Check FAILED on '${primary_node}'. Cluster is not quorate or unreachable!"
        return 1
    fi

    # Check HA Manager status for active error states
    log "INFO" "Checking HA manager status on '${primary_node}'..."
    if run_ssh "$primary_node" "ha-manager status 2>/dev/null | grep -iE '(error|fence|failed)'" >/dev/null 2>&1; then
        log "ERROR" "HA Manager Health Check FAILED. One or more HA services are in an error state!"
        return 1
    fi

    log "SUCCESS" "Cluster Pre-Flight Health Check PASSED (Quorum: OK, HA Manager: OK)."
    return 0
}

# Upgrade Node Packages
upgrade_node() {
    local target="$1"
    local nodename="$2"

    log "INFO" "Starting system upgrade on node '${nodename}' (${target})..."
    
    log "INFO" "Updating package repositories on '${nodename}'..."
    run_ssh "$target" "apt-get update" || {
        log "ERROR" "apt-get update failed on node '${nodename}'."
        return 1
    }

    log "INFO" "Performing dist-upgrade on '${nodename}'..."
    run_ssh "$target" "DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y" || {
        log "ERROR" "apt-get dist-upgrade failed on node '${nodename}'."
        return 1
    }

    log "INFO" "Performing autoremove on '${nodename}'..."
    run_ssh "$target" "DEBIAN_FRONTEND=noninteractive apt-get autoremove -y" || {
        log "ERROR" "apt-get autoremove failed on node '${nodename}'."
        return 1
    }

    log "SUCCESS" "System packages successfully upgraded and cleaned up on '${nodename}'."
    send_notification "SUCCESS" "Upgrade Completed" "Packages dist-upgraded and autoremoved on '${nodename}' (${target})."
}

# Reboot Node and Wait for Online / Quorum State
reboot_node() {
    local target="$1"
    local nodename="$2"

    log "INFO" "Rebooting node '${nodename}' (${target})..."
    send_notification "INFO" "Node Rebooting" "Initiating reboot for node '${nodename}' (${target})."

    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY-RUN] Reboot simulated for '${nodename}'."
        return 0
    fi

    # Trigger reboot asynchronously over SSH to prevent SSH hang
    run_ssh "$target" "systemctl reboot" || true

    # Wait for node to drop offline
    log "INFO" "Waiting for node '${nodename}' to go offline..."
    sleep 15

    # Wait for node to come back online
    log "INFO" "Waiting for node '${nodename}' to come back online (Timeout: ${REBOOT_TIMEOUT}s)..."
    local elapsed=0
    local online=false

    while [[ $elapsed -lt $REBOOT_TIMEOUT ]]; do
        if run_ssh "$target" "pvecm status" >/dev/null 2>&1; then
            online=true
            break
        fi
        sleep "$REBOOT_CHECK_INTERVAL"
        elapsed=$((elapsed + REBOOT_CHECK_INTERVAL))
    done

    if [[ "$online" == false ]]; then
        log "ERROR" "Node '${nodename}' (${target}) failed to come back online or join quorum within ${REBOOT_TIMEOUT}s."
        return 1
    fi

    log "SUCCESS" "Node '${nodename}' (${target}) is back online and in cluster quorum."
    send_notification "SUCCESS" "Node Online" "Node '${nodename}' (${target}) successfully rebooted and joined cluster quorum."
}

# Disable HA Maintenance Mode on Node
disable_maintenance() {
    local target="$1"
    local nodename="$2"

    log "INFO" "Disabling HA maintenance mode for node '${nodename}' (${target})..."
    run_ssh "$target" "ha-manager crm-command node-maintenance disable ${nodename}" || {
        log "ERROR" "Failed to disable HA maintenance mode on '${nodename}'."
        return 1
    }

    CURRENT_MAINTENANCE_NODE=""
    CURRENT_MAINTENANCE_TARGET=""

    log "SUCCESS" "HA maintenance mode disabled for node '${nodename}' (${target})."
    send_notification "SUCCESS" "Maintenance Disabled" "HA maintenance mode disabled for '${nodename}'. Guests can return."
}

# Main Execution Flow
main() {
    log "INFO" "=================================================="
    log "INFO" "Starting Proxmox VE Cluster Upgrade Workflow"
    log "INFO" "Target Nodes: ${NODES[*]}"
    if [[ -n "$SINGLE_NODE" ]]; then
        log "INFO" "Single Node Mode Enabled: Targeting '${SINGLE_NODE}'"
    fi
    if [[ "$DRY_RUN" == true ]]; then
        log "WARNING" "DRY-RUN MODE ENABLED - No changes or reboots will be executed."
    fi
    log "INFO" "=================================================="

    # Perform Cluster Pre-Flight Health Check
    if ! check_cluster_health; then
        log "ERROR" "Aborting upgrade workflow due to failed Pre-Flight Cluster Health Check."
        send_notification "ERROR" "Pre-Flight Check Failed" "Aborting cluster upgrade. Cluster quorum lost or HA services in error state!"
        return 1
    fi

    send_notification "INFO" "Cluster Upgrade Started" "Starting automated cluster upgrade for nodes: ${NODES[*]}"

    local total_nodes=${#NODES[@]}
    local success_count=0
    local failed_nodes=()

    for target in "${NODES[@]}"; do
        log "INFO" "--------------------------------------------------"
        log "INFO" "Processing Node: ${target}"
        log "INFO" "--------------------------------------------------"

        local nodename
        nodename=$(get_nodename "$target") || {
            log "ERROR" "Cannot connect to node ${target} via SSH."
            failed_nodes+=("${target}")
            continue
        }

        # 0. Smart check: Skip evacuation & reboot if node is already up to date
        if [[ "${SMART_UPGRADE:-true}" == true ]]; then
            if ! node_needs_update "$target" "$nodename"; then
                success_count=$((success_count + 1))
                continue
            fi
        fi

        # 1. Enable maintenance & wait for guest migration
        if ! enable_maintenance "$target" "$nodename"; then
            log "ERROR" "Skipping upgrade for node '${nodename}' due to maintenance mode error."
            failed_nodes+=("${target}")
            continue
        fi

        # 2. Upgrade system packages & autoremove
        if ! upgrade_node "$target" "$nodename"; then
            log "ERROR" "Upgrade step failed for node '${nodename}'."
            failed_nodes+=("${target}")
            # Try disabling maintenance mode before continuing
            disable_maintenance "$target" "$nodename" || true
            continue
        fi

        # 3. Reboot node and wait for quorum
        if ! reboot_node "$target" "$nodename"; then
            log "ERROR" "Reboot step failed for node '${nodename}'."
            failed_nodes+=("${target}")
            continue
        fi

        # 4. Disable maintenance mode
        if ! disable_maintenance "$target" "$nodename"; then
            log "ERROR" "Failed to disable maintenance mode for node '${nodename}' after reboot."
            failed_nodes+=("${target}")
            continue
        fi

        success_count=$((success_count + 1))
        log "SUCCESS" "Finished upgrade cycle for node '${nodename}' (${target})."
    done

    log "INFO" "=================================================="
    if [[ ${#failed_nodes[@]} -eq 0 ]]; then
        log "SUCCESS" "All ${total_nodes} nodes successfully upgraded!"
        send_notification "SUCCESS" "Cluster Upgrade Finished" "All ${total_nodes} cluster nodes (${NODES[*]}) upgraded and rebooted successfully!"
    else
        log "ERROR" "Cluster upgrade finished with errors. Upgraded: ${success_count}/${total_nodes}. Failed nodes: ${failed_nodes[*]}"
        send_notification "ERROR" "Cluster Upgrade Completed with Errors" "Upgraded ${success_count}/${total_nodes} nodes. Failed nodes: ${failed_nodes[*]}"
    fi
    log "INFO" "=================================================="
}

main
