# Failure Scenarios and Debugging

This document records (a) **real failures encountered** while building and validating ShopNest, and (b) **deliberate, safe failure scenarios** that can be reproduced against staging or a local stack.

> Never run the deliberate destructive scenarios against production.

## Part 1 — Real failures found and fixed

### Failure 1: backend compile errors

**Command**

```bash
docker build --target build -f backend/Dockerfile .
```

**Error**

```text
Program.cs(7,18): error CS1061: 'IServiceCollection' does not contain a definition for 'AddOpenApi'
Program.cs(40,5): error CS1061: 'WebApplication' does not contain a definition for 'MapOpenApi'
HealthController.cs(24,29): error CS0117: 'StatusCodes' does not contain a definition for 'StatusServiceUnavailable'
```

**Root cause**

- The OpenAPI helper was not available in this project configuration, and the API is not required by the assignment.
- The correct constant is `StatusCodes.Status503ServiceUnavailable`.

**Fix**

- Removed `AddOpenApi()` / `MapOpenApi()`.
- Changed the status code constant.
- Commit: see the implementation commit (code review diff).

**Verification**

```bash
docker build --target build -f backend/Dockerfile .   # success
```

---

### Failure 2: test project compile error

**Command**

```bash
docker run --rm shopnest-build:dev dotnet test backend/ShopNest.sln -c Release
```

**Error**

```text
ProductServiceTests.cs(27,17): error CS0747: Invalid initializer member declarator
ProductServiceTests.cs(38,17): error CS0747: Invalid initializer member declarator
ProductServiceTests.cs(68,13): error CS0747: Invalid initializer member declarator
```

**Root cause**

The test used an object-initializer shorthand (`CreatedAt`) that was ambiguous with the target property of the same name.

**Fix**

Introduced a clearly named static field and explicit assignment:

```csharp
private static readonly DateTime SampleCreatedAt = new(2026, 1, 2, 3, 4, 5, 0, DateTimeKind.Utc);
...
CreatedAt = SampleCreatedAt
```

**Verification**

```text
Passed!  - Failed: 0, Passed: 5, Skipped: 0, Total: 5
```

---

### Failure 3: frontend container reported unhealthy

**Symptom**

```text
container shopnest-blue-frontend is unhealthy
wget: can't connect to remote host: Connection refused
```

**Diagnosis**

```bash
docker compose exec blue-frontend wget -qO- http://127.0.0.1/healthz   # ok
docker compose exec blue-frontend wget -qO- http://localhost/healthz   # refused
```

**Root cause**

Inside the container, `localhost` resolved to IPv6 `::1`, but the Nginx `listen 80;` directive binds IPv4 only.

**Fix**

Replaced `localhost` with `127.0.0.1` in:

- `docker-compose.yml` health checks (backend, frontend, gateway);
- `scripts/bg-deploy.sh` internal smoke tests.

**Verification**

```text
shopnest-blue-frontend  Up (healthy)
shopnest-green-frontend Up (healthy)
```

## Part 2 — Deliberate failure scenarios

All scenarios are implemented in `scripts/failure-scenarios.sh` and are safe:

### Scenario A — bad image tag

```bash
./scripts/failure-scenarios.sh bad-image
```

**Expected**: the new colour fails to pull/start, the script exits non-zero, and the **active colour does not change**.

**Actual**

```text
[FAIL] Failed to pull images for 'green'
[ OK ] Active colour unchanged (blue); production traffic unaffected
```

### Scenario B — post-switch health failure (automatic rollback)

```bash
SIMULATE_FAILURE=post PULL_IMAGES=false ./scripts/bg-deploy.sh local
```

**Expected**: traffic switches, the verification fails, and the script automatically switches back.

**Actual**

```text
[INFO] Switching gateway traffic: green -> blue
[WARN] SIMULATE_FAILURE=post -> failing post-switch verification; rolling back.
[ OK ] Automatic rollback to 'green' completed.
[FAIL] Simulated post-switch failure (rolled back to 'green')
```

### Scenario C — inactive colour down

```bash
./scripts/failure-scenarios.sh inactive-down
```

**Expected**: the active colour keeps serving; only the inactive colour is affected.

**Actual**

```text
[ OK ] Active colour 'blue' still serving while 'green' is down
```

### Scenario D — manual rollback

```bash
./scripts/failure-scenarios.sh rollback
```

**Expected**: traffic returns to the previous colour and the public smoke test passes.

**Actual**

```text
[ OK ] Rollback complete. Active colour: blue
[ OK ] All smoke tests passed
```

## Part 3 — Pipeline failure types to demonstrate in GitHub Actions

The assignment asks for three different kinds of pipeline failure. The following can be reproduced deliberately on a **branch** (not `main`):

| Type | How to reproduce | Expected error |
|---|---|---|
| **YAML / workflow syntax** | Introduce an invalid key or bad indentation in `.github/workflows/ci.yml` on a branch, or run `actionlint` locally. | `actionlint` / GitHub Actions "Invalid workflow file" |
| **Test failure** | Change an assertion in `frontend/src/api/client.test.ts` to expect the wrong URL. | `vitest` fails; CI job `Frontend (Node 22.x)` fails; `docker` job is skipped. |
| **Deployment / connection failure** | Set an incorrect `EC2_HOST` or remove the SSH key in the `staging` environment, then dispatch CD. | `appleboy/ssh-action` fails to connect; the deployment job fails; production is not reached. |

For each, capture:

1. the failed run URL and a screenshot;
2. the failing step log;
3. the root-cause analysis;
4. the fixing commit.

Place screenshots in `docs/screenshots/` using the naming convention in [screenshots/README.md](screenshots/README.md).