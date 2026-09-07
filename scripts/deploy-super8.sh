#!/usr/bin/env bash
set -euo pipefail

# Manual deployment for the three Super8 applications.
# Run from the checked-out application repository:
#   ./scripts/deploy-super8.sh <app> <environment> <branch-or-tag>
# Example:
#   ./scripts/deploy-super8.sh portal staging release-candidate-1
#
# The script deliberately does not manage DNS, nginx, certificates, or secrets.
# It preserves the target server's .env and persistent data directory.

usage() {
  cat >&2 <<'EOF'
Usage: ./scripts/deploy-super8.sh <app> <environment> <branch-or-tag>

Apps:
  assistant   My-Suki/kasuki-super8       port 8510
  mobile      My-Suki/super8-mobile      port 8513
  portal      My-Suki/kasuki-portal-super8-edition  port 8514

Environments:
  staging     droplet2.mysuki.net
  production  droplet3.mysuki.io

Examples:
  ./scripts/deploy-super8.sh assistant staging release-candidate-1.1
  ./scripts/deploy-super8.sh mobile production release-candidate-1.1
  ./scripts/deploy-super8.sh portal staging main

Optional:
  DRY_RUN=1 ./scripts/deploy-super8.sh portal staging main
  DEPLOY_SSH_KEY=/path/to/key ./scripts/deploy-super8.sh portal staging main
EOF
  exit 2
}

[[ $# -eq 3 ]] || usage
APP="$1"
ENVIRONMENT="$2"
REF="$3"

case "$APP" in
assistant)
  EXPECTED_REPO='My-Suki/kasuki-super8'
  BASE='/home/deploy/apps/kasuki-super8'
  PROJECT='kasuki-super8'
  PORT='8510'
  CONTAINER='kasuki-super8-app-1'
  DEFAULT_GIT_KEY='/home/hermes/.ssh/ubuntu3_infra_git'
  ;;
mobile)
  EXPECTED_REPO='My-Suki/super8-mobile'
  BASE='/home/deploy/apps/super8-mobile'
  PROJECT='super8-mobile'
  PORT='8513'
  CONTAINER='super8-mobile-app-1'
  DEFAULT_GIT_KEY='/home/hermes/.ssh/kasuki_super8_github_readonly'
  ;;
portal)
  EXPECTED_REPO='My-Suki/kasuki-portal-super8-edition'
  BASE='/home/deploy/apps/kasuki-s8-portal'
  PROJECT='kasuki-s8-portal'
  PORT='8514'
  CONTAINER='kasuki-s8-portal'
  DEFAULT_GIT_KEY='/home/hermes/.ssh/repo_readonly_deploy'
  ;;
*)
    echo "Unknown app: $APP" >&2
    usage
    ;;
esac

case "$ENVIRONMENT" in
  staging)
    HOST="${DEPLOY_HOST:-deploy@droplet2.mysuki.net}"
    KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/ubuntu3_admin}"
    ;;
  production)
    HOST="${DEPLOY_HOST:-deploy@droplet3.mysuki.io}"
    KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/ubuntu3_admin}"
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT" >&2
    usage
    ;;
esac

command -v git >/dev/null || { echo 'git is required' >&2; exit 1; }
command -v ssh >/dev/null || { echo 'ssh is required' >&2; exit 1; }
command -v gzip >/dev/null || { echo 'gzip is required' >&2; exit 1; }
[[ -f "$KEY" ]] || { echo "SSH private key not found: $KEY" >&2; exit 1; }

GIT_KEY="${GIT_SSH_KEY:-$DEFAULT_GIT_KEY}"
[[ -f "$GIT_KEY" ]] || { echo "GitHub SSH key not found: $GIT_KEY (override with GIT_SSH_KEY=...)" >&2; exit 1; }
export GIT_SSH_COMMAND="ssh -i $GIT_KEY -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new"

REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
NORMALIZED_REMOTE="$(printf '%s' "$REMOTE_URL" | sed -E 's#.*github\.com[:/]##; s#\.git$##')"
[[ "$NORMALIZED_REMOTE" == "$EXPECTED_REPO" ]] || {
  echo "Wrong repository for app '$APP'." >&2
  echo "Expected: $EXPECTED_REPO" >&2
  echo "Found:    ${NORMALIZED_REMOTE:-none}" >&2
  exit 1
}

