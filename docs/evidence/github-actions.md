# GitHub Actions Evidence

**Repository:** https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment
**Date:** 2026-11-21

## Workflow runs

| Run ID | Workflow | Trigger | Commit | Conclusion | Notes |
|---|---|---|---|---|---|
| [44860561407](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44860561407) | CI | push | `008b0d6` | ❌ failure | Backend step `Bundle migrations` used the PowerShell cmdlet `Copy-Item` on a Bash runner (`Copy-Item: command not found`). |
| [44860640934](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44860640934) | CD | workflow_run | `008b0d6` | ✅ success (jobs skipped) | Correctly detected the failed CI run and skipped staging/production. |
| [44860712719](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44860712719) | CI | push | `cbee38b` | ✅ success | All jobs green; images pushed to GHCR. |
| [44860883080](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44860883080) | CD | workflow_run | `cbee38b` | ❌ failure | `missing server host` — the `EC2_HOST` secret is not configured yet. Expected until AWS credentials are added. |

## Successful CI job results (run 44860712719)

| Job | Steps | Result |
|---|---|---|
| `Frontend (Node 20.x)` | `npm ci`, `npm run lint`, `npm test`, `npm run build` | ✅ passed |
| `Frontend (Node 22.x)` | `npm ci`, `npm run lint`, `npm test`, `npm run build` | ✅ passed |
| `Backend (.NET 10)` | restore, `dotnet format`, build, test, publish | ✅ Build succeeded (0 errors); **5 tests passed** |
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

## Why the CD run fails today

`cd.yml` requires these secrets/variables to reach an EC2 host:

- `EC2_HOST`, `EC2_USER`, `EC2_SSH_KEY` (per environment)
- `APP_DIR`, `STAGING_URL`, `PRODUCTION_URL`

Without them, `appleboy/ssh-action` exits with `missing server host`. This is the correct, safe behaviour: no deployment is attempted without a target. Once the secrets are configured, the same workflow will deploy over SSH. See [DEPLOYMENT.md](DEPLOYMENT.md).

## Screenshots

Capture the runs above into `docs/screenshots/` following [screenshots/README.md](screenshots/README.md). In particular:

- `01-ci-successful-run.png` ← run 44860712719
- `02-ci-failed-test-run.png` ← run 44860561407
- `03-cd-staging-success.png` ← after EC2 secrets are configured
- `07-workflow-run-history.png` ← the Actions tab showing both successes and failures