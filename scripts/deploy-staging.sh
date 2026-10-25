#!/usr/bin/env bash
set -euo pipefail

# Server-side staging deployment for droplet2.
# Run as deploy on droplet2:
#   /home/deploy/scripts/deploy-staging.sh <app> <branch-or-tag>

usage() {
  cat >&2 <<'EOF'
Usage: deploy-staging.sh <app> <branch-or-tag>

Apps:
  assistant   My-Suki/kasuki-super8       port 8510
  mobile      My-Suki/super8-mobile      port 8513
  portal      My-Suki/kasuki-portal-super8-edition  port 8514
  upload      vjavier-mys/kasuki-super8-uploader-api port 8515
  evaluator   My-Suki/kasuki-evaluator          port 8517
  salesman    My-Suki/kasuki-salesman           port 8516

Examples:
  deploy-staging.sh assistant release-candidate-1.1
  deploy-staging.sh mobile release-candidate-1.1
  deploy-staging.sh portal main
  deploy-staging.sh upload main
  deploy-staging.sh evaluator main
  deploy-staging.sh salesman v0.3

Optional:
  DRY_RUN=1 deploy-staging.sh portal main
EOF
  exit 2
}

[[ $# -eq 2 ]] || usage
APP="$1"
REF="$2"

case "$APP" in
  assistant)
    REPO='git@github.com:My-Suki/kasuki-super8.git'
    GIT_KEY='/home/deploy/.ssh/github-kasuki-super8'
    BASE='/home/deploy/apps/kasuki-super8'
    CHECKOUT='/home/deploy/deploy-checkouts/kasuki-super8'
    PROJECT='kasuki-super8'
    PORT='8510'
    ;;
  mobile)
    REPO='git@github.com:My-Suki/super8-mobile.git'
    GIT_KEY='/home/deploy/.ssh/github-super8-mobile'
    BASE='/home/deploy/apps/super8-mobile'
    CHECKOUT='/home/deploy/deploy-checkouts/super8-mobile'
    PROJECT='super8-mobile'
    PORT='8513'
    ;;
  portal)
    REPO='git@github.com:My-Suki/kasuki-portal-super8-edition.git'
    GIT_KEY='/home/deploy/.ssh/github-kasuki-portal'
    BASE='/home/deploy/apps/kasuki-s8-portal'
    CHECKOUT='/home/deploy/deploy-checkouts/kasuki-portal-super8-edition'
    PROJECT='kasuki-s8-portal'
    PORT='8514'
    ;;
  upload)
    REPO='git@github.com:vjavier-mys/kasuki-super8-uploader-api.git'
    GIT_KEY='/home/deploy/.ssh/github-kasuki-upload-api'
    BASE='/home/deploy/apps/kasuki-upload-api'
    CHECKOUT='/home/deploy/deploy-checkouts/kasuki-upload-api'
    PROJECT='kasuki-upload-api'
    PORT='8515'
    ;;
  evaluator)
    REPO='git@github.com:My-Suki/kasuki-evaluator.git'
    GIT_KEY='/home/deploy/.ssh/github-kasuki-evaluator'
    BASE='/home/deploy/apps/kasuki-evaluator'
    CHECKOUT='/home/deploy/deploy-checkouts/kasuki-evaluator'
    PROJECT='kasuki-evaluator'
    PORT='8517'
    TEMPLATE_DIR='/home/deploy/deploy-templates/kasuki-evaluator'
    ;;
  salesman)
    REPO='git@github.com:My-Suki/kasuki-salesman.git'
    GIT_KEY='/home/deploy/.ssh/github-kasuki-salesman'
    BASE='/home/deploy/apps/kasuki-salesman'
    CHECKOUT='/home/deploy/deploy-checkouts/kasuki-salesman'
    PROJECT='kasuki-salesman'
    PORT='8516'
    ;;
  *) echo "Unknown app: $APP" >&2; usage ;;
esac

[[ "$(id -un)" == deploy ]] || { echo 'Run this script as deploy.' >&2; exit 1; }
for command in git docker curl timeout; do command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }; done
[[ -f "$GIT_KEY" ]] || { echo "GitHub key not found: $GIT_KEY" >&2; exit 1; }

