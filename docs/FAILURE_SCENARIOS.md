# Failure Scenarios and Debugging

This document records (a) **real failures encountered** while building and validating ShopNest, (b) **deliberate local failure scenarios**, and (c) **three GitHub Actions pipeline failure types** with step-by-step reproduction instructions for the assignment.

> Never run the deliberate destructive scenarios against production.

---

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

---

### Failure 4: CI failed with `Copy-Item: command not found` (earlier iteration)

**Workflow run:** [44860561407](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment-old/actions/runs/44860561407) (commit `008b0d6`, archived repository)

**Failing step:** `Bundle migrations into publish output`

```text
/home/runner/work/_temp/445f51f8-...sh: line 1: Copy-Item: command not found
##[error]Process completed with exit code 127.
```

**Root cause:** GitHub-hosted runners use **Bash** as the default shell for `run` steps. `Copy-Item` is a **PowerShell** cmdlet and does not exist in Bash.

**Fix:** replaced it with a POSIX `cp`:

```yaml
- name: Bundle migrations into publish output
  run: cp -r ../database/migrations publish/migrations
```

**Fix commit:** `cbee38b` (archived history).

**Verification:** the next CI run passed; all jobs green and both images pushed to GHCR.

---

### Failure 5: CD staging failed with `Not possible to fast-forward` (current repository)

**Workflow run:** [44879070130](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44879070130)

**Failing step:** `Deploy and verify staging`

```text
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:     git merge --no-ff
hint: or:
hint:     git rebase
fatal: Not possible to fast-forward, aborting.
##[error]Process completed with exit code 1.
```

**Root cause:** the EC2 repository was still on a pre-rewrite commit, and the CD used `git pull --ff-only origin main`. After a history rewrite, the local and remote histories had diverged, so a fast-forward was impossible.

**Fix:**

1. Reset the EC2 repositories to the new remote history:
   ```bash
   cd /opt/shopnest
   git fetch origin
   git reset --hard origin/main
   ```
15. Changed `cd.yml` to check out the **exact commit** associated with the image tag instead of pulling the branch:
   ```bash
   git checkout -- nginx/gateway/default.conf 2>/dev/null || true
   git fetch origin
   git checkout --detach "$FULL_SHA"
   ```
15. **Verification:** runs [44879363921](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44879363921) (staging) and [44880971914](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880971914) (staging + production) passed.

---

### Failure 6 (expected, configuration gap): CD without EC2 secrets (earlier iteration)

**Workflow run:** [44860883080](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment-old/actions/runs/44860883080) (archived repository)

```text
Error: missing server host
##[error]Process completed with exit code 1
```

**Root cause:** `EC2_HOST`, `EC2_USER`, and `EC2_SSH_KEY` were not configured.

**Resolution:** the secrets/variables are now configured; the same workflow deploys successfully (run `44880971914`).

---

## Part 2 — Deliberate local failure scenarios

All scenarios are implemented in `scripts/failure-scenarios.sh` and are safe:

### Scenario A — bad image tag

```bash
./scripts/failure-scenarios.sh bad-image
```

**Expected:** the new colour fails to pull/start, the script exits non-zero, and the **active colour does not change**.

**Actual**

```text
[FAIL] Failed to pull images for 'green'
[ OK ] Active colour unchanged (blue); production traffic unaffected
```

### Scenario B — post-switch health failure (automatic rollback)

```bash
SIMULATE_FAILURE=post PULL_IMAGES=false ./scripts/bg-deploy.sh local
```

**Expected:** traffic switches, the verification fails, and the script automatically switches back.

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

**Expected:** the active colour keeps serving; only the inactive colour is affected.

**Actual**

```text
[ OK ] Active colour 'blue' still serving while 'green' is down
```

### Scenario D — manual rollback

```bash
./scripts/failure-scenarios.sh rollback
```

**Expected:** traffic returns to the previous colour and the public smoke test passes.

**Actual**

```text
[ OK ] Rollback complete. Active colour: blue
[ OK ] All smoke tests passed
```

---

## Part 3 — Three GitHub Actions pipeline failure types

The assignment requires **three different kinds of pipeline failure**. Reproduce each on a **branch** (not `main`), capture the failed run, then fix it and capture the green run.

### 3.1 YAML syntax / configuration failure