# Resolve the requested ref from the remote, not from a stale local branch.
# Fetch the complete ref list once; querying peeled tag refs individually can
# hang with some GitHub SSH servers.
REMOTE_REFS="$(timeout 45 git ls-remote origin)" || {
  echo "Unable to read refs from GitHub within 45 seconds" >&2
  exit 1
}
mapfile -t MATCHES < <(printf '%s\n' "$REMOTE_REFS" | awk -v ref="$REF" '$2 == "refs/heads/" ref || $2 == "refs/tags/" ref || $2 == "refs/tags/" ref "^{}" {print $1 "\t" $2}')
[[ ${#MATCHES[@]} -gt 0 ]] || { echo "Remote ref not found: $REF" >&2; exit 1; }

COMMIT=""
for match in "${MATCHES[@]}"; do
  candidate="${match%%$'\t'*}"
  [[ -n "$COMMIT" && "$candidate" != "$COMMIT" ]] && { echo "Ambiguous ref resolves to multiple commits: $REF" >&2; exit 1; }
  COMMIT="$candidate"
done
SHORT="$(git rev-parse --short "$COMMIT" 2>/dev/null || printf '%s' "${COMMIT:0:12}")"
STAMP="$(date +%Y%m%d%H%M%S)"
BACKUP="${BASE}.before-${SHORT}-${STAMP}"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

printf 'app=%s environment=%s ref=%s commit=%s host=%s port=%s\n' \
  "$APP" "$ENVIRONMENT" "$REF" "$COMMIT" "$HOST" "$PORT"

if [[ "${DRY_RUN:-0}" == 1 ]]; then
  echo 'dry-run: no files changed and no remote commands executed'
  exit 0
fi

# Export tracked source only. .git and local .env files never reach the server.
git archive --format=tar "$COMMIT" | gzip > "$TMP"

SSH=(ssh -i "$KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new)

cat "$TMP" | "${SSH[@]}" "$HOST" "set -euo pipefail
  test -f '$BASE/.env'
  test ! -e '${BASE}.incoming'
  mkdir -p '${BASE}.incoming'
  gzip -dc | tar -xf - -C '${BASE}.incoming'
  cp '$BASE/.env' '${BASE}.incoming/.env'
  chmod 600 '${BASE}.incoming/.env'
  chown deploy:deploy '${BASE}.incoming/.env'
  if [ '$APP' = portal ]; then
    sed -i 's/container_name: kasuki-portal$/container_name: kasuki-s8-portal/' '${BASE}.incoming/docker-compose.yml'
    sed -i 's#127.0.0.1:8512:3001#127.0.0.1:8514:3001#' '${BASE}.incoming/docker-compose.yml'
  fi
  printf '%s\\n' '$COMMIT' > '${BASE}.incoming/RELEASE_COMMIT'
  chmod 600 '${BASE}.incoming/RELEASE_COMMIT'
  chown deploy:deploy '${BASE}.incoming/RELEASE_COMMIT'
  if [ -d '$BASE/data' ]; then
    rm -rf '${BASE}.incoming/data'
    cp -a '$BASE/data' '${BASE}.incoming/data'
    chown -R deploy:deploy '${BASE}.incoming/data'
  fi
  if [ -e '$BASE' ]; then mv '$BASE' '$BACKUP'; fi
  mv '${BASE}.incoming' '$BASE'
  cd '$BASE'
  docker compose -p '$PROJECT' config >/dev/null
  docker compose -p '$PROJECT' up -d --build
"

if "${SSH[@]}" "$HOST" "for i in \$(seq 1 20); do code=\$(curl -sS -o /tmp/super8-health.json -w '%{http_code}' http://127.0.0.1:$PORT/api/health 2>/dev/null || true); if [ \"\$code\" = 200 ]; then cat /tmp/super8-health.json; exit 0; fi; sleep 3; done; exit 1"; then
  "${SSH[@]}" "$HOST" "printf '%s\\n' '$COMMIT' > '$BASE/RELEASE_COMMIT'; printf '%s\\n' DEPLOYED > '$BASE/DEPLOYMENT_STATUS'; chmod 600 '$BASE/RELEASE_COMMIT' '$BASE/DEPLOYMENT_STATUS'; echo 'deployment verified'"
  echo "Deployment succeeded: $APP $REF ($COMMIT)"
else
  echo "Health check failed; attempting rollback from $BACKUP" >&2
  "${SSH[@]}" "$HOST" "set -e; docker compose -p '$PROJECT' -f '$BASE/docker-compose.yml' down || true; rm -rf '$BASE'; mv '$BACKUP' '$BASE'; cd '$BASE'; docker compose -p '$PROJECT' up -d --no-build; exit 1"
fi
