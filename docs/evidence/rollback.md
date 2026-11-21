# Rollback Evidence

All tests were run locally against the Docker Compose stack.

## Test 1 — automatic rollback after a post-switch failure

```bash
PULL_IMAGES=false SIMULATE_FAILURE=post ./scripts/bg-deploy.sh local
```

**Actual output**

```text
[INFO] Current active colour : green
[INFO] Deploying new release : blue (tag: local)
[INFO] Starting 'blue' environment ...
[ OK ] Service 'blue-backend' is healthy
[ OK ] Service 'blue-frontend' is healthy
[ OK ] Internal smoke tests passed
[INFO] Switching gateway traffic: green -> blue
[WARN] SIMULATE_FAILURE=post -> failing post-switch verification; rolling back.
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
[ OK ] Automatic rollback to 'green' completed.
[FAIL] Simulated post-switch failure (rolled back to 'green')

active after:  server green-frontend

[ OK ] GET /healthz -> 200
[ OK ] GET /api/info -> 200 (matched: ShopNest API)
[ OK ] GET /api/products -> 200 (matched: "id")
[ OK ] GET /api/products/1 -> 200 (matched: "name")
[ OK ] GET / -> 200
[ OK ] GET /products/1 -> 200
[ OK ] GET /api/products/999999 -> 404
[ OK ] All smoke tests passed
```

**Interpretation:** the deployment switched to Blue, failed post-switch verification, automatically switched back to Green, and the public API remained healthy.

## Test 2 — manual rollback

```bash
PULL_IMAGES=false ./scripts/rollback.sh local
```

**Actual output**

```text
[INFO] Manual rollback requested. Current='green' Target='blue'
 Container shopnest-blue-backend Running
 Container shopnest-blue-frontend Running
[ OK ] Service 'blue-backend' is healthy
[ OK ] Service 'blue-frontend' is healthy
[ OK ] Rollback complete. Active colour: blue
```

Followed by a clean smoke test:

```text
[ OK ] GET /healthz -> 200
[ OK ] GET /api/info -> 200 (matched: ShopNest API)
[ OK ] GET /api/products -> 200 (matched: "id")
[ OK ] All smoke tests passed
```

## Test 3 — bad image must not change the active colour

```bash
IMAGE_TAG=definitely-not-a-real-tag PULL_IMAGES=true ./scripts/bg-deploy.sh definitely-not-a-real-tag
```

**Actual output (trimmed)**

```text
[INFO] Deploying new release : green (tag: definitely-not-a-real-tag)
[INFO] Pulling images for 'green' ...
Image ... shopnest-frontend:definitely-not-a-real-tag failed to resolve reference: not found
[FAIL] Failed to pull images for 'green'

active after:  server blue-frontend
[ OK ] All smoke tests passed
```

**Interpretation:** a failed deployment never changes the active upstream; the previous version keeps serving.

## Test 4 — failure-scenarios harness

```bash
./scripts/failure-scenarios.sh bad-image
./scripts/failure-scenarios.sh inactive-down
```

**Actual output**

```text
[ OK ] Active colour unchanged (blue); production traffic unaffected
[ OK ] Failure scenario 'bad-image' completed

[ OK ] Active colour 'blue' still serving while 'green' is down
[ OK ] Failure scenario 'inactive-down' completed
```