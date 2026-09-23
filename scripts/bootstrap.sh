#!/usr/bin/env bash

set -euo pipefail

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

DEVOPS_USER="devops"

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

echo "[5/11] Configuring SSH access..."

SSH_DIR="/home/$DEVOPS_USER/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

sudo mkdir -p "$SSH_DIR"

sudo touch "$AUTHORIZED_KEYS"

sudo chown -R "$DEVOPS_USER:$DEVOPS_USER" "$SSH_DIR"

sudo chmod 700 "$SSH_DIR"
sudo chmod 600 "$AUTHORIZED_KEYS"

echo "SSH directory configured for $DEVOPS_USER."

echo "[6/11] Creating standard directories..."
sudo mkdir -p /opt/apps
sudo mkdir -p /var/log/apps

echo "[7/11] Applying basic permissions..."
sudo chown -R "$DEVOPS_USER:$DEVOPS_USER" /opt/apps

echo "[8/11] Applying SSH hardening..."

SSHD_CONFIG="/etc/ssh/sshd_config"

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

sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

sudo ufw --force enable

echo "Firewall enabled."

echo "[10/11] Verifying firewall status..."

sudo ufw status verbose

echo "[11/11] Bootstrap complete."

echo
echo "Server bootstrap completed successfully."

