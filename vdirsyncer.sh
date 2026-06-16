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

# Phase 1: Enumerate and validate all user units
declare -A user_map
users=()

for config_file in "${config_files[@]}"; do
  user=$(basename "$config_file" .conf)

  if [[ -n "${user_map[$user]:-}" ]]; then
    echo "Error: Duplicate user '$user'."
    exit 1
  fi

  user_upper="${user^^}"
  uid_var="${user_upper}_UID"
  gid_var="${user_upper}_GID"
  uid="${!uid_var:?Error: $uid_var is not set or empty}"
  gid="${!gid_var:?Error: $gid_var is not set or empty}"

  user_map[$user]="$uid:$gid"
  users+=("$user")
done

# Phase 2: Execute sync and normalize permissions for each user
for user in "${users[@]}"; do
  IFS=: read -r uid gid <<<"${user_map[$user]}"

  echo "Running sync for user: $user"

  config_file="$CONFIG_DIR/$user.conf"

  ("$YES" || true) | "$VDIRSYNCER" -c "$config_file" discover
  "$VDIRSYNCER" -c "$config_file" metasync
  "$VDIRSYNCER" -c "$config_file" sync

  cal_dir="/app/calendars/$user"

  chown -R "$uid:$gid" "$cal_dir"
  find "$cal_dir" -type f -exec chmod 0600 {} +
  find "$cal_dir" -type d -exec chmod 0700 {} +

  echo "Completed sync for user: $user"
done

echo "All vdirsyncer operations completed."
