# Build and Test Evidence

**Environment**

- Docker Desktop 29.9.2 (WSL2 backend)
- .NET 10 SDK (`mcr.microsoft.com/dotnet/sdk:10.0`)
- Node 22 (`node:22-alpine`)
- `rhysd/actionlint:latest`

All commands were run on 2026-11-21.

## 1. Backend build

```bash
docker build --target build -t shopnest-build:dev -f backend/Dockerfile .
```

Result: **success** (`exit=0`).

## 2. Backend tests

```bash
docker run --rm shopnest-build:dev \
  dotnet test backend/ShopNest.sln -c Release --logger "console;verbosity=normal"
```

Result:

```text
Passed ShopNest.Api.Tests.ProductServiceTests.GetByIdAsync_ReturnsNullWhenProductIsMissing
Passed ShopNest.Api.Tests.ProductServiceTests.GetByIdAsync_ReturnsMappedDtoForExistingId
Passed ShopNest.Api.Tests.ProductServiceTests.GetAllAsync_MapsEveryEntityFieldToTheDto
Passed ShopNest.Api.Tests.HealthEndpointTests.Info_ReturnsApiNameAndDefaults
Passed ShopNest.Api.Tests.HealthEndpointTests.Health_ReturnsHealthyWithoutDatabase
Test Run Successful.
```

**Failed: 0, Passed: 5, Total: 5.**

## 3. Backend formatting / lint

```bash
docker run --rm shopnest-build:dev \
  dotnet format backend/ShopNest.sln --verify-no-changes --severity warn
```

Result: **exit 0, no output** (no formatting changes required).

## 4. Frontend lint, tests, build

```bash
docker build --target build -t shopnest-frontend-build:dev -f frontend/Dockerfile frontend
docker run --rm shopnest-frontend-build:dev sh -c "npm run lint && npm test"
```

Result:

```text
> shopnest-frontend@0.0.0 lint
> eslint .
(no output — 0 errors, 0 warnings)

> shopnest-frontend@0.0.0 test
> vitest run

 ✓ src/api/client.test.ts (3 tests) 34ms
 ✓ src/pages/ProductListPage.test.tsx (3 tests) 294ms

 Test Files  2 passed (2)
      Tests  6 passed (6)
```

Production build (from the image build stage):

```text
vite v6.4.6 building for production...
✓ 47 modules transformed.
dist/index.html                  0.47 kB
dist/assets/index-*.css  7.83 kB
dist/assets/index-*.js  270.39 kB
✓ built in 2.14s
```

## 5. Workflow lint

```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest
```

Result: **no issues** (`exit=0`).

## 6. Docker Compose build

```bash
docker compose build
```

Result:

```text
Image shopnest-backend:local  Built
Image shopnest-frontend:local Built
```

## 7. Docker Compose startup

```bash
docker compose up -d
docker compose ps --format "table {{.Service}}\t{{.Status}}"
```

Result:

```text
SERVICE          STATUS
blue-backend     Up (healthy)
blue-frontend    Up (healthy)
db               Up (healthy)
gateway          Up (healthy)
green-backend    Up (healthy)
green-frontend   Up (healthy)
```

## 8. Smoke test

```bash
./scripts/smoke-test.sh http://localhost:8080
```

Result:

```text
[ OK ] GET /healthz -> 200
[ OK ] GET /api/info -> 200 (matched: ShopNest API)
[ OK ] GET /api/products -> 200 (matched: "id")
[ OK ] GET /api/products/1 -> 200 (matched: "name")
[ OK ] GET / -> 200
[ OK ] GET /products/1 -> 200
[ OK ] GET /api/products/999999 -> 404
[ OK ] All smoke tests passed
```

## 9. Public API sample

```bash
curl -fsS http://localhost:8080/api/info
# {"name":"ShopNest API","version":"local","commit":"local"}

curl -fsS http://localhost:8080/api/products
# [{"id":1,"name":"Aurora Wireless Headphones","description":"...","price":129.99,
#   "imageUrl":"https://picsum.photos/seed/headphones/600/400", ...}, ...]
```