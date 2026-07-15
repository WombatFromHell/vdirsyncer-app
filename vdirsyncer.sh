#!/usr/bin/env bash
set -euo pipefail

VDIRSYNCER="$(command -v vdirsyncer)"
YES="$(command -v yes)"

if [ -z "$VDIRSYNCER" ] || [ -z "$YES" ]; then
  echo "Error: 'vdirsyncer' and/or 'yes' not found!"
  exit 1
fi

USERS_FILE="/app/.users"

if [ ! -s "$USERS_FILE" ]; then
  echo "Error: No users found in $USERS_FILE"
  exit 1
fi

exit_code=0

while IFS=: read -r user uid gid; do
  echo "=== Syncing user: $user ==="

  config_file="/app/config/${user}.conf"

  if [ ! -f "$config_file" ]; then
    echo "Error: Config not found for user '$user': $config_file"
    exit_code=1
    continue
  fi

  # ponytail: set -e bypassed per-user via if-chain; one failure won't abort the rest
  if ("$YES" || true) | "$VDIRSYNCER" -c "$config_file" discover &&
    "$VDIRSYNCER" -c "$config_file" metasync &&
    "$VDIRSYNCER" -c "$config_file" sync; then
    cal_dir="/app/calendars/$user"
    state_dir="/app/.vdirsyncer/$user"

    chown -R "$uid:$gid" "$cal_dir" "$state_dir"
    find "$cal_dir" "$state_dir" -type f -exec chmod 0600 {} +
    find "$cal_dir" "$state_dir" -type d -exec chmod 0700 {} +
    echo "=== Completed sync for user: $user ==="
  else
    echo "=== FAILED sync for user: $user ==="
    exit_code=1
  fi
done <"$USERS_FILE"

if [ "$exit_code" -ne 0 ]; then
  echo "Warning: One or more users failed to sync"
fi

exit "$exit_code"
