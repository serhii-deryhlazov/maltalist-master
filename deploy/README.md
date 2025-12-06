# Deployment Scripts

Scripts for deploying MaltaListing services to production.

## Prerequisites

- Docker and Docker Compose installed locally
- SSH access to the production server (`root@162.0.222.102`)
- SSH key configured for passwordless authentication

## Scripts

### `deploy.sh`

Main deployment script that builds, transfers, and deploys selected services to production.

#### Usage

```bash
./deploy.sh [OPTIONS]
```

#### Options

| Option | Description |
|--------|-------------|
| `--api` | Deploy API service |
| `--ui` | Deploy UI service |
| `--monitoring` | Deploy monitoring service |
| `--all` | Deploy all services |
| `-h, --help` | Show help message |

#### Examples

```bash
# Deploy only the API
./deploy.sh --api

# Deploy API and UI together
./deploy.sh --api --ui

# Deploy everything
./deploy.sh --all
```

#### What it does

1. **Builds** selected services for `linux/amd64` platform
2. **Saves** Docker images to `.tar` files
3. **Transfers** images and config files to the server via SCP
4. **Runs** `run-prod.sh` on the server to load and restart services

### `run-prod.sh`

Server-side script that loads Docker images and gracefully restarts selected services.

#### Usage (on server)

```bash
./run-prod.sh [OPTIONS]
```

Same options as `deploy.sh`: `--api`, `--ui`, `--monitoring`, `--all`

#### What it does

1. **Loads** Docker images from `.tar` files
2. **Restarts** only the specified services (using `--no-deps --force-recreate`)
3. **Cleans up** `.tar` files and dangling images

## Server Configuration

| Setting | Value |
|---------|-------|
| Server IP | `162.0.222.102` |
| User | `root` |
| Docker path | `/var/www/docker` |

## Files Transferred

Each deployment transfers:

- Docker image `.tar` files (for selected services)
- `docker-compose.prod.yml`
- `run-prod.sh`
- `files/backups/backup.sh`
- `maltalist-api/init-db.sh`
- `maltalist-angular/nginx.conf`

## Workflow

```
Local Machine                         Production Server
─────────────────────────────────────────────────────────
docker-compose build ──────────────────────────────────→
docker save *.tar    ──────────────────────────────────→
                            scp *.tar ─────────────────→ /var/www/docker/
                            ssh run-prod.sh ───────────→ docker load
                                                         docker-compose up -d
```
