# AWS EC2 Deployment Guide

> This guide was written and validated locally with Docker Compose. The AWS steps below have **not** been executed in this environment because no AWS credentials or EC2 instance were available. Follow them exactly to perform the real deployment.

## 1. Provision EC2

1. Launch an **Ubuntu 22.04 LTS** (or 24.04) instance.
   - Instance type: `t3.small` or larger (two application colours + PostgreSQL).
   - Storage: 20 GB gp3.
2. Create a security group:
   - **22/tcp** — SSH, restricted to your IP.
   - **80/tcp** — HTTP, from `0.0.0.0/0`.
   - **443/tcp** — HTTPS, from `0.0.0.0/0` (if using TLS).
   - **Do not open 5432.**
3. Create an IAM role (optional but recommended) or use an SSH key pair.

## 2. Prepare the host

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker "$USER"
newgrp docker

docker --version
docker compose version
```

## 3. Clone and configure

```bash
sudo mkdir -p /opt/shopnest
sudo chown "$USER":"$USER" /opt/shopnest
git clone https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment.git /opt/shopnest
cd /opt/shopnest

cp .env.example .env
# Edit .env:
#   POSTGRES_PASSWORD=<strong unique password>
#   GATEWAY_PORT=80
#   PUBLIC_URL=http://<your-domain-or-ip>
```

Generate a strong password:

```bash
openssl rand -base64 32
```

## 4. First deployment (manual bootstrap)

```bash
cd /opt/shopnest
docker compose up -d --build
docker compose ps
curl -fsS http://localhost/healthz
curl -fsS http://localhost/api/info
```

Expected: all services `healthy`; `/api/info` returns JSON with `name`, `version`, `commit`.

## 5. GitHub configuration

### Secrets (per environment)

Create two environments: `staging` and `production`.

For **each** environment add:

| Secret | Example value |
|---|---|
| `EC2_HOST` | `staging.example.com` or `1.2.3.4` |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | the private OpenSSH key (PEM) |

### Variables (repository level)

| Variable | Example value |
|---|---|
| `APP_DIR` | `/opt/shopnest` |
| `STAGING_URL` | `http://staging.example.com` |
| `PRODUCTION_URL` | `https://shopnest.example.com` |
| `EC2_PORT` | `22` (optional) |

### Environment protection

- `production` → **Required reviewers**: add at least one reviewer.
- Optionally restrict deployment branches to `main`.

### Branch protection

See [CI_CD.md](CI_CD.md#branch-protection).

## 6. How a release flows

```text
push / merge to main
  └─ ci.yml
       ├─ frontend (Node 20 + 22): lint, test, build
       ├─ backend (.NET 10): format, build, test, publish
       └─ docker: build + push ghcr.io/<owner>/shopnest-app-{backend,frontend}:sha-<commit>
  └─ cd.yml (workflow_run)
       ├─ prepare: resolve sha-<commit>
       ├─ deploy-staging: SSH -> scripts/bg-deploy.sh -> smoke test
       └─ deploy-production: approval -> SSH -> scripts/bg-deploy.sh -> smoke test
```

## 7. Verifying a deployment

```bash
# On the server
cd /opt/shopnest
docker compose ps
grep -o 'server [a-z]*-frontend' nginx/gateway/default.conf

# Through the public URL
curl -fsS https://<domain>/healthz
curl -fsS https://<domain>/api/info
curl -fsS https://<domain>/api/products
```

`/api/info.commit` must equal the Git SHA shown in the GitHub Actions run. This is how each deployment is traced back to its exact commit.

## 8. Rollback

```bash
cd /opt/shopnest
./scripts/rollback.sh                     # previous colour
./scripts/rollback.sh sha-<commit> green  # specific tag on a specific colour
```

Or use the `CD` workflow → **Run workflow** → `action=rollback`.

## 9. Troubleshooting

| Symptom | Check |
|---|---|
| `unhealthy` backend | `docker compose logs blue-backend` — verify `ConnectionStrings__Default`, DB health. |
| `unhealthy` frontend | `docker compose logs blue-frontend` — verify `BACKEND_HOST` and `/api` proxy. |
| Gateway 502 | The active colour is down; check `docker compose ps` and switch with `scripts/rollback.sh`. |
| Cannot pull image | Confirm `docker login ghcr.io` succeeded and the package exists with the expected tag. |
| SSH permission denied | Confirm the key matches `EC2_SSH_KEY` and the user is in the `docker` group. |

## 10. TLS (optional, recommended for production)

Terminate TLS at an **Application Load Balancer** in front of EC2, or install a certificate at the Nginx gateway and expose 443. Keep port 80 as an HTTP→HTTPS redirect. The application does not handle TLS itself.