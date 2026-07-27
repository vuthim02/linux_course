## CI/CD
The GitHub Actions workflow in `.github/workflows/deploy.yaml`:
1. Lints and tests code
2. Builds Docker image
3. Scans for vulnerabilities with Trivy
4. Pushes to ECR
5. Deploys to staging
6. Runs integration tests
7. Promotes to production



---

[← Previous](22-quick-start.md) | [↑ Index](index.md) | [Next →](24-access.md)
