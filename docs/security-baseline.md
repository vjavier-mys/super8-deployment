# Security Baseline

This baseline is applied to `ubuntu3` before hosting public applications.

## Host hardening

- Ubuntu 24.04 LTS packages upgraded.
- Docker Engine installed from Docker's official Ubuntu repository.
- Docker Compose plugin and Buildx installed.
- nginx, fail2ban, unattended-upgrades, and apt-listchanges installed.
- `deploy` user created with a locked password and SSH-key-only access.
- `deploy` belongs to the `sudo` and `docker` groups.
- `deploy` has passwordless sudo for automation; access is controlled by SSH keys.
- Root SSH login disabled.
- SSH password and keyboard-interactive authentication disabled.
- X11 forwarding disabled.
- SSH access limited to the `deploy` account.
- UFW enabled with inbound TCP 22, 80, and 443 only.
- Default inbound policy is deny; default outbound policy is allow.
- fail2ban SSH jail active.
- 2 GiB swapfile enabled and persisted in `/etc/fstab`.
- nginx, Docker, containerd, fail2ban, and unattended-upgrades enabled at boot.

## Application isolation

- Kasuki Assistant uses `/home/deploy/apps/kasuki-super8` and localhost port `8510`.
- Kasuki Mobile uses `/home/deploy/apps/super8-mobile` and localhost port `8513`.
- nginx is the only public application entry point.
- Application `.env` files are server-only, mode `600`, and outside Git.
- Assistant `data/` is preserved during deployments.
- Each application has its own Docker Compose project name and directory.

## TLS

Active public hostnames:

```text
https://kasuki-s8.mysuki.io
https://kasuki-s8-mobile.mysuki.io
```

Certificates are issued by Let's Encrypt and renewed by Certbot's scheduled timer. Validate before and after nginx changes:

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo certbot renew --dry-run
```

## Access and key handling

Private keys are never stored in this repository. Use separate keys for:

- Laptop-to-server SSH access.
- GitHub repository access.
- CI/CD access, if added later.

Record only public-key fingerprints in operational notes. Never commit private keys, tokens, passwords, provider credentials, MongoDB URIs, or environment file contents.

## Routine checks

```bash
sudo apt-get update
sudo unattended-upgrade --dry-run --debug
sudo ufw status verbose
sudo fail2ban-client status sshd
sudo systemctl is-active docker nginx fail2ban unattended-upgrades
```

Apply security updates during an approved maintenance window and reboot when the kernel requires it.