export GIT_SSH_COMMAND="ssh -i $GIT_KEY -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
mkdir -p "$(dirname "$CHECKOUT")"
if [[ ! -d "$CHECKOUT/.git" ]]; then
  git clone --no-checkout "$REPO" "$CHECKOUT"
fi
cd "$CHECKOUT"
git remote set-url origin "$REPO"
git fetch --quiet --tags --prune origin '+refs/heads/*:refs/remotes/origin/*'

if git show-ref --verify --quiet "refs/remotes/origin/$REF"; then
  COMMIT="$(git rev-parse "refs/remotes/origin/$REF")"
elif git show-ref --verify --quiet "refs/tags/$REF"; then
  COMMIT="$(git rev-list -n 1 "refs/tags/$REF")"
else
  echo "Remote branch or tag not found: $REF" >&2
  exit 1
fi
SHORT="${COMMIT:0:12}"
OLD_COMMIT="$(cat "$BASE/RELEASE_COMMIT" 2>/dev/null || echo unknown)"
INCOMING="${BASE}.incoming"
CURRENT_BACKUP="${BASE}.backup1-${OLD_COMMIT}"

echo "app=$APP ref=$REF commit=$COMMIT port=$PORT"
[[ "${DRY_RUN:-0}" == 1 ]] && { echo 'dry-run: no deployment changes made'; exit 0; }

rm -rf "$INCOMING"
mkdir -p "$INCOMING"
git archive --format=tar "$COMMIT" | tar -xf - -C "$INCOMING"
if [[ "$APP" == evaluator ]]; then
  [[ -d "$TEMPLATE_DIR" ]] || { echo "Deployment template not found: $TEMPLATE_DIR" >&2; exit 1; }
  cp "$TEMPLATE_DIR/Dockerfile" "$TEMPLATE_DIR/docker-compose.yml" "$INCOMING/"
fi
test -f "$BASE/.env"
cp "$BASE/.env" "$INCOMING/.env"
chmod 600 "$INCOMING/.env"

if [[ "$APP" == portal ]]; then
  sed -i 's/container_name: kasuki-portal$/container_name: kasuki-s8-portal/' "$INCOMING/docker-compose.yml"
  sed -i 's#127.0.0.1:8512:3001#127.0.0.1:8514:3001#' "$INCOMING/docker-compose.yml"
fi
printf '%s\n' "$COMMIT" > "$INCOMING/RELEASE_COMMIT"
chmod 600 "$INCOMING/RELEASE_COMMIT"
if [[ -d "$BASE/data" ]]; then cp -a "$BASE/data" "$INCOMING/data"; fi

# Rotate numbered backups: backup1 is newest, backup3 is oldest.
for old in "$BASE".backup3-*; do
  [[ -e "$old" ]] || continue
  rm -rf "$old"
done
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
if [[ -e "$BASE" ]]; then mv "$BASE" "$CURRENT_BACKUP"; fi
mv "$INCOMING" "$BASE"
cd "$BASE"
if ! docker compose -p "$PROJECT" config >/dev/null || ! docker compose -p "$PROJECT" up -d --build; then
  echo 'Deployment failed; rolling back.' >&2
  docker compose -p "$PROJECT" down || true
  rm -rf "$BASE"
  mv "$CURRENT_BACKUP" "$BASE"
  cd "$BASE"
  docker compose -p "$PROJECT" up -d --no-build || true
  exit 1
fi

if timeout 75 bash -c 'for i in $(seq 1 20); do code=$(curl -sS -o /tmp/super8-health.json -w "%{http_code}" http://127.0.0.1:'"$PORT"'/api/health 2>/dev/null || true); if [ "$code" = 200 ]; then cat /tmp/super8-health.json; exit 0; fi; sleep 3; done; exit 1'; then
  printf '%s\n' DEPLOYED > DEPLOYMENT_STATUS
  chmod 600 DEPLOYMENT_STATUS
  echo "Deployment verified: $APP $REF ($COMMIT)"
else
  echo 'Health check failed; rolling back.' >&2
  docker compose -p "$PROJECT" down || true
  rm -rf "$BASE"
  mv "$CURRENT_BACKUP" "$BASE"
  cd "$BASE"
  docker compose -p "$PROJECT" up -d --no-build || true
  exit 1
fi
