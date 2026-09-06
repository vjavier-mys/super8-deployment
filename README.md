# ubuntu3 infrastructure

Infrastructure and operational notes for `ubuntu3` (`droplet3.mysuki.net`).

## Repository rules

- Never commit private keys, tokens, passwords, `.env` files, or provider credentials.
- Record infrastructure changes and verification results in `docs/CHANGELOG.md`.
- Keep application source and application secrets separate from this repository.

## Current server

- Provider: DigitalOcean
- Droplet: `ubuntu3`
- Region: Singapore (`sgp1`)
- OS: Ubuntu 24.04 LTS
- Size: 1 vCPU / 2 GB RAM / 50 GB disk
- Public hostname: `droplet3.mysuki.net`
- Reverse proxy: nginx
- Container runtime: Docker Engine + Compose plugin

## Planned next steps

- Add Victor's personal SSH public key to `/home/deploy/.ssh/authorized_keys`.
- Reboot during an approved maintenance window to load the updated kernel.
- Configure the application-specific nginx upstream and proxy rules.
- Issue and verify a Let's Encrypt certificate for `droplet3.mysuki.net`.
- Add deployment instructions after the Node application is available.

## Manual laptop deployment

The reusable deployment script is `scripts/deploy-kasuki.sh`. It is intended to run from a checked-out copy of the application repository on Victor's laptop.

Prerequisites:

- SSH access to the server as `deploy` using a personal laptop key.
- The application repository checked out locally.
- Docker Compose available on the server (already installed).
- The server-side `/home/deploy/apps/kasuki-super8/.env` remains in place; it is never copied from Git or committed.

Example:

```bash
chmod +x scripts/deploy-kasuki.sh
export DEPLOY_SSH_KEY="$HOME/.ssh/ubuntu3_deploy"
./scripts/deploy-kasuki.sh release-candidate-1
```

The script archives the selected Git commit, uploads it over SSH, builds the Docker image, starts the same Compose project, checks `/api/health`, and records the deployed commit in `CURRENT_RELEASE`. Releases are stored under `/home/deploy/apps/kasuki-super8/releases/` for rollback. It does not modify nginx or copy secrets.

GitHub Actions deployment can be added later using a separate encrypted SSH key and repository secrets; do not put the production `.env` in GitHub Actions or the application repository.

## Remote repository

No Git remote is configured yet. Add the remote only after the destination repository is supplied and approved.