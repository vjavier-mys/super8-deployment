# Kasuki Evaluator

## Staging deployment

| Item | Value |
|---|---|
| Repository | `git@github.com:My-Suki/kasuki-evaluator.git` |
| Branch | `main` |
| Deployed commit | `82ed4dec8e0a92820585ef5d27b2c249231d72fa` |
| Server | `ubuntu-02` / `206.189.38.17` |
| App path | `/home/deploy/apps/kasuki-evaluator` |
| Compose project | `kasuki-evaluator` |
| Private port | `127.0.0.1:8517` |
| Health endpoint | `http://127.0.0.1:8517/api/health` |
| Intended hostname | `kasuki-evaluator.mysuki.net` |

The repository does not contain Docker deployment files. The staging deployment uses the infrastructure templates in `templates/kasuki-evaluator/` and preserves the server `.env` file outside Git.

## Deploy

Run as `deploy` on droplet2:

```bash
DRY_RUN=1 /home/deploy/scripts/deploy-staging.sh evaluator main
/home/deploy/scripts/deploy-staging.sh evaluator main
```

The script creates numbered backups using the standard `backup1`/`backup2`/`backup3` convention and verifies `/api/health` before completing.

## Revert

```bash
/home/deploy/scripts/revert-staging.sh --list evaluator
/home/deploy/scripts/revert-staging.sh evaluator
/home/deploy/scripts/revert-staging.sh evaluator 2
```

The current baseline is retained as:

```text
/home/deploy/apps/kasuki-evaluator.backup1-82ed4dec8e0a92820585ef5d27b2c249231d72fa
```

## Public access

The app is available at:

```text
https://kasuki-evaluator.mysuki.net
```

- DNS A record points to `206.189.38.17`.
- nginx proxies the hostname to `127.0.0.1:8517`.
- HTTP redirects to HTTPS.
- Let’s Encrypt certificate is valid through `2027-01-09` and automatic renewal is enabled.
