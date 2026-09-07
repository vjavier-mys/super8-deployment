#!/usr/bin/env bash
set -euo pipefail

# Safe server-side production rollback for droplet3.
# Run as deploy:
#   /home/deploy/scripts/revert-production.sh <app>
#   /home/deploy/scripts/revert-production.sh <app> <1|2|3>
#
# backup1 is the newest previous version. backup2 and backup3 are older.
# Backups are never deleted by this script.

usage() {
  cat >&2 <<'EOF'
Usage: revert-production.sh <app> [backup-number]
       revert-production.sh --list <app>

Apps:
  assistant   /home/deploy/apps/kasuki-super8       port 8510
  mobile      /home/deploy/apps/super8-mobile      port 8513
  portal      /home/deploy/apps/kasuki-s8-portal    port 8514

Examples:
  revert-staging.sh --list portal
  revert-staging.sh portal
  revert-staging.sh portal 2
EOF
  exit 2
}

LIST=0
if [[ "${1:-}" == --list ]]; then LIST=1; shift; fi
[[ $# -ge 1 && $# -le 2 ]] || usage
APP="$1"
REQUESTED_NUMBER="${2:-1}"

case "$APP" in
  assistant) BASE='/home/deploy/apps/kasuki-super8'; PROJECT='kasuki-super8'; PORT=8510 ;;
  mobile) BASE='/home/deploy/apps/super8-mobile'; PROJECT='super8-mobile'; PORT=8513 ;;
  portal) BASE='/home/deploy/apps/kasuki-s8-portal'; PROJECT='kasuki-s8-portal'; PORT=8514 ;;
  *) echo "Unknown app: $APP" >&2; usage ;;
esac

[[ "$REQUESTED_NUMBER" =~ ^[123]$ ]] || { echo 'Backup number must be 1, 2, or 3.' >&2; exit 1; }
[[ "$(id -un)" == deploy ]] || { echo 'Run this script as deploy.' >&2; exit 1; }
[[ "$(hostname -s)" == ubuntu3 ]] || { echo 'This is the droplet3 production script; run it on ubuntu3.' >&2; exit 1; }
for command in docker find sort head cut date cp mv rm chmod cat; do command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }; done

find_backup() {
  local number="$1"
  find "$(dirname "$BASE")" -maxdepth 1 -mindepth 1 -type d \
    -name "$(basename "$BASE").backup${number}-*" -printf '%T@ %p\n' \
    | sort -nr | head -1 | cut -d' ' -f2-
}

if [[ "$LIST" == 1 ]]; then
  for number in 1 2 3; do
    backup="$(find_backup "$number")"
    if [[ -n "$backup" ]]; then
      commit="$(cat "$backup/RELEASE_COMMIT" 2>/dev/null || echo unknown)"
      printf 'backup%s: %s (%s)\n' "$number" "$backup" "$commit"
    else
      printf 'backup%s: <empty>\n' "$number"
    fi
  done
  exit 0
fi

[[ -d "$BASE" ]] || { echo "Current deployment not found: $BASE" >&2; exit 1; }
BACKUP="$(find_backup "$REQUESTED_NUMBER")"
[[ -n "$BACKUP" && -d "$BACKUP" ]] || { echo "backup${REQUESTED_NUMBER} is empty for $APP." >&2; exit 1; }
[[ -f "$BASE/.env" ]] || { echo "Current .env is missing: $BASE/.env" >&2; exit 1; }
[[ -f "$BACKUP/docker-compose.yml" ]] || { echo "Backup has no docker-compose.yml: $BACKUP" >&2; exit 1; }
[[ -f "$BACKUP/RELEASE_COMMIT" ]] || { echo "Backup has no RELEASE_COMMIT: $BACKUP" >&2; exit 1; }

OLD_COMMIT="$(cat "$BASE/RELEASE_COMMIT" 2>/dev/null || echo unknown)"
NEW_COMMIT="$(cat "$BACKUP/RELEASE_COMMIT")"
CURRENT_BACKUP="${BASE}.backup1-${OLD_COMMIT}"
INCOMING="${BASE}.revert-incoming"

echo "app=$APP"
echo "current_commit=$OLD_COMMIT"
echo "rollback_commit=$NEW_COMMIT"
echo "selected_backup=backup${REQUESTED_NUMBER}"

rm -rf "$INCOMING"
mkdir -p "$INCOMING"
cp -a "$BACKUP"/. "$INCOMING"/
# Keep the currently active runtime configuration and persistent data.
cp "$BASE/.env" "$INCOMING/.env"
chmod 600 "$INCOMING/.env"
if [[ -d "$BASE/data" ]]; then
  rm -rf "$INCOMING/data"
  cp -a "$BASE/data" "$INCOMING/data"
fi

# Rotate the current version into backup1 and older slots upward.
for old in "$BASE".backup3-*; do [[ -e "$old" ]] || continue; rm -rf "$old"; done
for old in "$BASE".backup2-*; do
  [[ -e "$old" ]] || continue
  suffix="${old#"$BASE".backup2-}"
  mv "$old" "${BASE}.backup3-${suffix}"
done
for old in "$BASE".backup1-*; do
  [[ -e "$old" ]] || continue
  suffix="${old#"$BASE".backup1-}"
  mv "$old" "${BASE}.backup2-${suffix}"
done
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
