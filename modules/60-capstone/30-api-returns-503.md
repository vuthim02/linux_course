## API Returns 503

### Check 1: Is the application running?
```bash
kubectl get pods -n production -l app.kubernetes.io/name=capstone-api
```
If pods are not running: `kubectl describe pod <name>` to see why.

### Check 2: Is the database reachable?
```bash
kubectl exec -it deployment/capstone-api -n production -- curl -f http://localhost:8000/health
```
If health check fails on DB: check RDS connectivity and credentials.

### Check 3: Is the ingress working?
```bash
kubectl get ingress -n production
kubectl describe ingress capstone-api -n production
```



---

[← Previous](29-resolution.md) | [↑ Index](index.md) | [Next →](31-high-memory-usage.md)
