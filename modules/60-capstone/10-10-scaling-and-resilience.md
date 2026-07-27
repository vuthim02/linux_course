## 10. Scaling and Resilience

### HPA — Advanced Configuration

```yaml
# Custom metrics HPA example
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: capstone-api-custom
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: capstone-api
  minReplicas: 3
  maxReplicas: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 2
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Pods
          value: 10
          periodSeconds: 15
        - type: Percent
          value: 200
          periodSeconds: 15
      selectPolicy: Max
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
    - type: Pods
      pods:
        metric:
          name: app_requests_per_second
        target:
          type: AverageValue
          averageValue: 1000
```

### Cluster Autoscaler Verification

```bash
# Check cluster-autoscaler status
kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler --tail=50

# Simulate scale-up by deploying many pods
kubectl create deployment stress-test --image=nginx --replicas=100
watch kubectl get pods
# Observe new nodes being added

# Clean up
kubectl delete deployment stress-test
# Observe nodes being drained and removed
```

### PodDisruptionBudget Verification

```yaml
# Test PDB with eviction
kubectl drain NODE_NAME --ignore-daemonsets
# Without PDB: pods get evicted immediately
# With PDB: eviction waits until minAvailable is satisfied
```

### Anti-Affinity Rules

```yaml
# Verified by checking pod distribution across zones
kubectl get pods -n production -o wide --sort-by=.spec.nodeName

# Confirm pods are spread
kubectl get pods -n production -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'
```

---



---

[← Previous](09-9-observability-stack.md) | [↑ Index](index.md) | [Next →](11-11-security-hardening.md)
