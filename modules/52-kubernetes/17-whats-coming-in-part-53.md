## What's Coming in Part 53

**Part 53: CI/CD Pipelines — GitHub Actions, GitLab CI, Jenkins**

We will automate all of the above. Save the YAML to a repo, push, and watch a pipeline build, test, containerize, and deploy to Kubernetes — every commit, automatically.

Topics: GitHub Actions workflows, GitLab CI runners, Jenkins pipelines, Helm charts for templating, ArgoCD/GitOps for declarative deployments, image scanning, secret management in CI.

### What You'll Learn

- Writing CI/CD pipeline definitions from scratch
- Automating Docker image builds and pushes
- GitOps with ArgoCD for Kubernetes deployments
- Security scanning in pipelines (Trivy, Snyk)
- Secrets management (Vault, GitHub Secrets)

### How This Connects

Everything you've built in Parts 50 through 52 — cloud infrastructure, IaC templates, and Kubernetes clusters — serves as the deployment target for CI/CD pipelines. Part 53 ties it all together by automating the path from code commit to running production containers, closing the loop on the modern Linux sysadmin workflow.

### Why It Matters

Manual deployments are slow, error-prone, and difficult to repeat. CI/CD pipelines enforce consistency, catch bugs early through automated tests, and enable teams to ship updates multiple times a day with confidence. These pipelines are now standard practice in virtually every organization running Linux servers.


[← Previous](16-16-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](18-self-test.md)