**What to change**

Create a branch and introduce an invalid YAML line in `.github/workflows/ci.yml`, for example:

```yaml
      - name: Lint
        run: npm run lint
      invalid_key_without_colon
```

**Expected failure**

GitHub Actions reports:

```text
Invalid workflow file: .github/workflows/ci.yml
You have an error in your yaml syntax on line ...
```

The workflow does not start; no jobs run.

**Root cause**

The YAML parser rejects the invalid key/indentation. `actionlint` reports the same error locally.

**Copilot troubleshooting**

Ask Copilot Chat:

```text
This GitHub Actions workflow fails with "Invalid workflow file ... yaml syntax". Show me the exact line and the corrected YAML.
```

**Fix**

Correct the YAML, commit to the branch, and push. The CI run turns green.

**Screenshot file:** `docs/screenshots/02-ci-failed-yaml-run.png`

**Record:** failed run URL + fixing commit hash.

---

### 3.2 Test failure

**What to change**

Create a branch and change an assertion in `frontend/src/api/client.test.ts`:

```ts
expect(fetchMock).toHaveBeenCalledWith('/api/wrong');
```

**Expected failure**

The `Test` step fails in the `Frontend (Node 20.x)` and `Frontend (Node 22.x)` jobs:

```text
AssertionError: expected "fetch" to be called with arguments: [ '/api/wrong' ]
Received: [ '/api/products' ]
```

The `docker` job is skipped because it `needs` the frontend job.

**Root cause**

The assertion no longer matches the client implementation.

**Copilot troubleshooting**

Ask Copilot Chat:

```text
This Vitest test fails with an assertion error. Compare the test expectation with the fetch URL in src/api/client.ts and explain the mismatch.
```

**Fix**

Restore the correct assertion, commit, and push. The CI turns green.

**Screenshot file:** `docs/screenshots/03-ci-failed-test-run.png`

**Record:** failed run URL + fixing commit hash.

---

### 3.3 Deployment / connection failure

**What to change**

In the GitHub `staging` environment, temporarily set `EC2_HOST` to an invalid value (for example `staging.invalid.example.com`), then run the **CD** workflow manually with `environment = staging`, `action = deploy`.

**Expected failure**

The `Deploy and verify staging` step fails:

```text
Error: missing server host
```
or
```text
ssh: connect to host staging.invalid.example.com port 22: Connection timed out
```

The production job is not reached.

**Root cause**

The SSH action cannot resolve/connect to the target host. This is a configuration/connectivity failure, not an application failure.

**Copilot troubleshooting**

Ask Copilot Chat:

```text
This appleboy/ssh-action step fails with "missing server host" / "Connection timed out". Check the action inputs and the environment secrets it expects.
```

**Fix**

Restore the correct `EC2_HOST` secret, then re-run the CD workflow. The deployment succeeds.

**Screenshot file:** `docs/screenshots/04-ci-failed-deployment-run.png`

**Record:** failed run URL + fixing commit or secret update.

> A real deployment failure is already recorded in this repository: run [44879070130](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44879070130) (`Not possible to fast-forward`). It can be used as additional evidence.

---

## Part 4 — Evidence capture checklist

| Evidence | Filename | Run |
|---|---|---|
| CI successful run | `01-ci-successful-run.png` | 44880858023 |
| CI YAML failure | `02-ci-failed-yaml-run.png` | deliberate |
| CI test failure | `03-ci-failed-test-run.png` | deliberate |
15. CI deployment failure | `04-ci-failed-deployment-run.png` | deliberate |
15. CD staging success | `05-cd-staging-success.png` | 44880971914 |
15. Production approval | `06-cd-production-approval.png` | 44880971914 |
15. Production success | `07-cd-production-success.png` | 44880971914 |
15. Blue-green switch | `08-blue-green-switch.png` | 44880971914 |
15. Automatic rollback | `09-automatic-rollback.png` | deliberate / rollback run |
15. Manual rollback | `10-manual-rollback.png` | manual rollback run |
15. Workflow run history | `11-workflow-run-history.png` | Actions tab |

For each deliberate failure, record:

1. the failed run URL and a screenshot;
15. the failing step log;
15. the root-cause analysis;
15. the fixing commit.

See [screenshots/README.md](screenshots/README.md) for the naming convention and capture instructions.