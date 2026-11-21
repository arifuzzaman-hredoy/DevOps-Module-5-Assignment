# Copilot-Assisted Development

ShopNest was built with AI assistance. This document records the prompts used to generate the workflow files, the generated output, and the corrections made during review.

> **Tool attribution:** The initial CI/CD workflows and deployment scripts were generated with **Kilo**, an AI coding assistant, and then reviewed and corrected. GitHub Copilot Chat was also used for a separate workflow-generation/refinement interaction. The genuine user-captured interaction is included as [docs/screenshots/copilot-ci-workflow-generation.png](screenshots/copilot-ci-workflow-generation.png). This evidence demonstrates Copilot Chat usage; it does not change the attribution of the original workflow implementation to Kilo.

> The prompts below are reproducible prompts. They describe the workflow-generation tasks and can be reused in GitHub Copilot Chat. Do not interpret them as proof that the original workflow files were authored by Copilot.

## Prompt 1 — CI skeleton

```text
Create a GitHub Actions CI workflow for a monorepo with a React + Vite + TypeScript frontend
in ./frontend and a .NET 10 ASP.NET Core Web API in ./backend.

Requirements:
- Trigger on push and pull_request to main.
- Frontend job: matrix over Node 20.x and 22.x, run npm ci, npm run lint, npm test, npm run build.
- Backend job: setup-dotnet 10.0.x, restore, build, test.
- Jobs must run in parallel.
- Upload build artifacts from both jobs.
```

### Generated output (summary)

A single workflow with two jobs, each doing checkout + setup + build steps. It did not include linting for the backend, did not pass artifacts anywhere, and used a hard-coded `dotnet-version: 8.0.x`.

### Changes made

| Change | Reason |
|---|---|
| Pinned `DOTNET_VERSION: "10.0.x"` | The assignment mandates .NET 10. |
| Added `npm run lint` and `npm test -- --run` | The assignment requires linting and tests for both tiers. |
| Added `dotnet format --verify-no-changes` | .NET has no separate linter; `dotnet format` is the standard check. |
| Added artifact upload/download | The assignment requires build outputs to be passed between jobs. |

## Prompt 2 — Container job

```text
Add a third job named "docker" that needs both the frontend and backend jobs.
It should download their artifacts, build Docker images using Dockerfile.ci files,
and push to GitHub Container Registry. Tag images with the commit SHA and latest.
Only push on the main branch; on pull requests, build without pushing.
```

### Generated output (summary)

Used `docker/build-push-action@v5`, pushed on every event, and tagged only `latest`.

### Changes made

| Change | Reason |
|---|---|
| Upgraded to `docker/build-push-action@v6` | Current stable major. |
| `push: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}` | PRs must not publish images. |
| Added `sha-<commit>` tag via `docker/metadata-action` | Immutable tags are required for rollback and traceability. |
| Added `cache-from`/`cache-to: type=gha` | Faster repeat builds. |
| Added `permissions: packages: write` | Required to push to GHCR. |

## Prompt 3 — CD workflow

```text
Create a CD workflow that runs after CI completes on main.
- A prepare job resolves the triggering commit SHA.
- A staging job deploys over SSH with appleboy/ssh-action and runs ./scripts/bg-deploy.sh.
- A production job uses a GitHub Environment named "production" so it requires manual approval.
- Add a manual rollback path using workflow_dispatch with an image tag input.
- Pass secrets to the SSH action through its envs input, not by interpolating them into the script.
```

### Generated output (summary)

A `cd.yml` with staging and production jobs. It interpolated `${{ secrets.EC2_SSH_KEY }}` directly into the script and used `needs: [prepare, deploy-staging]` for production.

### Changes made

| Change | Reason |
|---|---|
| Pass values via `envs:` and read them as `$VARIABLES` inside the script | Avoids putting secrets into the remote script text and shell history. |
| Changed production `needs` to `[prepare]` | A manual production dispatch would otherwise be skipped because the staging job is skipped. |
| Added `concurrency` and `workflow_run.conclusion` checks | Prevents deploying a failed CI run and overlapping deploys. |
| Added `environment: production` + documentation for required reviewers | Satisfies the manual-approval requirement. |
| Added `manual-rollback` job with `workflow_dispatch` inputs | Satisfies the manual rollback requirement. |

## Prompt 4 — Blue-Green script

```text
Write a bash script that performs a blue-green deployment with docker compose.
It must start the inactive colour, wait for Docker health checks, run smoke tests
through the new colour, switch an Nginx upstream, reload Nginx, run a public health
check, and automatically switch back on failure. Also write a rollback script and a
soak test that sends requests continuously while the switch happens.
```

### Generated output (summary)

A good first draft, but it used `localhost` for health checks and did not load `.env`.

### Changes made

| Change | Reason |
|---|---|
| Replaced `localhost` with `127.0.0.1` in container health checks | Inside the container `localhost` resolved to IPv6 `::1` while Nginx listens on IPv4, causing false `unhealthy` results. |
| Load `.env` without overriding CI-provided variables | The scripts need `GATEWAY_PORT`, `REGISTRY`, etc. on a manual run. |
| Fall back to local image tags when `PULL_IMAGES=false` | Makes local testing possible without GHCR. |
| Use `nginx -t` before `nginx -s reload` | Prevents applying an invalid configuration. |
| Run the public health check *after* the switch and roll back on failure | This is the automatic rollback requirement. |

## Prompt 5 — Tests

```text
Write Vitest tests for the API client and the product list page, and xUnit tests for the
product service and health endpoints. Mock the network layer; do not require a live database.
```

### Changes made

- Rewrote the object initializer in `ProductServiceTests` to avoid `CS0747` (`CreatedAt = SampleCreatedAt`).
- Overrode `Migrations:Path` in the test factory so the health tests do not attempt a database connection.

## Validation

The generated and corrected workflows were checked with:

```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest
# -> no issues
```

The full application was then built and exercised locally; see [evidence/](evidence/).

## Part H evidence summary

- Initial workflow implementation: generated with Kilo, then reviewed and corrected.
- GitHub Copilot Chat: a separate genuine interaction is captured in [copilot-ci-workflow-generation.png](screenshots/copilot-ci-workflow-generation.png).
- Failure diagnosis, fixes, and CI run evidence: documented in [FAILURE_SCENARIOS.md](FAILURE_SCENARIOS.md) and the screenshots directory.
- Attribution remains explicit: the Copilot screenshot proves the documented Copilot Chat interaction, not that Kilo-generated original files were authored by Copilot.
