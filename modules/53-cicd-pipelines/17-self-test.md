## Self-Test
1. What is the difference between continuous delivery and continuous deployment?
2. Write a GitHub Actions `on:` trigger that runs on push to `main` and on a schedule every 6 hours.
3. What does the `strategy.matrix` keyword do in GitHub Actions?
4. How does `needs:` in GitLab CI differ from stage-based execution?
5. Write a GitLab CI job that only runs on merge requests that change files in `src/`.
6. What is the purpose of `artifacts:` in GitLab CI? How is it different from `cache:`?
7. Explain the master/agent architecture in Jenkins.
8. Write a Declarative Jenkins Pipeline stage that runs `mvn test` and archives the JUnit results.
9. What is a multibranch pipeline in Jenkins?
10. How does OIDC improve security compared to storing cloud credentials?
11. What is the difference between SAST and DAST?
12. Write a Trivy command to scan a Docker image and output SARIF format.
13. Explain blue/green deployment vs canary deployment.
14. How does a container-based runner (e.g., GitLab Runner with Docker executor) work internally?
15. What is SLSA and why is it important for supply-chain security?
**Score:** 12/15 correct = ready for Part 54.
## Answer Key
### Q1: What is the difference between continuous delivery and continuous deployment?
**Answer:** Continuous delivery = code is always deployable (manual approval needed). Continuous deployment = every change goes to production automatically after passing tests.
### Q2: Write a GitHub Actions trigger for push to main and schedule every 6 hours.
**Answer:**
```yaml
on:
  push:
    branches: [main]
  schedule:
    - cron: '0 */6 * * *'
```
### Q3: What does `strategy.matrix` do in GitHub Actions?
**Answer:** Runs the job multiple times with different combinations of variables (e.g., OS versions, Node versions). Each combination is a matrix entry.
### Q4: How does `needs:` in GitLab CI differ from stage-based execution?
**Answer:** `needs:` creates explicit DAG dependencies (Job B runs after Job A). Stage-based runs all jobs in stage N before stage N+1.
### Q5: Write a GitLab CI job that runs only on MR changes in `src/`.
**Answer:**
```yaml
test:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - "src/**/*"
  script: make test
```
### Q6: What is the purpose of `artifacts:` vs `cache:`?
**Answer:** `artifacts` = files passed between jobs/stages (downloadable). `cache` = files reused across pipeline runs (speeds up builds).
### Q7: Explain Jenkins master/agent architecture.
**Answer:** Master handles scheduling, UI, and config. Agents (nodes) execute the actual build steps. Agents connect via JNLP or SSH.
### Q8: Write a Jenkins Declarative stage for `mvn test` with JUnit.
**Answer:**
```groovy
stage('Test') {
  steps {
    sh 'mvn test'
    junit '**/target/surefire-reports/*.xml'
  }
}
```
### Q9: What is a multibranch pipeline in Jenkins?
**Answer:** Automatically creates pipelines for each branch in a repository, running Jenkinsfiles found in each branch.
### Q10: How does OIDC improve security vs storing cloud credentials?
**Answer:** OIDC uses short-lived tokens instead of long-lived access keys. No secrets in CI/CD — trust is established via identity federation.
### Q11: What is the difference between SAST and DAST?
**Answer:** SAST = Static Application Security Testing (analyzes source code). DAST = Dynamic Application Security Testing (tests running application).
### Q12: Write a Trivy command to scan a Docker image in SARIF format.
**Answer:** `trivy image --format sarif --output result.sarif myapp:latest`
### Q13: Blue/green vs canary deployment?
**Answer:** Blue/green = two identical environments, switch traffic instantly. Canary = gradually route a small percentage of traffic to the new version.
### Q14: How does a container-based runner work?
**Answer:** The runner spins up a fresh container per job, executes the script inside it, and destroys the container after. Ensures clean, isolated environments.
### Q15: What is SLSA?
**Answer:** Supply-chain Levels for Software Artifacts — a framework for build integrity. Levels 1-4 ensure provenance,防tampering, and reproducible builds.
*Linux SysAdmin Course | Part 53 of ∞ | Reverse Engineering Approach*
*Previous → Part 52: Kubernetes Administration*
*Next → Part 54: Advanced Configuration Management*
[← Previous](16-whats-coming-in-part-54.md) | [↑ Index](index.md)
