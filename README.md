# ShopNest

A production-oriented three-tier e-commerce application demonstrating automated CI/CD, containerization, and Blue-Green deployment.

## Project Overview

ShopNest is a DevOps-focused project designed to demonstrate how a modern three-tier web application can be developed, tested, containerized, and deployed using automated CI/CD pipelines.

The project focuses on practical DevOps engineering concepts, including:

- Three-tier application architecture
- Automated Continuous Integration
- Automated Continuous Deployment
- Docker containerization
- Docker Compose orchestration
- Nginx reverse proxy
- AWS EC2 deployment
- Blue-Green deployment
- Application health checks
- Automated and manual rollback

## Technology Stack

| Component | Technology |
|---|---|
| Frontend | React + TypeScript |
| Frontend Runtime | Node.js |
| Package Manager | npm |
| Build Tool | Vite |
| Backend | C# + ASP.NET Core Web API |
| Backend Framework | .NET 10 LTS |
| Database | PostgreSQL |
| Containerization | Docker |
| Container Orchestration | Docker Compose |
| Reverse Proxy | Nginx |
| CI/CD | GitHub Actions |
| Cloud Infrastructure | AWS EC2 |
| Deployment Strategy | Blue-Green |
| Version Control | Git + GitHub |

## System Architecture

ShopNest follows a three-tier architecture.

```text
                 +----------------------+
                 |       Browser        |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 |        Nginx         |
                 |    Reverse Proxy     |
                 +----------+-----------+
                            |
                 +----------+-----------+
                 |                      |
                 v                      v
       +----------------+    +----------------------+
       | React Frontend |    | ASP.NET Core Web API |
       |  TypeScript    |    |       Backend        |
       +----------------+    +----------+-----------+
                                        |
                                        v
                              +----------------------+
                              |     PostgreSQL       |
                              |       Database       |
                              +----------------------+
```

## Repository Structure

```text
ShopNest/
├── frontend/
│   ├── public/
│   └── src/
├── backend/
├── database/
│   └── migrations/
├── nginx/
├── docker/
├── .github/
│   └── workflows/
├── docs/
├── .gitignore
├── LICENSE
└── README.md
```

## CI/CD Overview

GitHub Actions will be used to automate the Continuous Integration and Continuous Deployment (CI/CD) processes.

The planned CI/CD pipeline includes:

1. Source code validation and quality checks.
2. Frontend dependency installation, testing, and build.
3. Backend dependency restoration, testing, and build.
4. Build artifact generation and storage.
5. Automated staging deployment.
6. Manual approval before production deployment.
7. Blue-Green production deployment.
8. Post-deployment health checks.
9. Automated rollback when deployment verification fails.

CI and CD workflows will be maintained separately to improve pipeline organization and maintainability.

## Deployment Architecture

The application is planned to be deployed on AWS EC2 using Docker and Docker Compose.

The deployment architecture will include:

- **AWS EC2:** Hosts the application environment.
- **Docker:** Containerizes frontend and backend services.
- **Docker Compose:** Manages multi-container application services.
- **Nginx:** Acts as the reverse proxy and public entry point.
- **PostgreSQL:** Stores application data and remains accessible only through the private application network.
- **GitHub Actions:** Automates build, testing, and deployment workflows.

Blue-Green deployment will be implemented to minimize application downtime during production releases.

## Project Status

**Current Status:** Initial Project Foundation

| Phase | Description | Status |
|---|---|---|
| 01 | Project Foundation | In Progress |
| 02 | CI/CD Fundamentals | Planned |
| 03 | Application Quality and CI | Planned |
| 04 | Advanced GitHub Actions | Planned |
| 05 | AWS Infrastructure and Containerization | Planned |
| 06 | Secrets Management and Automated Deployment | Planned |
| 07 | Zero-Downtime Blue-Green Deployment | Planned |
| 08 | Health Checks and Automated Rollback | Planned |
| 09 | GitHub Copilot and Failure Testing | Planned |
| 10 | Final Documentation and Submission | Planned |

## Security Considerations

Security will be considered throughout the development and deployment lifecycle.

- Never commit passwords, API keys, access tokens, or private SSH keys.
- Store sensitive CI/CD credentials in GitHub Actions Secrets.
- Keep PostgreSQL inaccessible from the public internet.
- Use environment-specific configurations for staging and production.
- Maintain `.env` files outside version control.
- Use `.env.example` to document required environment variables without exposing actual credentials.
- Apply the principle of least privilege to application and deployment permissions.
- Regularly update dependencies and container images.
- Validate application health after every deployment.

## Project Repository

**GitHub Repository:**

[DevOps Module 5 Assignment](https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment)

## License

This project is licensed under the MIT License. See the LICENSE file for details.
