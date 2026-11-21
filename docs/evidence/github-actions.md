# GitHub Actions Evidence

**Repository:** https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment
**Date:** 2026-11-21
**Default branch:** `main`
**Latest commit:** `097b76f`

## Recent runs (current repository)

| Run | Workflow | Trigger | Commit | Conclusion | Notes |
|---|---|---|---|---|---|
| [44880971914](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880971914) | CD | workflow_run | `097b76f` | ✅ success | Staging 26s, production 26s; blue-green; production approved. |
| [44880858023](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880858023) | CI | push | `097b76f` | ✅ success | Frontend Node 20/22, Backend (.NET 10), Docker images pushed. |
| [44879363921](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44879363921) | CD | workflow_dispatch | `b4e8fef` | ✅ success | Staging 24s. |
| [44879070130](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44879070130) | CD | workflow_run | `b4e8fef` | ❌ failure | Staging failed because the EC2 repo could not fast-forward after a history rewrite; production succeeded. Fixed by resetting the EC2 repos and changing the CD to exact-commit checkout. |
| [44878895676](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44878895676) | CI | push | `b4e8fef` | ✅ success | All jobs green; images pushed. |

## Successful CI job results (run 44880858023)

| Job | Steps | Result |
|---|---|---|
| `Frontend (Node 20.x)` | `npm ci`, `npm run lint`, `npm test`, `npm run build` | ✅ passed |
| `Frontend (Node 22.x)` | `npm ci`, `npm run lint`, `npm test`, `npm run build` | ✅ passed |
| `Backend (.NET 10)` | restore, `dotnet format`, build, test, publish | ✅ Build succeeded (0 errors); 5 tests passed |
| `Build and publish container images` | download artifacts, build `Dockerfile.ci` for both tiers, push to GHCR | ✅ passed |

Relevant log excerpts:

```text
Backend (.NET 10)  Build   Build succeeded.
Backend (.NET 10)  Build   0 Error(s)
Backend (.NET 10)  Test    Passed!  - Failed: 0, Passed: 5, Skipped: 0, Total: 5
Frontend (Node 22.x) Test  Test Files  2 passed (2)
Frontend (Node 20.x) Test  Test Files  2 passed (2)
```

## GHCR packages

- `ghcr.io/arifuzzaman-hredoy/shopnest-app-backend`
- `ghcr.io/arifuzzaman-hredoy/shopnest-app-frontend`

Images are tagged `sha-<commit>` and `latest` (on `main`).

## CD behaviour

`cd.yml` resolves the exact CI commit and checks it out on the EC2 host before deploying:

```bash
git checkout -- nginx/gateway/default.conf 2>/dev/null || true
git fetch origin
git checkout --detach "$FULL_SHA"
```

This guarantees that the **image tag**, **application source**, and **APP_VERSION** all refer to the same commit. It replaces the earlier `git pull --ff-only origin main`, which could deploy a newer commit than the image.

## CD failure and fix (run 44879070130)

- **Failure:** `fatal: Not possible to fast-forward, aborting.` in the staging deploy.
- **Root cause:** the EC2 repository still had the pre-rewrite commit; `git pull --ff-only` could not fast-forward.
- **Fix:** reset the EC2 repos to `origin/main` and changed `cd.yml` to check out the exact commit with `git checkout --detach "$FULL_SHA"`.
15. **Verification:** run [44879363921](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44879363921) (staging) and [44880971914](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880971914) (staging + production) passed.

## Screenshots to capture

| File | Run |
|---|---|
| `01-ci-successful-run.png` | 44880858023 |
| `02-ci-failed-run.png` | a deliberate failure run (see `docs/FAILURE_SCENARIOS.md`) |
| `03-cd-staging-success.png` | 44880971914 |
| `04-cd-production-approval.png` | 44880971914 |
15. `05-cd-production-success.png` | 44880971914 |
15. `06-blue-green-switch.png` | 44880971914 |
15. `07-automatic-rollback.png` | a deliberate failure/rollback run |
15. `08-manual-rollback.png` | a manual rollback run |
15. `09-workflow-run-history.png` | the Actions tab |

No screenshots are committed yet; capturing them is a manual step. This file records the exact runs to capture.