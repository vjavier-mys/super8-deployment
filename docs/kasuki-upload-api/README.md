# Kasuki Upload API

## Staging deployment

| Item | Value |
|---|---|
| Repository | `git@github.com:vjavier-mys/kasuki-super8-uploader-api.git` |
| Branch | `main` |
| Server | `ubuntu-02` / `206.189.38.17` |
| Hostname | `kasuki-upload-api.mysuki.net` |
| Application path | `/home/deploy/apps/kasuki-upload-api` |
| Compose project | `kasuki-upload-api` |
| Private port | `8515` |
| Health endpoint | `/api/health` |

The Upload API is a staging-only deployment at this time. Its environment file remains on droplet2 and is never copied from Git.

## Deploy from droplet2

SSH as `deploy`:

```bash
ssh deploy@droplet2.mysuki.net
```

Run a dry run first:

```bash
DRY_RUN=1 /home/deploy/scripts/deploy-staging.sh upload main
```

Deploy:

```bash
/home/deploy/scripts/deploy-staging.sh upload main
```

The script fetches the exact commit using the repository-specific read-only GitHub key, preserves `.env` and `data/`, rotates numbered backups, rebuilds only the `kasuki-upload-api` Compose project, and verifies `/api/health`.

## Revert

List available backups:

```bash
/home/deploy/scripts/revert-staging.sh --list upload
```

Revert to the previous version:

```bash
/home/deploy/scripts/revert-staging.sh upload
```

Revert to a selected older backup:

```bash
/home/deploy/scripts/revert-staging.sh upload 2
```

## Verification

```bash
curl -fsS http://127.0.0.1:8515/api/health
docker compose -p kasuki-upload-api -f /home/deploy/apps/kasuki-upload-api/docker-compose.yml ps
```

Expected health response:

```json
{"ok":true}
```

The API accepts CSV uploads and writes them to S3. Do not print or include bearer tokens, AWS credentials, bucket details, or `.env` contents in deployment logs or documentation.
