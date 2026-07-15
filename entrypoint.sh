#!/usr/bin/env bash
set -euo pipefail

CRONTAB_FILE="/app/crontab"
CONFIG_DIR="/app/config"
USERS_FILE="/app/.users"

shopt -s nullglob
config_files=("$CONFIG_DIR"/*.conf)
shopt -u nullglob

if [ ${#config_files[@]} -eq 0 ]; then
  echo "Error: No .conf files found in $CONFIG_DIR."
  exit 1
fi

: >"$USERS_FILE"
echo "" >"$CRONTAB_FILE"

for config_file in "${config_files[@]}"; do
  user=$(basename "$config_file" .conf)

  user_upper="${user^^}"
  uid_var="${user_upper}_UID"
  gid_var="${user_upper}_GID"

  uid="${!uid_var:?Error: $uid_var is not set}"
  gid="${!gid_var:?Error: $gid_var is not set}"

  if ! [[ "$uid" =~ ^[0-9]+$ ]] || ! [[ "$gid" =~ ^[0-9]+$ ]]; then
    echo "Error: $uid_var=$uid or $gid_var=$gid is not numeric"
    exit 1
  fi

  echo "Discovered user: $user (uid=$uid, gid=$gid)"

  mkdir -p "/app/.vdirsyncer/$user" "/app/calendars/$user"
  chown -R "$uid:$gid" "/app/.vdirsyncer/$user" "/app/calendars/$user"

  echo "$user:$uid:$gid" >>"$USERS_FILE"
done

SYNC_SCHEDULE="${SYNC_SCHEDULE:-"*/30 * * * *"}"
echo "${SYNC_SCHEDULE} /usr/local/bin/vdirsyncer.sh" >>"$CRONTAB_FILE"

echo "--- Generated crontab ---"
cat "$CRONTAB_FILE"
echo "-------------------------"

if [ "${DEBUG_MODE:-false}" = "true" ]; then
  echo "DEBUG_MODE is enabled. Supercronic will NOT start."
  echo "Container is idle. Use: docker exec -it vdirsyncer bash"
  exec tail -f /dev/null
fi

echo "Starting supercronic..."
exec supercronic "$CRONTAB_FILE"
