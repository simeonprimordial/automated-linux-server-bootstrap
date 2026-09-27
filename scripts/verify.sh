#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " Server Bootstrap Verification"
echo "======================================"

DEVOPS_USER="devops"
APP_DIR="/opt/apps"
LOG_DIR="/var/log/apps"

PASS=0
FAIL=0

check() {
    local description="$1"
    local command="$2"

    if eval "$command" >/dev/null 2>&1; then
        echo "[PASS] $description"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $description"
        FAIL=$((FAIL + 1))
    fi
}

check "DevOps user exists" \
    "id $DEVOPS_USER"

check "SSH directory exists" \
    "test -d /home/$DEVOPS_USER/.ssh"

check "authorized_keys exists" \
    "test -f /home/$DEVOPS_USER/.ssh/authorized_keys"

check "Application directory exists" \
    "test -d $APP_DIR"

check "Log directory exists" \
    "test -d $LOG_DIR"

check "UFW is active" \
    "sudo ufw status | grep -q 'Status: active'"

check "SSH service is running" \
    "systemctl is-active --quiet ssh"

echo
echo "======================================"
echo " Passed: $PASS"
echo " Failed: $FAIL"
echo "======================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi

echo "Server verification successful."