# Failure Scenarios and Debugging

This document records (a) **real failures encountered** while building and validating ShopNest, (b) **deliberate local failure scenarios**, and (c) **three GitHub Actions pipeline failure types** with step-by-step reproduction instructions for the assignment.

> Never run the deliberate destructive scenarios against production.

> **Classification:** Failures 1–6 are naturally encountered during development/operation. Failures 7–9 are deliberately injected for Part H evidence.

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

### Failure 5: CD staging failed with `Not possible to fast-forward` (current repository, naturally encountered)

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
- Changed `cd.yml` to check out the **exact commit** associated with the image tag instead of pulling the branch:
   ```bash
   git checkout -- nginx/gateway/default.conf 2>/dev/null || true
   git fetch origin
   git checkout --detach "$FULL_SHA"
   ```
- **Verification:** runs [44879363921](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44879363921) (staging) and [44880971914](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880971914) (staging + production) passed.

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

### Failure 7: Deliberately injected YAML syntax failure

**Branch:** `evidence/yaml-syntax-failure`
**Commits:** `ab6b016` (introduce), `4cc27b7` (fix)
**Runs:** [44884747114](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44884747114) (failure), [44884934412](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44884934412) (success)
**Error:** `Invalid workflow file: .github/workflows/ci.yml ... yaml syntax`
**Root cause:** invalid YAML key/indentation.
**Fix:** corrected the YAML.
**Evidence:** `docs/screenshots/02-ci-failed-yaml-run.png`

---

### Failure 8: Deliberately injected frontend test failure

**Branch:** `evidence/test-failure`
**Failing commit:** `c4d77e6`
**Failing runs:** [44887207111](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44887207111), [44887005810](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44887005810)
**Error:** `AssertionError: expected '/api/products' to be '/api/products-wrong'`
**Root cause:** the assertion in `frontend/src/api/client.test.ts` line 41 was intentionally changed.
**Fixing commit:** `76c4d15201417fd469cb627edca46540d2425e8a`
**Successful run:** [44907810414](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44907810414)
**Fix:** the incorrect assertion in `frontend/src/api/client.test.ts` line 41 was restored to `expect(url).toBe('/api/products')`.
**Verification:** frontend lint passed; all 6 frontend tests passed; `tsc -b` and `vite build` passed; GitHub Actions CI run [44907810414](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44907810414) passed (Backend .NET 10, Frontend Node 20.x, Frontend Node 22.x, Docker images).
**Evidence:** `docs/screenshots/03-ci-failed-frontend-test.png` (failure screenshot; the fix is verified by the successful run above)

---

### Failure 9: Deliberately injected deployment/SSH failure demo

**Temporary workflow:** `cd-failure-demo.yml` on branch `evidence/deployment-failure-demo` (deleted after the run)
**Run:** [44889677627](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44889677627)
**Failed step:** `Simulate staging SSH failure` → `Attempt SSH to an invalid staging host`

#### Observed errors

```text
ssh.ParsePrivateKey: ssh: no key found
dial tcp: lookup staging.invalid.example.com on 127.0.0.53:53: no such host
##[error]Process completed with exit code 1.
```

#### Root cause

Two separate issues:

1. **No usable SSH private-key data was provided.** The demo workflow passed an intentionally invalid placeholder key, so `appleboy/ssh-action` could not parse a private key (`ssh.ParsePrivateKey: ssh: no key found`).
2. **The configured staging hostname was an intentionally invalid placeholder.** `staging.invalid.example.com` does not resolve, so the SSH client could not connect (`no such host`).

These are independent: even with a valid key, the invalid hostname would fail; even with a valid hostname, the invalid key would fail.

#### Copilot troubleshooting

Copilot's explanation and remediation recommendations:

- Use **GitHub Actions Secrets** and protected **Environments** for sensitive values, with separate credentials for staging and production.
- Verify the correct staging hostname and SSH port.
- Use a verified `known_hosts` file and enable **strict host-key checking**.
- Use a least-privilege deployment account and key.
- Validate network reachability and SSH connectivity with a non-mutating check before deploying.

> Copilot provided a remediation plan only. The plan was **not** implemented in this repository; this was a temporary failure-demo workflow.

**Supplementary remediation notes (not Copilot's actual response):**

- `appleboy/ssh-action` with `host`, `username`, and `key: ${{ secrets.EC2_SSH_KEY }}` (or an environment-scoped secret).
- Restrict SSH ingress to GitHub Actions IP ranges, or use a self-hosted runner.
- A non-mutating pre-check such as `nc -zv <host> 22` or `ssh -o ConnectTimeout=5 <user>@<host> true`.

#### Evidence

- Actions run: [44889677627](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44889677627)
- Screenshot: `docs/screenshots/04-ci-failed-deployment-run.png`
- Copilot screenshot: `docs/screenshots/05-copilot-deployment-failure-troubleshooting.png`

#### Important limitation

- This was a **temporary failure-demo workflow** (`cd-failure-demo.yml`) on branch `evidence/deployment-failure-demo`.
- The temporary workflow was removed after the run; it is not part of the repository.
- No production or staging service was affected.
- No actual deployment fix commit or successful rerun exists for this temporary demo.
- Copilot provided a remediation plan; **do not claim that the plan was implemented**.

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


## Part 3 — GitHub Actions pipeline failure evidence

| Type | Injection | Commit / run | Result |
|---|---|---|---|
| YAML syntax | Deliberate | `ab6b016` / [44884747114](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44884747114) | Failed with invalid YAML; fixed in `4cc27b7`; [44884934412](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44884934412) passed |
| Frontend test | Deliberate | `c4d77e6` / [44887207111](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44887207111) (failed); fixed in `76c4d15` / [44907810414](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44907810414) (passed) | Failed as expected, then fixed and CI passed |
| Deployment/SSH connection | Deliberate (temporary demo) | [44889677627](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44889677627) | Failed with `no such host`; no services touched |
| Deployment fast-forward | Naturally encountered | [44879070130](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44879070130) | Failed with `Not possible to fast-forward`; fixed by exact-commit checkout |

> The `44879070130` failure was **not** deliberately injected. It was a real deployment failure caused by `git pull --ff-only` after the local and remote Git histories diverged. The `44889677627` failure was a deliberate temporary demo that simulated a staging SSH connection failure without touching production or staging services.

## Part 4 — Evidence capture checklist

| Evidence | Filename | Run |
|---|---|---|
| CI successful run | `01-ci-successful-run.png` | 44880858023 |
| CI YAML failure | `02-ci-failed-yaml-run.png` | 44884747114 |
| CI test failure | `03-ci-failed-frontend-test.png` | 44887207111 |
| CI deployment failure | `04-ci-failed-deployment-run.png` | 44889677627 |
| CD staging success | `05-cd-staging-success.png` | 44883093333 |
| Production approval | `06-cd-production-approval.png` | 44890142542 |
| Production success | `07-cd-production-success.png` | 44883093333 |
| Blue-green switch | `08-blue-green-switch.png` | 44883093333 |
| Automatic rollback | `09-automatic-rollback.png` | staging demo |
| Manual rollback | `10-manual-rollback.png` | 44892753441 |
| Workflow run history | `11-workflow-run-history.png` | Actions tab |

All 11 screenshots are committed in `docs/screenshots/`. See [screenshots/README.md](screenshots/README.md).
