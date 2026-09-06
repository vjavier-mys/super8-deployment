#!/usr/bin/env bash
set -euo pipefail

# Laptop-driven deployment for Kasuki Super8.
# Usage: ./scripts/deploy-kasuki.sh release-candidate-1
# The application repository must be the current working directory.

REF="${1:-release-candidate-1}"
HOST="${DEPLOY_HOST:-deploy@droplet3.mysuki.io}"
KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/ubuntu3_deploy}"
BASE="/home/deploy/apps/kasuki-super8"
SSH=(ssh -i "$KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new)

command -v git >/dev/null || { echo "git is required" >&2; exit 1; }
command -v ssh >/dev/null || { echo "ssh is required" >&2; exit 1; }
[ -f "$KEY" ] || { echo "SSH private key not found: $KEY" >&2; exit 1; }

COMMIT="$(git rev-parse --verify "$REF^{commit}")"
SHORT="$(git rev-parse --short "$COMMIT")"
RELEASE="$BASE/releases/$COMMIT"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Deploying $REF ($COMMIT) to $HOST"

git archive --format=tar "$COMMIT" | gzip > "$TMP"
cat "$TMP" | "${SSH[@]}" "$HOST" "set -euo pipefail; mkdir -p '$RELEASE'; gzip -dc | tar -xf - -C '$RELEASE'; test -f '$BASE/.env'; ln -sfn '$BASE/.env' '$RELEASE/.env'; printf '%s\\n' '$COMMIT' > '$RELEASE/RELEASE_COMMIT'; cd '$RELEASE'; docker compose -p kasuki-super8 --env-file '$BASE/.env' up -d --build"

if "${SSH[@]}" "$HOST" "for i in 1 2 3 4 5 6 7 8 9 10; do code=\$(curl -sS -o /tmp/kasuki-health.json -w '%{http_code}' http://127.0.0.1:8510/api/health 2>/dev/null || true); if [ \"\$code\" = 200 ]; then cat /tmp/kasuki-health.json; exit 0; fi; sleep 3; done; exit 1"; then
  "${SSH[@]}" "$HOST" "printf '%s\\n' '$COMMIT' > '$BASE/CURRENT_RELEASE'; echo 'Deployment verified: $SHORT'"
else
  echo "Health check failed; current release was not advanced." >&2
  exit 1
fi
