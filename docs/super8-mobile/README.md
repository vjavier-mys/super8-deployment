# Kasuki Super8 Mobile

Kasuki Super8 Mobile is a separate Next.js staff web application. It does not share the Assistant container, Compose project, application directory, or port.

## Production at a glance

- Repository: `git@github.com:My-Suki/super8-mobile.git`
- Production ref currently documented: tag `release-candidate-1`
- Deployed commit: `db421fcb1ac2660180edf540ff4871cebba135f8`
- Application version: `0.2.1`
- Production URL: <https://kasuki-s8-mobile.mysuki.io>
- Server: `ubuntu3` / `168.144.110.200`
- Application directory: `/home/deploy/apps/super8-mobile`
- Docker Compose project: `super8-mobile`
- Container port: `127.0.0.1:8513` → application port `3000`
- Health endpoint: `https://kasuki-s8-mobile.mysuki.io/api/health`
- nginx: TLS termination and reverse proxy to `127.0.0.1:8513`

## Application layout

```text
/home/deploy/apps/super8-mobile/
├── .env                 # secret; mode 600; never commit
├── docker-compose.yml
├── Dockerfile
├── app/
├── public/
├── package.json
└── RELEASE_COMMIT
```

The Dockerfile builds a Next.js standalone image. `NEXT_PUBLIC_GOOGLE_CLIENT_ID` is a build-time value and must be present during `docker compose build`. Runtime credentials are loaded from `.env` by Compose.

## First-time setup

1. Provision the shared server using [`../OPERATIONS.md`](../OPERATIONS.md).
2. Create `/home/deploy/apps/super8-mobile` owned by `deploy:deploy`.
3. Copy the production environment file to `.env` without printing it.
4. Secure it:

```bash
sudo chown deploy:deploy /home/deploy/apps/super8-mobile/.env
sudo chmod 600 /home/deploy/apps/super8-mobile/.env
```

5. Check out the desired tag.
6. Build and start the separate Compose project:

```bash
cd /home/deploy/apps/super8-mobile
docker compose -p super8-mobile build
docker compose -p super8-mobile up -d
```

7. Verify locally:

```bash
curl -fsS http://127.0.0.1:8513/api/health
```

8. Configure nginx for `kasuki-s8-mobile.mysuki.io`, verify `sudo nginx -t`, reload nginx, and issue the certificate after DNS resolves.

## Google OAuth requirements

Both production web apps use the same Google Web OAuth client. The client ID must be identical in the mobile env values used by both the server and the frontend build:

```text
GOOGLE_CLIENT_ID
NEXT_PUBLIC_GOOGLE_CLIENT_ID
VITE_GOOGLE_CLIENT_ID
```

The Google OAuth client must list these exact authorized JavaScript origins:

```text
https://kasuki-s8.mysuki.io
https://kasuki-s8-mobile.mysuki.io
```

Do not add paths, `/api`, trailing slashes, or HTTP variants for production. If the client ID changes, rebuild the image; changing only the runtime `.env` does not update the already-built frontend bundle.

## Manual deployment

From a local checkout of `super8-mobile`:

```bash
REF=release-candidate-1
COMMIT=$(git rev-parse "$REF^{commit}")
ssh deploy@droplet3.mysuki.net \
  "mkdir -p /home/deploy/apps/super8-mobile"
git archive --format=tar "$COMMIT" | gzip | \
  ssh deploy@droplet3.mysuki.net \
  "gzip -dc | tar -xf - -C /home/deploy/apps/super8-mobile"
```

Before building, confirm the server `.env` is still present and mode `600`. Do not overwrite it from the application checkout:

```bash
ssh deploy@droplet3.mysuki.net \
  'stat -c "%a %U:%G %n" /home/deploy/apps/super8-mobile/.env'
```

Then build and verify:

```bash
ssh deploy@droplet3.mysuki.net \
  'cd /home/deploy/apps/super8-mobile && \
   docker compose -p super8-mobile build && \
   docker compose -p super8-mobile up -d && \
   curl -fsS http://127.0.0.1:8513/api/health'
```

Back up the current application tree before replacing it. Keep the existing `.env` and do not merge the Mobile directory with the Assistant directory.

## Rollback

1. Stop the current project.
2. Restore the previous `super8-mobile` source backup.
3. Keep the production `.env` at mode `600`.
4. Rebuild and start the same Compose project.
5. Verify both local and public health endpoints.

```bash
cd /home/deploy/apps/super8-mobile
docker compose -p super8-mobile down
docker compose -p super8-mobile build
docker compose -p super8-mobile up -d
curl -fsS http://127.0.0.1:8513/api/health
```

## Troubleshooting

```bash
docker compose -p super8-mobile ps
docker compose -p super8-mobile logs --tail=100 app
curl -v http://127.0.0.1:8513/api/health
sudo nginx -t
sudo journalctl -u nginx -n 100 --no-pager
```

For Google origin errors, first compare the client ID used in the built frontend with the OAuth client whose authorized origins contain both production domains. Do not expose the complete client ID or any env values in logs.
