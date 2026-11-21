# Automatic Rollback — Staging Evidence

**Date:** 2026-11-21
**Environment:** Staging only (`/opt/shopnest-staging`)
**Command:** `SIMULATE_FAILURE=post PULL_IMAGES=false bash ./scripts/bg-deploy.sh sha-0e21c4d`
**Result:** Automatic rollback completed successfully; staging remained on `green` with `sha-0e21c4d`; production was not touched.

## Exact terminal output

```text
=== BEFORE: staging API ===
{"name":"ShopNest API","version":"sha-0e21c4d","commit":"0e21c4d"}
=== BEFORE: active colour ===
server green-frontend
=== BEFORE: production ===
production HTTP 200

=== RUNNING: SIMULATE_FAILURE=post bg-deploy.sh sha-0e21c4d ===
[INFO] Current active colour : green
[INFO] Deploying new release : blue (tag: sha-0e21c4d)
[INFO] Backend image         : shopnest-app-backend:sha-0e21c4d
[INFO] Frontend image        : shopnest-app-frontend:sha-0e21c4d
[INFO] Starting 'blue' environment ...
 Container shopnest-staging-blue-backend-1 Recreate
 Container shopnest-staging-blue-backend-1 Recreated
 Container shopnest-staging-blue-frontend-1 Recreate
 Container shopnest-staging-blue-frontend-1 Recreated
 Container shopnest-staging-blue-backend-1 Starting
 Container shopnest-staging-blue-backend-1 Started
 Container shopnest-staging-blue-backend-1 Waiting
 Container shopnest-staging-blue-backend-1 Healthy
 Container shopnest-staging-blue-frontend-1 Starting
 Container shopnest-staging-blue-frontend-1 Started
[ OK ] Service 'blue-backend' is healthy
[ OK ] Service 'blue-frontend' is healthy
[INFO] Running internal smoke tests against 'blue' ...
[ OK ] Internal smoke tests passed
[INFO] Switching gateway traffic: green -> blue
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
2026/11/21 09:43:46 [notice] 120#120: signal process started
[WARN] SIMULATE_FAILURE=post -> failing post-switch verification; rolling back.
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
2026/11/21 09:43:48 [notice] 141#141: signal process started
[FAIL] Simulated post-switch failure (rolled back to 'green')
[ OK ] Automatic rollback to 'green' completed.

=== AFTER: staging API ===
{"name":"ShopNest API","version":"sha-0e21c4d","commit":"0e21c4d"}
=== AFTER: active colour ===
server green-frontend
=== AFTER: production ===
production HTTP 200
```

## Required lines (for screenshot)

- `Switching gateway traffic: green -> blue`
- `SIMULATE_FAILURE=post`
- `Automatic rollback to 'green' completed.`

## Verification

- Staging active colour after rollback: `green`
- Staging version after rollback: `sha-0e21c4d`
- Production: HTTP 200, `sha-0e21c4d` (unaffected)
- All staging containers: healthy