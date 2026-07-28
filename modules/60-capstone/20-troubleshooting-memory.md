## High Memory Usage

### Step 1: Check per-pod memory

```bash
kubectl top pods -n production --sort-by=memory
```

Identify which pods are consuming the most memory. If a pod exceeds its `resources.limits.memory`, Kubernetes will OOM-kill it (restart).

### Step 2: Check if HPA needs tuning

```bash
kubectl describe hpa capstone-api -n production
kubectl get hpa -n production -o yaml | grep -A 10 "currentMetrics"
```

Common HPA issues:
- `CurrentReplicas: 5, DesiredReplicas: 5` when memory is at 90% → HPA is not scaling on memory (check `--metrics` flag)
- Memory metric not configured → add `--metric-types=memory` or define `memory` in the HPA spec

### Step 3: Check node-level memory pressure

```bash
kubectl describe nodes | grep -A 5 "Allocated resources"
kubectl top nodes
```

If nodes are near 100% memory, pods may be evicted. Check `kubectl get events -n production --field-selector reason=Evicted`.

### Step 4: Adjust resource limits in values.yaml

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### Common Causes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Pod OOMKilled repeatedly | Memory limit too low | Increase `limits.memory` |
| All pods high memory | Memory leak in app | Profile with `jmap`/`pprof`, fix leak |
| Nodes at capacity | No cluster autoscaler | Enable cluster autoscaler |
| Sudden spike after deploy | New code regression | Roll back, profile new code |



[← Previous](19-troubleshooting-503.md) | [↑ Index](index.md) | [Next →](21-infrastructure-costs.md)
