vm_exec() {
    local VMID=$1
    local CMD=$2
    local DESC=$3
    
    if ! qm agent $VMID ping >/dev/null 2>&1; then
        echo " AGENT IS NOT AVAILABLE AT $VMID"
        return
    fi
check_env() {
    local MISSING=()
    local REQUIRED_VARS=(
        ID_ISP ID_HQ_RTR ID_BR_RTR ID_HQ_SRV ID_HQ_CLI ID_BR_SRV
        ISP_IF_WAN ISP_IF_HQ ISP_IF_BR
        HQ_IF_WAN HQ_IF_LAN
        BR_IF_WAN BR_IF_LAN
        HQ_SRV_IF HQ_CLI_IF BR_SRV_IF
        USER_ADMIN USER_SSH PASS TIMEZONE
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
    # english error
    local FULL_CMD="export LC_ALL=C; $CMD"
    local B64_CMD=$(echo "$FULL_CMD" | base64 -w0)
    local WRAPPER="echo $B64_CMD | base64 -d | /bin/bash"

    qm guest exec $VMID --timeout 600 -- /bin/bash -c "$WRAPPER" >/dev/null 2>&1
    sleep 2
}
