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