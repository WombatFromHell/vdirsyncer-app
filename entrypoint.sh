#!/usr/bin/env bash
set -euo pipefail

CRONTAB_FILE="/app/crontab"
CONFIG_DIR="/app/config"

shopt -s nullglob
config_files=("$CONFIG_DIR"/*.conf)
shopt -u nullglob

if [ ${#config_files[@]} -eq 0 ]; then
  echo "Error: No .conf files found in $CONFIG_DIR."
  exit 1
fi

echo "" >"$CRONTAB_FILE"
for config_file in "${config_files[@]}"; do
  filename=$(basename "$config_file")
  user="${filename%.conf}"

  echo "Discovered config for user: $user"

  # Ensure directories exist for active state
  mkdir -p "/app/.vdirsyncer/$user" "/app/calendars"
done

# expose a single entrypoint for syncing on schedule (does user-logic as well)
echo "0 */2 * * * /usr/local/bin/vdirsyncer.sh" >>"$CRONTAB_FILE"

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
