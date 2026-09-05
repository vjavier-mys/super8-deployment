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

## Remote repository

No Git remote is configured yet. Add the remote only after the destination repository is supplied and approved.