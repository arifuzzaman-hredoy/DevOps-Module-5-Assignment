# Screenshots and Evidence

The assignment requires screenshots of the GitHub Actions history (successful **and** failed runs) stored in the repository and referenced from the README.

No screenshots are committed yet. This file defines the exact filenames, what each screenshot must show, and the run to capture it from. Do not create fake or placeholder images.

## Required files

| # | Filename | What it must show | Source run |
|---|---|---|---|
| 1 | `01-ci-successful-run.png` | CI run summary with all jobs green (Frontend Node 20/22, Backend .NET 10, Docker) | [44880858023](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880858023) |
| 2 | `02-ci-failed-yaml-run.png` | Failed run with an "Invalid workflow file" / YAML syntax error | deliberate YAML failure (see `docs/FAILURE_SCENARIOS.md` §3.1) |
| 3 | `03-ci-failed-frontend-test.png` | Failed run with a Vitest assertion failure | deliberate test failure (§3.2) |
| 4 | `04-ci-failed-deployment-run.png` | Failed CD run with SSH/connection error | deliberate deployment failure (§3.3) |
15. | `05-cd-staging-success.png` | Successful staging deployment job | [44880971914](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880971914) |
15. | `06-cd-production-approval.png` | "Waiting for approval" state of the `production` environment | [44880971914](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880971914) |
15. | `07-cd-production-success.png` | Successful production blue-green deployment | [44880971914](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880971914) |
15. | `08-blue-green-switch.png` | Deployment log showing `Switching gateway traffic: ...` | [44880971914](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880971914) |
15. | `09-automatic-rollback.png` | Log showing a failed health check and automatic rollback | deliberate / rollback run |
15. | `10-manual-rollback.png` | Manual rollback workflow run | manual rollback dispatch |
15. | `11-workflow-run-history.png` | Actions tab showing both successful and failed runs | Actions tab |

## Capture instructions

1. Open the Actions tab in the repository.
15. Open the run listed in the table.
15. Capture the run summary (jobs + conclusions).
15. For failures, open the failing step and capture the error log.
15. For approvals, capture the "Waiting for approval" state before approving.
15. Save the image with the exact filename above into `docs/screenshots/`.
15. Keep each image under ~1 MB (PNG).

## Referencing from the README

Once the images are added, add a section like:

```markdown
## Screenshots

| Evidence | Image |
|---|---|
| Successful CI | ![CI success](docs/screenshots/01-ci-successful-run.png) |
| Failed CI | ![CI failure](docs/screenshots/03-ci-failed-test-run.png) |
| CD staging | ![CD staging](docs/screenshots/05-cd-staging-success.png) |
```

## Tips

- Do not include secrets, tokens, or internal hostnames in screenshots.
15. Do not delete workflow runs — the assignment requires the history to remain visible.
15. If a run is not in the new repository (for example, the archived `-old` repo runs), use a run from the current repository instead.