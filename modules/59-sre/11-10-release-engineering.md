## 10. Release Engineering

### Progressive Delivery

| Technique | Risk | Rollback Time |
|---|---|---|
| Feature flags | Very low | Seconds |
| Canary release | Low | Minutes |
| Blue/green | Low | Seconds |
| Rolling update | Medium | Depends |

### Feature Flags with Flagger

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: checkout-api
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: checkout-api
  service:
    port: 8080
  analysis:
    interval: 30s
    maxWeight: 50
    stepWeight: 5
    thresholds:
      maxRestarts: 2
      latency: { threshold: 200, percentile: 99 }
      errorRate: { threshold: 1 }
    metrics:
      - name: request-success-rate
        templateRef: { name: success-rate }
        threshold: 99
        interval: 1m
```

### Blue/Green Deployment Script

```bash
#!/bin/bash
# blue-green-deploy.sh
set -euo pipefail
APP="checkout-api"
BLUE_NS="${APP}-blue"; GREEN_NS="${APP}-green"
ACTIVE_NS=$(kubectl get svc -n "${BLUE_NS}" -o name >/dev/null 2>&1 && echo "${BLUE_NS}" || echo "${GREEN_NS}")
INACTIVE_NS=$([ "$ACTIVE_NS" = "${BLUE_NS}" ] && echo "${GREEN_NS}" || echo "${BLUE_NS}")
echo "Active: ${ACTIVE_NS}, deploying to: ${INACTIVE_NS}"

kubectl apply -f k8s/deployment.yaml -n "${INACTIVE_NS}"
kubectl rollout status deployment/"${APP}" -n "${INACTIVE_NS}" --timeout=5m
curl -f -s "http://${APP}-${INACTIVE_NS}/health" || exit 1
kubectl apply -f k8s/service.yaml -n "${INACTIVE_NS}"
sleep 300  # observation window
kubectl scale deployment/"${APP}" -n "${ACTIVE_NS}" --replicas=0
echo "Deploy complete. Active: ${INACTIVE_NS}"
```

### Rollback Triggers

```yaml
triggers:
  - error_rate_5m > 5%
  - p99_latency_5m > 500ms
  - error_budget_burn_rate > 10x

kubernetes_rollback:
  - "kubectl rollout undo deployment/checkout-api"
  - "kubectl rollout status deployment/checkout-api"
```





[← Previous](10-9-capacity-planning.md) | [↑ Index](index.md) | [Next →](12-11-monitoring-for-sres.md)
