#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="$(dirname "$0")/../config/server.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

echo "======================================"
echo " Automated Linux Server Bootstrap"
echo "======================================"

echo "[1/11] Updating package index..."
sudo apt-get update

echo "[2/11] Upgrading system packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "[3/11] Installing required packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    wget \
    git \
    vim \
    unzip \
    ufw \
    htop \
    tree

echo "[4/11] Creating DevOps user..."

if id "$DEVOPS_USER" &>/dev/null; then
    echo "User $DEVOPS_USER already exists."
else
    sudo useradd \
        --create-home \
        --shell /bin/bash \
        --groups sudo \
        "$DEVOPS_USER"

    echo "User $DEVOPS_USER created."
fi

echo "[5/10] Configuring SSH access..."

SSH_DIR="/home/$DEVOPS_USER/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

sudo mkdir -p "$SSH_DIR"
sudo touch "$AUTHORIZED_KEYS"

sudo chown -R "$DEVOPS_USER:$DEVOPS_USER" "$SSH_DIR"
sudo chmod 700 "$SSH_DIR"
sudo chmod 600 "$AUTHORIZED_KEYS"

if [[ -n "${SSH_PUBLIC_KEY:-}" ]]; then
    if ! grep -qxF "$SSH_PUBLIC_KEY" "$AUTHORIZED_KEYS"; then
        echo "$SSH_PUBLIC_KEY" | sudo tee -a "$AUTHORIZED_KEYS" > /dev/null
        echo "SSH public key added for $DEVOPS_USER."
    else
        echo "SSH public key already exists."
    fi
else
    echo "WARNING: SSH_PUBLIC_KEY was not provided."
fi

echo "[6/11] Creating standard directories..."
sudo mkdir -p "$APP_DIR"
sudo mkdir -p "$LOG_DIR"

echo "[7/11] Applying basic permissions..."
sudo chown -R "$DEVOPS_USER:$DEVOPS_USER" "$APP_DIR"

echo "[8/11] Applying SSH hardening..."

SSHD_CONFIG="/etc/ssh/sshd_config"

sudo mkdir -p /run/sshd

sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"

if sudo sshd -t; then
    sudo systemctl reload ssh
    echo "SSH configuration validated and reloaded."
else
    echo "ERROR: Invalid SSH configuration."
    exit 1
fi

echo "[9/11] Configuring firewall..."

sudo ufw allow "$SSH_PORT"/tcp
sudo ufw allow "$HTTP_PORT"/tcp
sudo ufw allow "$HTTPS_PORT"/tcp

sudo ufw --force enable

echo "Firewall enabled."

echo "[10/11] Verifying firewall status..."

sudo ufw status verbose

echo "[11/11] Bootstrap complete."

echo
echo "Server bootstrap completed successfully."

