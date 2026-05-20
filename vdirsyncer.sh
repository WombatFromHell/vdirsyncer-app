#!/usr/bin/env bash
set -euo pipefail

YES="$(command -v yes)"
VDIRSYNCER="$(command -v vdirsyncer)"

if [ -z "$YES" ] || [ -z "$VDIRSYNCER" ]; then
  echo "Error: 'yes' and/or 'vdirsyncer' not found!"
  exit 1
fi

CONFIG_DIR="/app/config"

shopt -s nullglob
config_files=("$CONFIG_DIR"/*.conf)
shopt -u nullglob

if [ ${#config_files[@]} -eq 0 ]; then
  echo "Error: No .conf files found in $CONFIG_DIR."
  exit 1
fi

for config_file in "${config_files[@]}"; do
  filename=$(basename "$config_file")
  user="${filename%.conf}"

  echo "Running sync for user: $user (config: $config_file)"

  # Perform the vdirsyncer operations for this specific user/config
  ("$YES" || true) | "$VDIRSYNCER" -c "$config_file" discover
  "$VDIRSYNCER" -c "$config_file" metasync
  "$VDIRSYNCER" -c "$config_file" sync

  echo "Completed sync for user: $user"
done

echo "All vdirsyncer operations completed."
