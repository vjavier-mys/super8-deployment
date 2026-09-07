# Change log

## 2026-09-05 — Initial baseline

- Confirmed an existing DigitalOcean droplet already matched the requested `ubuntu3` name and 2 GB Ubuntu specification; no duplicate droplet was created.
- Confirmed the existing DNS A record: `droplet3.mysuki.net` → `168.144.110.200`.
- Verified Ubuntu 24.04 LTS, 1 vCPU, 2 GB RAM, 50 GB disk.
- Applied available Ubuntu package updates.
- Installed nginx and verified the default HTTP endpoint returns `200 OK`.
- Installed Docker Engine 29.8.0, Docker Compose, and Buildx.
- Created the locked-password `deploy` administrator with SSH key access and passwordless sudo.
- Disabled root SSH access and SSH password authentication.
- Enabled UFW with only ports 22, 80, and 443 allowed inbound.
- Enabled fail2ban and unattended security upgrades.
- Added and persisted a 2 GiB swapfile.
- Verified: deploy SSH works; root SSH is rejected; Docker, nginx, fail2ban, and unattended-upgrades are active and enabled.
- Pending: Victor's personal SSH key, approved reboot for the updated kernel, HTTPS certificate, and application-specific nginx proxy configuration.

## 2026-09-05 — Kasuki Super8 release-candidate deployment

- Verified Git ref `release-candidate-1` at commit `71466327d55ccfc60a4fe3b60f3f1904627dc98b` (`0.9.0-rc.1`).
- Deployed the application source to `/home/deploy/apps/kasuki-super8` on `ubuntu3`.
- Installed the supplied MongoDB environment configuration outside Git with mode `600`; no secrets were committed or printed.
- Built and started the Docker Compose application on `127.0.0.1:8510`.
- Updated the MongoDB URL after the first Atlas endpoint failed; the application then initialized successfully.
- Added nginx reverse proxy for `droplet3.mysuki.net` and verified public HTTP plus `/api/health`.
- Verified response: `{"ok":true,"version":"0.9.0-rc.1","debug":false}`.
- HTTPS was configured later under the separate HTTPS hostname setup entry. Existing `kasuki-s8.mysuki.net` DNS was not changed.

## 2026-09-05 — HTTPS hostname setup

- Configured nginx for `kasuki-s8.mysuki.io` while retaining `droplet3.mysuki.net`.
- Installed Certbot and the nginx plugin.
- Issued a Let's Encrypt ECDSA certificate covering both hostnames; expiry is 2026-12-04.
- Enabled HTTP-to-HTTPS redirects and verified the public app and `/api/health` over HTTPS.
- Verified the Certbot renewal timer is enabled.

## 2026-09-06 — Super8 Mobile release-candidate deployment

- Verified tag `release-candidate-1` at commit `db421fcb1ac2660180edf540ff4871cebba135f8`.
- Deployed the Next.js app to `/home/deploy/apps/super8-mobile`.
- Corrected one malformed comment marker in the supplied env file; retained the original as a root-owned backup.
- Installed the supplied environment outside Git with mode `600`.
- Built the Docker image with zero npm vulnerabilities reported and started the app on private port `127.0.0.1:8513`.
- Verified local health response: `{"ok":true,"version":"0.2.1"}`.
- Configured nginx for `kasuki-s8-mobile.mysuki.io`.
- Issued a Let's Encrypt ECDSA certificate; expiry is 2026-12-05.
- Verified public HTTPS, HTTP-to-HTTPS redirect, and `/api/health`.

## 2026-09-06 — Super8 Mobile Google OAuth origin fix

- Diagnosed origin mismatch: the mobile app used a different Google client ID than the existing Kasuki app, even though the mobile origin had been added to the other client.
- Aligned `GOOGLE_CLIENT_ID`, `NEXT_PUBLIC_GOOGLE_CLIENT_ID`, and `VITE_GOOGLE_CLIENT_ID` with the shared client configured for the approved production origins.
- Rebuilt and restarted the mobile Docker image because the Next.js public client ID is baked into the bundle.
- Verified mobile health remains `{"ok":true,"version":"0.2.1"}`. Secrets remain outside Git.

## 2026-09-06 — Super8 Mobile release-candidate-1 redeployment

- Verified tag `release-candidate-1` at commit `db421fcb1ac2660180edf540ff4871cebba135f8`.
- Backed up the previous app tree as `/home/deploy/apps/super8-mobile.before-mobile-rc1-20260906021019`.
- Preserved the production `.env` at mode `600` and redeployed the source separately from Kasuki Assistant.
- Rebuilt/verified the Docker Compose service on `127.0.0.1:8513`.
- Verified local and public HTTPS health: `{"ok":true,"version":"0.2.1"}`.
- Verified `kasuki-s8-mobile.mysuki.io` continues to return HTTP 200 with its existing TLS certificate.

## 2026-09-06 — Kasuki Assistant release-candidate-1.1 deployment

- Verified tag/branch `release-candidate-1.1` at commit `9815eaaaa6d90ae0c58664f6f56b7ca777728ca1`.
- Backed up the prior application tree as `/home/deploy/apps/kasuki-super8.before-rc11-20260906020222`.
- Preserved the server-side `.env` and live `data/` directory; `.env` remains mode `600`.
- Built and restarted the Docker Compose service on `127.0.0.1:8510`.
- Verified local and public HTTPS health: `{"ok":true,"version":"0.9.1-rc.1","debug":false}`.
- Verified `kasuki-s8.mysuki.io` continues to return HTTP 200 with its existing TLS certificate.
- Build reported one moderate npm audit finding; dependencies were not automatically changed.

## 2026-09-06 — Root SSH key exception

