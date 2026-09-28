#!/usr/bin/env bash

set -euo pipefail

OUTPUT_FILE="cloud-init/user-data-rendered.yaml"

if [[ ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    echo "ERROR: SSH public key not found."
    exit 1
fi

SSH_PUBLIC_KEY="$(cat "$HOME/.ssh/id_ed25519.pub")"

sed "s|\${SSH_PUBLIC_KEY}|${SSH_PUBLIC_KEY}|g" \
    cloud-init/user-data.yaml \
    > "$OUTPUT_FILE"

chmod 600 "$OUTPUT_FILE"

echo "Generated: $OUTPUT_FILE"