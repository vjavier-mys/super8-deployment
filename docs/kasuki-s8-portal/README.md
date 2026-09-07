# Kasuki S8 Portal

## Deployment map

| Environment | URL | Server | App path | Private port |
|---|---|---|---|---:|
| Production | `https://kasuki-s8-portal.mysuki.io` | `droplet3.mysuki.net` | `/home/deploy/apps/kasuki-s8-portal` | `8514` |
| Staging | `https://kasuki-s8-portal.mysuki.net` | `droplet2.mysuki.net` | `/home/deploy/apps/kasuki-s8-portal` | `8514` |

Repository: `git@github.com:My-Suki/kasuki-portal-super8-edition.git`

## Manual deployment

Clone this infrastructure repository and run the deployment script from a local checkout of the Portal repository:

```bash
cd /path/to/kasuki-portal-super8-edition
DRY_RUN=1 /path/to/super8-deployment/scripts/deploy-super8.sh portal staging release-candidate-1
/path/to/super8-deployment/scripts/deploy-super8.sh portal staging release-candidate-1
```

For production, use `production` instead of `staging`:

```bash
/path/to/super8-deployment/scripts/deploy-super8.sh portal production release-candidate-1
```

The script accepts a branch or tag, resolves it from GitHub, transfers source without `.git` or local env files, preserves the server `.env` and `data/`, rebuilds the image, recreates the container, checks `/api/health`, and rolls back if health fails. It does not change DNS or nginx.

The default Portal GitHub key on Hermes is `/home/hermes/.ssh/repo_readonly_deploy`. On another operator machine, override it:

```bash
GIT_SSH_KEY="$HOME/.ssh/portal-readonly" \
DEPLOY_SSH_KEY="$HOME/.ssh/droplet-admin" \
/path/to/super8-deployment/scripts/deploy-super8.sh portal staging release-candidate-1
```

The target server must already have `/home/deploy/apps/kasuki-s8-portal/.env` with mode `600`.

## Server-side staging deployment

Droplet2 has a staging-only script that can be run directly as `deploy`:

```bash
ssh deploy@droplet2.mysuki.net
/home/deploy/scripts/deploy-staging.sh portal release-candidate-1
```

It clones/fetches the selected ref into `/home/deploy/deploy-checkouts/`, keeps GitHub keys under `/home/deploy/.ssh/` with mode `600`, preserves the application `.env` and data, backs up the current deployment, rebuilds, health-checks, and rolls back on failure. Use `DRY_RUN=1` before a real deployment.

## Runtime env-only restart

For changes to runtime environment values without a code rebuild:

```bash
ssh deploy@droplet2.mysuki.net
cd /home/deploy/apps/kasuki-s8-portal
docker compose -p kasuki-s8-portal up -d --force-recreate --no-build
```

Use the production hostname for droplet3. Rebuild if a changed variable is embedded into the frontend at build time.

## Health checks

```bash
curl -fsS https://kasuki-s8-portal.mysuki.net/api/health
curl -fsS https://kasuki-s8-portal.mysuki.io/api/health
```