- Installed Victor's supplied public key in `/root/.ssh/authorized_keys` with root-only ownership and mode `600`.
- Changed the SSH policy to `PermitRootLogin prohibit-password`; root password and keyboard-interactive authentication remain disabled.
- Updated `AllowUsers` to permit only `deploy` and root key authentication.
- Validated `sshd -t`, reloaded SSH, and verified the existing `deploy` key login still works.
- The matching private key remains on Victor's laptop and was never requested or handled by Hermes.

## 2026-09-06 — Staging deployment on droplet2

- Verified `ubuntu-02` at `206.189.38.17` and established root access using the approved Hermes key.
- Applied the Ubuntu 24.04 staging baseline: package updates, Docker/Compose, nginx, Certbot, UFW, fail2ban, unattended upgrades, 2 GiB swap, and key-only `deploy` access.
- Deployed Kasuki Assistant commit `9815eaaaa6d90ae0c58664f6f56b7ca777728ca1` to `/home/deploy/apps/kasuki-super8` on `127.0.0.1:8510`.
- Deployed Super8 Mobile commit `db421fcb1ac2660180edf540ff4871cebba135f8` to `/home/deploy/apps/super8-mobile` on `127.0.0.1:8513`.
- Installed both staging env files with mode `600`; no secret values were printed or committed.
- Configured staging DNS and HTTPS: `kasuki-s8.mysuki.net` and `kasuki-s8-mobile.mysuki.net` point to `206.189.38.17`.
- Expanded the Mobile staging certificate to cover `super8.mysuki.net` and `kasuki-s8-mobile.mysuki.net`.
- Verified both public HTTPS health endpoints, HTTP-to-HTTPS redirects, nginx syntax, and running containers.

## 2026-09-06 — Super8 Mobile staging redeployment (`release-candidate-1.1`)

- Verified the repository tag `release-candidate-1.1` resolves to commit `216f1c04149cc2f17b69a36364514f83602f15af`.
- Replaced the staging Mobile source on droplet2 at `/home/deploy/apps/super8-mobile`; the previous tree was retained as a timestamped backup.
- Preserved the staging `.env` with mode `600` and owner `deploy:deploy`.
- Rebuilt and restarted the Compose project on `127.0.0.1:8513`.
- Verified version `0.2.1-rc.1`, local/public health, HTTPS status `200`, HTTP-to-HTTPS redirect, and container restart count `0`.

## 2026-09-06 — Victor deploy-user SSH key

- Installed the same Victor-supplied public key in `/home/deploy/.ssh/authorized_keys`.
- Preserved key-only access and verified the authorized-keys file is owned by `deploy:deploy` with mode `600`.
- Validated the SSH configuration after the change; no private key was handled.

## 2026-09-06 — Enable real SMS OTP on production Mobile

- Investigated missing OTP reports on droplet3.
- Found the Mobile app logging `[mock SMS]` because `USE_MOCK` was absent; the code treats any value other than `false` as mock mode.
- Set `USE_MOCK=false` in `/home/deploy/apps/super8-mobile/.env` on droplet3, preserving mode `600` and owner `deploy:deploy`.
- Recreated the container and verified `USE_MOCK=false`, health `ok`, and restart count `0`.
- No secret values or OTP contents were recorded.

## 2026-09-06 — Kasuki S8 Portal staging deployment

- Verified repository `My-Suki/kasuki-portal-super8-edition` main commit `95617a470edc7f1013d319e4408cc217a5b1e0d2`, version `0.3.0-rc1`.
- Deployed as a separate application at `/home/deploy/apps/kasuki-s8-portal`; the existing `/opt/apps/kasuki-portal` deployment was not modified.
- Installed the provided staging env as `.env` with mode `600` and owner `deploy:deploy`.
- Configured the new Compose project/container as `kasuki-s8-portal` on `127.0.0.1:8514`.
- Created `kasuki-s8-portal.mysuki.net` DNS pointing to `206.189.38.17`.
- Configured nginx and issued a Let’s Encrypt certificate with HTTP-to-HTTPS redirect.
- Verified public health `{"ok":true,"version":"0.3.0-rc1"}`, HTTPS status `200`, and no restart loop.
- Confirmed Assistant `8510`, Mobile `8513`, existing portal `8512`, and new Portal `8514` are separate running services.

## 2026-09-06 — Kasuki S8 Portal production deployment

- Deployed the same verified commit `95617a470edc7f1013d319e4408cc217a5b1e0d2` (`0.3.0-rc1`) to droplet3.
- Installed `/home/deploy/dropbox/env_production` as `/home/deploy/apps/kasuki-s8-portal/.env` with mode `600` and owner `deploy:deploy`.
- Configured the production Compose project/container `kasuki-s8-portal` on `127.0.0.1:8514`.
- Created the compatibility Docker network required by the Compose file; production API/auth services remain remote HTTPS endpoints.
- Configured `kasuki-s8-portal.mysuki.io` in nginx and issued a Let’s Encrypt certificate.
- Verified public health `{"ok":true,"version":"0.3.0-rc1"}`, HTTPS status `200`, HTTP-to-HTTPS redirect, and existing Assistant/Mobile services remained healthy.

## 2026-09-06 — Unified manual deployment script

- Added `scripts/deploy-super8.sh` for manual branch/tag deployments of Assistant, Mobile, or Portal to staging or production.
- The script verifies the expected repository and remote ref, archives source without `.git` or local env files, preserves server `.env` and application data, creates a backup, rebuilds/recreates the correct Compose project, verifies health, and rolls back on failure.
- Added dry-run support with `DRY_RUN=1`; DNS, nginx, and certificates remain outside the script’s scope.