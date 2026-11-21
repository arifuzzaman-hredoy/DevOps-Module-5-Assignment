# Screenshots and Evidence

All 11 required screenshots are committed in this directory, plus three additional evidence images (GitHub Copilot workflow interaction, live storefront, and live product detail). The assignment requires screenshots of GitHub Actions history (successful **and** failed runs) stored in the repository and referenced from the README.

## Files

| # | Filename | What it shows | Source run |
|---|---|---|---|
| 1 | `01-ci-successful-run.png` | CI run summary with all jobs green (Frontend Node 20/22, Backend .NET 10, Docker) | [44880858023](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44880858023) |
| 2 | `02-ci-failed-yaml-run.png` | Failed run with an "Invalid workflow file" / YAML syntax error | [44884747114](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44884747114) |
| 3 | `03-ci-failed-frontend-test.png` | Failed run with a Vitest assertion failure | [44887207111](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44887207111) |
| 4 | `04-ci-failed-deployment-run.png` | Failed CD run with an SSH/connection error (temporary demo) | [44889677627](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44889677627) |
| 5 | `05-cd-staging-success.png` | Successful staging deployment job | [44883093333](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44883093333) |
| 6 | `06-cd-production-approval.png` | "Waiting for approval" state of the `production` environment | [44890142542](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44890142542) |
| 7 | `07-cd-production-success.png` | Successful production blue-green deployment | [44883093333](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44883093333) |
| 8 | `08-blue-green-switch.png` | Deployment log showing `Switching gateway traffic: ...` | [44883093333](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44883093333) |
| 9 | `09-automatic-rollback.png` | Staging automatic rollback demo | [automatic-rollback-staging.md](../evidence/automatic-rollback-staging.md) |
| 10 | `10-manual-rollback.png` | Manual rollback workflow run | [44892753441](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44892753441) |
| 11 | `11-workflow-run-history.png` | Actions tab showing both successful and failed runs | [Actions tab](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions) |

## Additional evidence

| Filename | What it shows | Notes |
|---|---|---|
| `copilot-ci-workflow-generation.png` | User-captured GitHub Copilot Chat prompt and workflow response | Genuine Copilot Chat interaction evidence. The original workflow implementation remains accurately attributed to Kilo; see [COPILOT.md](../COPILOT.md). |
| `live-product-detail.png` | Live ShopNest product detail page | Captured from https://shopnest.oxytumzone.com |
| `live-storefront.png` | Live ShopNest storefront | Captured from https://shopnest.oxytumzone.com |

## Notes

- Screenshots 2, 3, and 4 are from **deliberately injected** failures created for Part H.
- Screenshot 3 is the deliberate frontend test failure; the fix was verified by successful run [44907810414](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment/actions/runs/44907810414).
- Screenshot 4 is from the temporary `CD Failure Demo` workflow, which simulated a staging SSH connection failure without touching production.
- Screenshot 9 is from the staging automatic-rollback demo; the exact terminal output is preserved in [automatic-rollback-staging.md](../evidence/automatic-rollback-staging.md).
- Do not include secrets, tokens, or internal hostnames in screenshots.
- Do not delete workflow runs — the assignment requires the history to remain visible.
- PR #2 and PR #3 are open evidence PRs; do not merge them.
