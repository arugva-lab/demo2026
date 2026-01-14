vm_exec() {
    local VMID=$1
    local CMD=$2
    local DESC=$3
    
    echo "[$VMID] $DESC..."
    
    if ! qm agent $VMID ping >/dev/null 2>&1; then
        echo " AGENT IS NOT AVAILABLE AT $VMID"
        return
    fi

    # english error
    local FULL_CMD="export LC_ALL=C; $CMD"
    local B64_CMD=$(echo "$FULL_CMD" | base64 -w0)
    local WRAPPER="echo $B64_CMD | base64 -d | /bin/bash"

    qm guest exec $VMID --timeout 600 -- /bin/bash -c "$WRAPPER"
    sleep 2
}
