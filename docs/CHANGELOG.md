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