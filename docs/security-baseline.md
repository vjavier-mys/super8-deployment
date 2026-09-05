# Security baseline

Completed baseline configuration:

- Ubuntu packages fully upgraded.
- Docker installed from Docker's official Ubuntu repository.
- nginx, fail2ban, unattended-upgrades, and apt-listchanges installed.
- `deploy` user created with locked password and SSH-key-only access.
- `deploy` belongs to `sudo` and `docker` groups.
- `deploy` has passwordless sudo for automation; access is controlled by its SSH key.
- Root SSH login disabled.
- SSH password and keyboard-interactive authentication disabled.
- X11 forwarding disabled.
- SSH limited to the `deploy` account.
- UFW enabled with inbound SSH (22), HTTP (80), and HTTPS (443) only.
- Default inbound policy is deny; default outbound policy is allow.
- fail2ban SSH jail active.
- 2 GiB swapfile enabled and persisted in `/etc/fstab`.
- nginx, Docker, containerd, fail2ban, unattended-upgrades enabled at boot.

## Important access note

The deployment private key is not stored in this repository. The corresponding public key is installed on the server. Victor's personal public key still needs to be added before normal personal SSH access is available through `deploy`.