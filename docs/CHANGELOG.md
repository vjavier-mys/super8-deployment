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
- HTTPS remains pending a certificate contact email. Existing `kasuki-s8.mysuki.net` DNS was not changed.