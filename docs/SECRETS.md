# Secrets and Configuration Management

## Principles

1. **No secrets in Git** — not in files, not in commit history.
2. **Environment separation** — staging and production have separate credentials.
3. **Least privilege** — the SSH key can deploy but should not be a root key; the DB user is scoped to the application database.
4. **Ephemeral CI credentials** — `GITHUB_TOKEN` is short-lived and scoped to the workflow.
5. **Auditability** — every deployment records the commit SHA, image tag, environment, and actor.

## What is committed

Only `.env.example`, which contains **placeholders**:

```dotenv
POSTGRES_PASSWORD=change-me-to-a-strong-password
```

`.gitignore` excludes:

```gitignore
.env
.env.*
!.env.example
secrets/
*.pem
*.key
```

## GitHub Secrets

| Secret | Scope | Purpose |
|---|---|---|
| `EC2_HOST` | `staging`, `production` | Target EC2 hostname/IP. |
| `EC2_USER` | `staging`, `production` | SSH user. |
| `EC2_SSH_KEY` | `staging`, `production` | Private SSH key used by `appleboy/ssh-action`. |
| `GITHUB_TOKEN` | automatic | GHCR login during deployment. |

> `GITHUB_TOKEN` is provided automatically by GitHub Actions. It is passed to the EC2 host only for the duration of the deploy step via `appleboy/ssh-action`'s `envs:` input. If you prefer not to send it to EC2, make the GHCR packages public or add a dedicated `GHCR_PAT` secret with `read:packages`.

## GitHub Variables

| Variable | Scope | Purpose |
|---|---|---|
| `APP_DIR` | repository | Checkout path on EC2, e.g. `/opt/shopnest`. |
| `STAGING_URL` | repository | Public staging URL for smoke tests. |
| `PRODUCTION_URL` | repository | Public production URL for smoke tests. |
| `EC2_PORT` | repository (optional) | SSH port; defaults to `22`. |

## Runtime environment variables

| Name | Purpose |
|---|---|
| `POSTGRES_DB` | Database name. |
| `POSTGRES_USER` | Database user. |
| `POSTGRES_PASSWORD` | Database password (**secret**). |
| `ASPNETCORE_ENVIRONMENT` | `Production` or `Staging`. |
| `APP_VERSION` | Build version surfaced by `/api/info`. |
| `APP_COMMIT` | Commit SHA surfaced by `/api/info`. |
| `GATEWAY_PORT` | Host port for the public gateway. |
| `PUBLIC_URL` | Base URL for scripts. |
| `REGISTRY` | Container registry (`ghcr.io`). |
| `IMAGE_TAG` | Immutable image tag (`sha-<commit>`). |
| `BACKEND_IMAGE` / `FRONTEND_IMAGE` | Full image references (set by CI/CD). |
| `PULL_IMAGES` | `true` pulls from GHCR; `false` uses local images. |

## Local development

```bash
cp .env.example .env
# edit .env with a local password
docker compose up -d --build
```

The local `.env` is never committed.

## Rotating credentials

- **Database password**: change `POSTGRES_PASSWORD` in `.env` and the GitHub secrets, then `docker compose up -d` to recreate the database container. For an existing volume, also change the password inside PostgreSQL or recreate the volume with a migration/backup.
- **SSH key**: generate a new key pair, replace `EC2_SSH_KEY`, update the authorized key on EC2, and verify a staging deploy.
- **`GITHUB_TOKEN`**: no rotation needed; it is issued per run.

## Verifying no secrets are committed

```bash
git log --all -p | grep -Ei 'password|secret|token|private key|aws_' || echo "clean"
git status --ignored --short | grep -E '\.env$'
```

The repository history currently contains only documentation references to secrets, never values.