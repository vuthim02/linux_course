## Resolution
```bash
# 1. Rollback to last working version
helm rollback capstone-api <previous-revision> -n production

# 2. If config issue, fix and redeploy
helm upgrade --install capstone-api ./helm -n production --values ./helm/values.yaml --set image.tag=fixed-tag

# 3. Force restart
kubectl rollout restart deployment/capstone-api -n production
```
```

### Troubleshooting Guide

```markdown
# Troubleshooting Guide



---

[← Previous](28-common-causes.md) | [↑ Index](index.md) | [Next →](30-api-returns-503.md)
