# Kasuki Super8 Assistant

Kasuki Super8 Assistant is the main Kasuki application. This page is the starting point for an operator who needs to reproduce or deploy this application.

## Production at a glance

- Repository: `git@github.com:My-Suki/kasuki-super8.git`
- Production ref currently documented: `release-candidate-1.1`
- Current deployed commit: `9815eaaaa6d90ae0c58664f6f56b7ca777728ca1`
- Production URL: <https://kasuki-s8.mysuki.io>
- Server: `ubuntu3` / `168.144.110.200`
- Application directory: `/home/deploy/apps/kasuki-super8`
- Docker Compose project: `kasuki-super8`
- Container port: `127.0.0.1:8510` → application port `3001`
- Health endpoint: `https://kasuki-s8.mysuki.io/api/health`
- nginx: TLS termination and reverse proxy to `127.0.0.1:8510`

## Application layout

The production directory contains the checked-out source, Docker Compose file, `data/` files, and the server-only `.env`:

```text
/home/deploy/apps/kasuki-super8/
├── .env                 # secret; mode 600; never commit
├── docker-compose.yml
├── Dockerfile
├── data/                # persistent CSV application data
└── RELEASE_COMMIT
```

The application uses MongoDB for application data and keeps its CSV data under the host `data/` directory. Preserve `data/` during source deployments.

## First-time setup

1. Provision the shared server using [`../OPERATIONS.md`](../OPERATIONS.md).
2. Create `/home/deploy/apps/kasuki-super8` owned by `deploy:deploy`.
3. Copy the production environment file into `.env` without printing it.
4. Set its ownership and mode:

```bash
sudo chown deploy:deploy /home/deploy/apps/kasuki-super8/.env
sudo chmod 600 /home/deploy/apps/kasuki-super8/.env
```

5. Check out the desired application ref.
6. Build and start the service:

```bash
cd /home/deploy/apps/kasuki-super8
docker compose -p kasuki-super8 build
docker compose -p kasuki-super8 up -d
```

7. Verify locally:

```bash
curl -fsS http://127.0.0.1:8510/api/health
```

8. Configure nginx for `kasuki-s8.mysuki.io`, verify `sudo nginx -t`, reload nginx, and issue the certificate with Certbot after DNS resolves.

## Manual deployment from a laptop

The infrastructure repository includes `scripts/deploy-kasuki.sh`. Run it from a local checkout of the application repository:

```bash
export DEPLOY_SSH_KEY="$HOME/.ssh/ubuntu3_deploy"
./scripts/deploy-kasuki.sh release-candidate-1.1
```

The script:

- Resolves the exact Git commit locally.
- Archives and uploads source without `.git`.
- Does not upload `.env` or secrets.
- Creates a release directory on the server.
- Builds and starts the Compose project.
- Checks `http://127.0.0.1:8510/api/health`.
- Records the verified commit in `CURRENT_RELEASE`.

The script assumes the production `.env` already exists on the server. It does not configure nginx or issue certificates.

## Manual deployment procedure

If the script is unavailable:

```bash
REF=release-candidate-1.1
COMMIT=$(git rev-parse "$REF^{commit}")
ssh deploy@droplet3.mysuki.net \
  "mkdir -p /home/deploy/apps/kasuki-super8/releases/$COMMIT"
git archive --format=tar "$COMMIT" | gzip | \
  ssh deploy@droplet3.mysuki.net \
  "gzip -dc | tar -xf - -C /home/deploy/apps/kasuki-super8/releases/$COMMIT"
```

Before starting the release, confirm `.env` and `data/` are present. Use the existing Compose project name so nginx continues proxying to the same port.

## Rollback

A deployment backup is created before replacement. To roll back:

1. Stop the current Compose service.
2. Restore the previous source tree, keeping the current production `.env` and `data/` only if they are compatible with the rollback.
3. Rebuild and start:

```bash
cd /home/deploy/apps/kasuki-super8
docker compose -p kasuki-super8 down
docker compose -p kasuki-super8 build
docker compose -p kasuki-super8 up -d
curl -fsS http://127.0.0.1:8510/api/health
```

## Troubleshooting

```bash
docker compose -p kasuki-super8 ps
docker compose -p kasuki-super8 logs --tail=100 app
curl -v http://127.0.0.1:8510/api/health
sudo nginx -t
sudo journalctl -u nginx -n 100 --no-pager
```

If the app cannot connect to MongoDB, do not expose the connection string in logs. Check the Atlas allowlist, TLS compatibility, and the server outbound IP using sanitized metadata only.
