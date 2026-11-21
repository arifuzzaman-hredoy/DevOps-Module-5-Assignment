# Rollback Runbook

## Automatic rollback (built into every deployment)

`scripts/bg-deploy.sh` automatically switches back to the previous colour if:

- the new backend/frontend becomes `unhealthy`;
- the internal smoke test fails;
- the public health check fails after the traffic switch.

It never leaves the inactive colour serving traffic on failure.

### Evidence

```text
[INFO] Switching gateway traffic: green -> blue
[WARN] SIMULATE_FAILURE=post -> failing post-switch verification; rolling back.
[ OK ] Automatic rollback to 'green' completed.
[FAIL] Simulated post-switch failure (rolled back to 'green')
active after:  server green-frontend
[ OK ] All smoke tests passed
```

Full log: [evidence/rollback.md](evidence/rollback.md).

## Manual rollback

### Fastest path — previous colour

```bash
cd /opt/shopnest
./scripts/rollback.sh
```

This switches the gateway back to the colour that was active before the last deployment. It is a Nginx reload, typically **sub-second**.

### Specific release

Every image is tagged with the commit that produced it (`sha-<short>`). To roll back to a specific version:

```bash
./scripts/rollback.sh sha-1a2b3c4 blue
```

- `sha-1a2b3c4` — the image tag to deploy.
- `blue` — optional target colour; defaults to the inactive colour.

The script pulls the tag (unless `PULL_IMAGES=false`), starts it on the target colour, waits for health, switches traffic, and verifies the public endpoint. On failure it restores the previous upstream.

### Via GitHub Actions

1. Open **Actions → CD → Run workflow**.
2. Set:
   - `action` = `rollback`
   - `environment` = `production`
   - `image_tag` = `sha-<commit>`
   - `colour` = `auto` (or `blue`/`green`)
3. Approve the `production` environment if prompted.

The workflow SSHes to EC2, runs `scripts/rollback.sh`, and runs the smoke test.

## Finding a known-good version

- **GHCR**: every successful CI run on `main` produces `sha-<commit>` tags.
- **GitHub Actions**: the deployment record shows the image tag and the commit.
- **Runtime**: `GET /api/info` returns `{"name":"ShopNest API","version":"sha-...","commit":"..."}`.
- **Git**: `git log --oneline` maps the short SHA to the commit.

## Verifying a rollback

```bash
cd /opt/shopnest
docker compose ps
grep -o 'server [a-z]*-frontend' nginx/gateway/default.conf
./scripts/smoke-test.sh "$PUBLIC_URL"
curl -fsS "$PUBLIC_URL/api/info"
```

Expected: all services healthy, active colour is the rollback target, smoke tests pass, and `/api/info.commit` matches the rolled-back version.

## Post-rollback actions

1. Confirm user-facing functionality (storefront + product details).
2. Check backend logs for errors: `docker compose logs --tail=200 blue-backend green-backend`.
3. Record the incident: which tag was active, which tag was deployed, why the health check failed.
4. Fix forward and redeploy through the normal pipeline; do not leave the system on an untested manual state.