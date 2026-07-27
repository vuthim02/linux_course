## High Memory Usage

### Check per-pod memory
```bash
kubectl top pods -n production
```

### Check if HPA needs tuning
```bash
kubectl describe hpa capstone-api -n production
```

### Consider increasing resource limits in values.yaml



---

[← Previous](30-api-returns-503.md) | [↑ Index](index.md) | [Next →](32-slow-database-queries.md)
