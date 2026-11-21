# Screenshots

The assignment requires screenshots of the GitHub Actions history (successful **and** failed runs) stored in the repository and referenced from the README.

No screenshots are committed yet because no GitHub Actions run exists until the workflows are pushed and executed. This file defines exactly what to capture so the repository can be completed without guesswork.

## Naming convention

```text
docs/screenshots/
├── 01-ci-successful-run.png
├── 02-ci-failed-test-run.png
├── 03-cd-staging-success.png
├── 04-cd-production-approval.png
├── 05-blue-green-switch.png
├── 06-automatic-rollback.png
└── 07-workflow-run-history.png
```

## Capture checklist

- [ ] **CI successful run** — Actions → CI → a green run on `main`. Capture the summary with all jobs green.
- [ ] **CI failed run** — push a branch with a deliberately failing test; capture the red run and the failing step.
- [ ] **CD staging** — capture the successful staging deployment job.
- [ ] **Production approval** — capture the "Waiting for approval" state of the `production` environment.
- [ ] **Blue-Green switch** — capture the deployment log showing `Switching gateway traffic: blue -> green`.
- [ ] **Automatic rollback** — capture a run where the health check failed and the log shows `rolling back to`.
- [ ] **Run history** — capture the Actions tab showing both successful and failed runs.

## Referencing from the README

Add a section like:

```markdown
## Screenshots

| Evidence | Image |
|---|---|
| Successful CI | ![CI success](docs/screenshots/01-ci-successful-run.png) |
| Failed CI | ![CI failure](docs/screenshots/02-ci-failed-test-run.png) |
```

## Tips

- Use GitHub's built-in screenshot tools or the browser devtools device toolbar.
- Keep images under ~1 MB; PNG is fine.
- Do not include secrets, tokens, or internal hostnames in screenshots.
- Do not delete workflow runs — the assignment requires the history to remain visible.