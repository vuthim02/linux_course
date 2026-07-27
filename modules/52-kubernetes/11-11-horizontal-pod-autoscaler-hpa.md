## 11. Horizontal Pod Autoscaler (HPA)

The HPA automatically scales the number of pods in a deployment or statefulset based on observed metrics.

### Prerequisites: metrics-server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify
kubectl top nodes
kubectl top pods
```

### HPA Resource

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 3
  maxReplicas: 20
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
        name: requests_per_second
      target:
        type: AverageValue
        averageValue: 1000
  - type: Object
    object:
      metric:
        name: request_count
      describedObject:
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        name: myapp-ingress
      target:
        type: Value
        value: 10000
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300    # wait 5 min before scaling down
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

### How HPA Calculates Desired Replicas

```
desiredReplicas = ceil(currentReplicas * (currentMetricValue / desiredMetricValue))
```

Example:
- Current replicas: 3
- Current CPU utilization: 90%
- Target CPU: 70%
- desiredReplicas = ceil(3 * (90 / 70)) = ceil(3 * 1.29) = ceil(3.87) = 4

### Custom and External Metrics

- **Custom metrics** come from the pod itself (e.g., `requests_per_second` exposed by the app).
- **External metrics** come from outside the cluster (e.g., queue length from AWS SQS).
- Requires a metrics adapter (Prometheus Adapter, KEDA, etc.).

```bash
# Watch HPA status
kubectl get hpa -w
kubectl describe hpa nginx-hpa

# Generate load to test scaling
kubectl run load-generator --image=busybox --rm -it -- sh -c "while true; do wget -q -O- http://nginx.production; done"
```

### Scaling Behavior (autoscaling/v2)

- **stabilizationWindowSeconds**: Cooldown period before scaling in a direction.
- **policies**: Limits on how fast to scale (absolute pods or percentage per period).
- **selectPolicy**: `Max` (least restrictive), `Min` (most restrictive), `Disabled` (block direction).

---



---

[← Previous](10-10-rbac-role-based-access-control.md) | [↑ Index](index.md) | [Next →](12-12-logging-and-debugging.md)
