# Super8 Deployment Infrastructure

Operational documentation for the two production applications hosted on the Ubuntu server `ubuntu3`.

## Choose an application

- [Kasuki Super8 Assistant](docs/kasuki-super8-assistant/README.md)
- [Kasuki Super8 Mobile](docs/super8-mobile/README.md)
- [Shared server, security, DNS, TLS, and recovery runbook](docs/OPERATIONS.md)
- [Combined deployment history](docs/CHANGELOG.md)

## Current deployment map

| Environment | Application | Repository | URL | Server | App path | Private port |
|---|---|---|---|---|---|---:|
| Production | Kasuki Super8 Assistant | `My-Suki/kasuki-super8` | `https://kasuki-s8.mysuki.io` | `ubuntu3` / `168.144.110.200` | `/home/deploy/apps/kasuki-super8` | `8510` |
| Production | Kasuki Super8 Mobile | `My-Suki/super8-mobile` | `https://kasuki-s8-mobile.mysuki.io` | `ubuntu3` / `168.144.110.200` | `/home/deploy/apps/super8-mobile` | `8513` |
| Staging | Kasuki Super8 Assistant | `My-Suki/kasuki-super8` | `https://kasuki-s8.mysuki.net` | `ubuntu-02` / `206.189.38.17` | `/home/deploy/apps/kasuki-super8` | `8510` |
| Staging | Kasuki Super8 Mobile | `My-Suki/super8-mobile` | `https://kasuki-s8-mobile.mysuki.net` | `ubuntu-02` / `206.189.38.17` | `/home/deploy/apps/super8-mobile` | `8513` |

The `.io` domains are production and the `.net` domains are staging. All services are exposed publicly only through nginx over HTTPS. Docker publishes each application on localhost; the application ports are not directly exposed to the Internet.

## Repository safety rules

- Never commit private keys, tokens, passwords, `.env` files, provider credentials, or MongoDB connection strings.
- Production environment files remain on the server and are installed with mode `600`.
- Keep application source repositories separate from this infrastructure repository.
- Record operational changes in the combined `docs/CHANGELOG.md`.
- Use a dedicated SSH key for each purpose: server access, GitHub repository access, and CI/CD.

## Local repository

This repository is intended to be cloned by an operator with access to:

```text
git@github.com:vjavier-mys/super8-deployment.git
```

The deployment scripts in `scripts/` are reference implementations. They never copy production secrets from Git.
