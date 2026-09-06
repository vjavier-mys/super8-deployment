# Shared Operations Runbook

This document covers the infrastructure shared by Kasuki Super8 Assistant and Kasuki Super8 Mobile.

## 1. Server inventory

| Item | Value |
|---|---|
| Provider | DigitalOcean |
| Droplet | `ubuntu3` |
| Region | Singapore (`sgp1`) |
| OS | Ubuntu 24.04 LTS |
| Size | 1 vCPU, 2 GB RAM, 50 GB disk |
| Public IP | `168.144.110.200` |
| Public hostname | `droplet3.mysuki.net` |
| SSH user | `deploy` |
| SSH access | Key-only; root key exception enabled, root password login disabled |

The `deploy` account has a locked password, belongs to the Docker group, and has passwordless sudo for automation. Password SSH remains disabled; root access is restricted to the explicitly authorized public key.

## 2. Required server packages

The baseline requires:

- Docker Engine, Docker Compose plugin, and Buildx
- nginx
- Certbot with the nginx plugin
- fail2ban
- unattended-upgrades and apt-listchanges
- UFW
- A persistent 2 GiB swapfile

Enable and verify the services:

```bash
sudo systemctl enable --now docker nginx fail2ban unattended-upgrades
sudo nginx -t
sudo ufw status verbose
sudo systemctl is-active docker nginx fail2ban unattended-upgrades
```

Firewall policy:

```text
Inbound allowed: TCP 22, 80, 443
Default inbound: deny
Default outbound: allow
```

The server baseline is documented in [`security-baseline.md`](security-baseline.md).

## 3. DNS

Current records:

```text
droplet3.mysuki.net       A 168.144.110.200
kasuki-s8.mysuki.io       A 168.144.110.200
kasuki-s8-mobile.mysuki.io A 168.144.110.200
```

The `.net` DNS zone is managed in DigitalOcean. The `.io` zone is managed in AWS Route 53. Verify DNS before requesting a certificate:

```bash
getent ahostsv4 kasuki-s8.mysuki.io
getent ahostsv4 kasuki-s8-mobile.mysuki.io
```

## 4. TLS and nginx

nginx terminates TLS and proxies to localhost-only Docker ports. HTTP redirects to HTTPS. Certificates are managed by Certbot:

```bash
sudo certbot certificates
sudo systemctl list-timers certbot.timer
sudo certbot renew --dry-run
```

Certificate names:

```text
kasuki-s8.mysuki.io
kasuki-s8-mobile.mysuki.io
droplet3.mysuki.net and kasuki-s8.mysuki.io may share a certificate depending on the current nginx configuration.
```

Never replace nginx configuration without running `sudo nginx -t` and reloading only after the test succeeds.

## 5. Environment files

Production env files are not stored in Git:

```text
/home/deploy/apps/kasuki-super8/.env
/home/deploy/apps/super8-mobile/.env
```

Required permissions:

```bash
sudo chown deploy:deploy /home/deploy/apps/kasuki-super8/.env /home/deploy/apps/super8-mobile/.env
sudo chmod 600 /home/deploy/apps/kasuki-super8/.env /home/deploy/apps/super8-mobile/.env
```

The env files contain credentials and OAuth values. Do not print them, put them in issue comments, or include them in Docker build output. Backups must also remain mode `600` and outside Git.

## 6. Common verification

```bash
curl -fsS https://kasuki-s8.mysuki.io/api/health
curl -fsS https://kasuki-s8-mobile.mysuki.io/api/health

ssh deploy@droplet3.mysuki.net \
  'docker compose -p kasuki-super8 -f /home/deploy/apps/kasuki-super8/docker-compose.yml ps; \
   docker compose -p super8-mobile -f /home/deploy/apps/super8-mobile/docker-compose.yml ps'
```

Expected health responses identify the deployed application version. A healthy container should have restart count `0` and status `running`.

## 7. Recovery principles

Before replacing an application:

1. Confirm the Git ref and commit.
2. Confirm the production `.env` exists and is mode `600`.
3. Back up the current application tree.
4. Preserve application data. Assistant uses `/home/deploy/apps/kasuki-super8/data`.
5. Build the new image before starting it.
6. Check the local health endpoint.
7. Check the public HTTPS endpoint.
8. If health fails, stop the new container and restore the last known-good source backup, keeping the production `.env` and data.

Never solve a deployment failure by printing or copying secret values into logs.
