vm_exec() {
    local VMID=$1
    local CMD=$2
    local DESC=$3

    if ! qm agent $VMID ping >/dev/null 2>&1; then
        echo "AGENT IS NOT AVAILABLE AT $VMID" >&2
        return 1
    fi

    local FULL_CMD="export LC_ALL=C; $CMD"
    local B64_CMD=$(echo "$FULL_CMD" | base64 -w0)
    local WRAPPER="echo $B64_CMD | base64 -d | /bin/bash"
    
    local RESULT
    RESULT=$(qm guest exec $VMID --timeout 600 -- /bin/bash -c "$WRAPPER")
    sleep 2

    echo "[$VMID] ... $DESC"
    echo "$RESULT"
    
    local EXIT_CODE
    EXIT_CODE=$(echo "$RESULT" | grep -oP '"exitcode"\s*:\s*\K[0-9]+')
    if [[ "$EXIT_CODE" != "0" ]]; then
        local ERR
        ERR=$(echo "$RESULT" | grep -oP '"err-data"\s*:\s*"\K[^"]+')
        echo "[$VMID] $DESC — ОШИБКА (exitcode $EXIT_CODE): $ERR" >&2
        return 1
    fi
}

self_destruct() {
    LOG="/var/log/demo2026_$(basename $0).log"
    exec 3>&1
    exec &>"$LOG"
    trap '_exit_code=$?
        if [[ $_exit_code -ne 0 ]]; then
            echo "" >&3
            echo "=== СКРИПТ УПАЛ ===" >&3
            echo "Exit code: $_exit_code" >&3
            echo "Посмотреть лог можно командой: cat $LOG" >&3
            echo "===================" >&3
        else
            rm -f "$0"
            if [[ ! -f ./22_neebu.sh ]]; then
                rm -f ./env.sh ./lib.sh
            fi
        fi' EXIT
}

check_env() {
    local MISSING=()
    local REQUIRED_VARS=(
        ID_ISP ID_HQ_RTR ID_BR_RTR ID_HQ_SRV ID_HQ_CLI ID_BR_SRV
        ISP_IF_WAN ISP_IF_HQ ISP_IF_BR
        HQ_IF_WAN HQ_IF_LAN
        BR_IF_WAN BR_IF_LAN
        HQ_SRV_IF HQ_CLI_IF BR_SRV_IF
    )
  for VAR in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!VAR}" ]]; then
            MISSING+=("$VAR")
        fi
    done

    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo "ERROR: Следующие переменные не заполнены в env.sh:"
        for VAR in "${MISSING[@]}"; do
            echo "  - $VAR"
        done
        exit 1
    fi
}

#cleanup_pve_logs() {
#     find /var/log/pve/tasks/ -type f -delete
  #   truncate -s 0 /var/lib/pve-manager/tasks/index
#    truncate -s 0 /var/lib/pve-manager/tasks/index.1 2>/dev/null
 #    rm -f /var/log/demo2026_*.log
#}
