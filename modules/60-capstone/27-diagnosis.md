## Diagnosis
```bash
# Check pod status
kubectl get pods -n production
kubectl describe pod <pod-name> -n production

# Check logs
kubectl logs <pod-name> -n production --previous

# Check events
kubectl get events -n production --sort-by=.lastTimestamp
```



---

[← Previous](26-symptoms.md) | [↑ Index](index.md) | [Next →](28-common-causes.md)
