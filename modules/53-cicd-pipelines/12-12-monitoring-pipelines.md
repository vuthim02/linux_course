## 12. Monitoring Pipelines

| Metric | Source | What It Tells |
|--------|--------|---------------|
| Build duration | All CI systems | Pipeline efficiency |
| Success rate | API | Pipeline stability |
| Queue time | Runner logs | Runner capacity |
| Test pass rate | JUnit | Code quality |
| Coverage % | Jacoco/Cobertura | Test quality |

**Prometheus metrics:**
- GitLab: `gitlab_runner_jobs_total`, `gitlab_ci_pipeline_duration_seconds`
- Jenkins: `default_jenkins_builds_success_total`, `default_jenkins_builds_duration_milliseconds_sum`, `default_jenkins_queue_size_value`

**Grafana dashboard panels:** Pipeline Success Rate (7d), Build Duration p50/p95/p99, Active Runners, Queue Depth,
Panel 5: Test Pass Rate — bar chart
Panel 6: Top Failed Jobs — table
```

**GitHub Actions API:**
```bash
# Get workflow run stats
gh run list --repo myorg/my-app --limit 100 --json conclusion,createdAt,updatedAt,duration

# Get job-level metrics
gh run view RUN_ID --repo myorg/my-app --log
```

**GitLab CI API:**
```bash
# Pipeline statistics
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/pipelines?per_page=100"

# Job duration per pipeline
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs"
```

### Runner Utilization

```bash
# GitLab Runner autoscaling metrics
docker exec gitlab-runner cat /var/log/gitlab-runner.log | grep "processed"

# Jenkins — Manage Jenkins → Load Statistics: graphs of executor usage
# Jenkins — Script Console: Jenkins.instance.computers.each { println it }
```

### Alerts for Failures

```yaml
# GitHub Actions — Slack notification on failure
jobs:
  notify:
    runs-on: ubuntu-22.04
    if: failure() && github.ref == 'refs/heads/main'
    needs: [build, test, deploy]
    steps:
      - name: Slack Notification
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_CHANNEL: '#ci-cd-alerts'
          SLACK_COLOR: danger
          SLACK_TITLE: 'Pipeline failed on main'
          SLACK_MESSAGE: |
            Job: ${{ github.workflow }}
            Run: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
            Branch: ${{ github.ref_name }}
            Commit: ${{ github.sha }}
```

```yaml
# GitLab CI — email + Slack
notify-failure:
  stage: .post
  script:
    - |
      curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"❌ Pipeline failed: $CI_PIPELINE_URL\"}" \
        $SLACK_WEBHOOK_URL
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_failure
```

```groovy
// Jenkins — email notification
post {
    failure {
        emailext(
            to: 'team@example.com',
            subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """
                Pipeline failed: ${env.BUILD_URL}
                Branch: ${env.BRANCH_NAME}
                Commit: ${env.GIT_COMMIT}
                Check: ${env.BUILD_URL}console
            """
        )
    }
}
```

---



---

[← Previous](11-11-deployment-strategies.md) | [↑ Index](index.md) | [Next →](13-15-hands-on-practices.md)
