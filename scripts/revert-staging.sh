#!/usr/bin/env bash
set -euo pipefail

# Safe server-side staging rollback for droplet2.
# Run as deploy:
#   /home/deploy/scripts/revert-staging.sh <app>
#   /home/deploy/scripts/revert-staging.sh <app> <backup-directory>
#
# The newest matching backup is selected when no backup directory is given.
# Existing backups are never deleted.

usage() {
  cat >&2 <<'EOF'
Usage: revert-staging.sh <app> [backup-directory]
       revert-staging.sh --list <app>

Apps:
  assistant   /home/deploy/apps/kasuki-super8       port 8510
  mobile      /home/deploy/apps/super8-mobile      port 8513
  portal      /home/deploy/apps/kasuki-s8-portal    port 8514

Examples:
  revert-staging.sh --list portal
  revert-staging.sh portal
  revert-staging.sh portal /home/deploy/apps/kasuki-s8-portal.before-abc-20260906120000
EOF
  exit 2
}

LIST=0
if [[ "${1:-}" == --list ]]; then LIST=1; shift; fi
[[ $# -ge 1 && $# -le 2 ]] || usage
APP="$1"
REQUESTED_BACKUP="${2:-}"

case "$APP" in
  assistant) BASE='/home/deploy/apps/kasuki-super8'; PROJECT='kasuki-super8'; PORT=8510; PREFIX='kasuki-super8' ;;
  mobile) BASE='/home/deploy/apps/super8-mobile'; PROJECT='super8-mobile'; PORT=8513; PREFIX='super8-mobile' ;;
  portal) BASE='/home/deploy/apps/kasuki-s8-portal'; PROJECT='kasuki-s8-portal'; PORT=8514; PREFIX='kasuki-s8-portal' ;;
  *) echo "Unknown app: $APP" >&2; usage ;;
esac

[[ "$(id -un)" == deploy ]] || { echo 'Run this script as deploy.' >&2; exit 1; }
for command in docker find sort head cut date cp mv rm chmod stat; do command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }; done

mapfile -t BACKUPS < <(find "$(dirname "$BASE")" -maxdepth 1 -mindepth 1 -type d -name "$(basename "$BASE").before-*" -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-)
if [[ "$LIST" == 1 ]]; then
  if [[ ${#BACKUPS[@]} -eq 0 ]]; then echo "No backups found for $APP."; else printf '%s\n' "${BACKUPS[@]}"; fi
  exit 0
fi

if [[ -n "$REQUESTED_BACKUP" ]]; then
  BACKUP="$REQUESTED_BACKUP"
else
  [[ ${#BACKUPS[@]} -gt 0 ]] || { echo "No backups found for $APP." >&2; exit 1; }
  BACKUP="${BACKUPS[0]}"
fi

[[ -d "$BASE" ]] || { echo "Current deployment not found: $BASE" >&2; exit 1; }
[[ -d "$BACKUP" ]] || { echo "Backup directory not found: $BACKUP" >&2; exit 1; }
[[ -f "$BASE/.env" ]] || { echo "Current .env is missing: $BASE/.env" >&2; exit 1; }
[[ -f "$BACKUP/docker-compose.yml" ]] || { echo "Backup has no docker-compose.yml: $BACKUP" >&2; exit 1; }
[[ -f "$BACKUP/RELEASE_COMMIT" ]] || { echo "Backup has no RELEASE_COMMIT: $BACKUP" >&2; exit 1; }

OLD_COMMIT="$(cat "$BASE/RELEASE_COMMIT" 2>/dev/null || echo unknown)"
NEW_COMMIT="$(cat "$BACKUP/RELEASE_COMMIT")"
STAMP="$(date +%Y%m%d%H%M%S)"
CURRENT_BACKUP="${BASE}.before-revert-${OLD_COMMIT:0:12}-${STAMP}"
INCOMING="${BASE}.revert-incoming"

echo "app=$APP"
echo "current_commit=$OLD_COMMIT"
echo "rollback_commit=$NEW_COMMIT"
echo "backup=$BACKUP"

if [[ "${CONFIRM_REVERT:-}" != 1 ]]; then
  echo 'Set CONFIRM_REVERT=1 to perform the rollback.' >&2
  exit 3
fi

rm -rf "$INCOMING"
cp -a "$BACKUP" "$INCOMING"
# Keep the currently active runtime configuration and persistent data.
cp "$BASE/.env" "$INCOMING/.env"
chmod 600 "$INCOMING/.env"
if [[ -d "$BASE/data" ]]; then
  rm -rf "$INCOMING/data"
  cp -a "$BASE/data" "$INCOMING/data"
fi

docker compose -p "$PROJECT" -f "$BASE/docker-compose.yml" down || true
mv "$BASE" "$CURRENT_BACKUP"
mv "$INCOMING" "$BASE"
cd "$BASE"

if ! docker compose -p "$PROJECT" config >/dev/null || ! docker compose -p "$PROJECT" up -d --no-build; then
  echo 'Rollback startup failed; restoring the current deployment.' >&2
  docker compose -p "$PROJECT" down || true
  rm -rf "$BASE"
  mv "$CURRENT_BACKUP" "$BASE"
  cd "$BASE"
  docker compose -p "$PROJECT" up -d --no-build || true
  exit 1
fi

if timeout 75 bash -c 'for i in $(seq 1 20); do code=$(curl -sS -o /tmp/super8-revert-health.json -w "%{http_code}" http://127.0.0.1:'"$PORT"'/api/health 2>/dev/null || true); if [ "$code" = 200 ]; then cat /tmp/super8-revert-health.json; exit 0; fi; sleep 3; done; exit 1'; then
  printf '%s\n' REVERTED > DEPLOYMENT_STATUS
  chmod 600 DEPLOYMENT_STATUS
  echo "Rollback verified: $NEW_COMMIT"
else
  echo 'Rollback health check failed; restoring the current deployment.' >&2
  docker compose -p "$PROJECT" down || true
  rm -rf "$BASE"
  mv "$CURRENT_BACKUP" "$BASE"
  cd "$BASE"
  docker compose -p "$PROJECT" up -d --no-build || true
  exit 1
fi
