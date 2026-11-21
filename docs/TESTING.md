# Testing

## Test layers

| Layer | Tool | Location |
|---|---|---|
| Frontend unit/component | Vitest + Testing Library | `frontend/src/**/*.test.ts(x)` |
| Backend unit | xUnit | `backend/ShopNest.Api.Tests/ProductServiceTests.cs` |
| Backend integration | xUnit + `WebApplicationFactory` | `backend/ShopNest.Api.Tests/HealthEndpointTests.cs` |
| Container smoke | Bash + curl/wget | `scripts/smoke-test.sh` |
| Zero-downtime | Bash soak loop | `scripts/soak-test.sh` |
| Failure/rollback | Bash | `scripts/failure-scenarios.sh`, `scripts/rollback.sh` |
| Workflow syntax | actionlint | `.github/workflows/*.yml` |

## Running tests

### Frontend

```bash
cd frontend
npm ci
npm run lint
npm test
npm run build
```

On Windows, if the checkout path contains `&`, `npm` may mis-generate script shims. Use WSL or run the commands inside a Linux container:

```bash
docker build --target build -t shopnest-app-frontend-build -f frontend/Dockerfile frontend
docker run --rm shopnest-app-frontend-build sh -c "npm run lint && npm test"
```

### Backend

```bash
cd backend
dotnet restore ShopNest.sln
dotnet format ShopNest.sln --verify-no-changes
dotnet build ShopNest.sln -c Release
dotnet test ShopNest.sln -c Release
```

Or, without a local .NET SDK:

```bash
docker build --target build -t shopnest-build -f backend/Dockerfile .
docker run --rm shopnest-build dotnet test backend/ShopNest.sln -c Release
```

### Full stack

```bash
cp .env.example .env
docker compose up -d --build
docker compose ps
bash scripts/smoke-test.sh http://localhost:8080
```

## Test inventory

### Frontend

- `src/api/client.test.ts`
  - builds the correct URL and parses JSON;
  - rejects on a non-2xx response.
- `src/pages/ProductListPage.test.tsx`
  - shows a loading state;
  - renders products returned by the API;
  - provides navigation to the detail page.

### Backend

- `ProductServiceTests`
  - maps every entity field to the DTO;
  - maps an existing id;
  - returns `null` for a missing id.
- `HealthEndpointTests`
  - `GET /health` returns 200 without a database;
  - `GET /api/info` returns the API name and non-empty version/commit.

## Evidence

Actual results are recorded in [evidence/](evidence/):

- [build-and-test.md](evidence/build-and-test.md)
- [zero-downtime.md](evidence/zero-downtime.md)
- [rollback.md](evidence/rollback.md)

## CI behaviour

- A PR is blocked by branch protection unless **all** CI checks pass.
- The `docker` job runs only after both `frontend` and `backend` succeed, so an image is never published from a failing build.
- Test results (TRX) and coverage are uploaded as artifacts for review.