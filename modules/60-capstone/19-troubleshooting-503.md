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

### Check 4: Is the backend service healthy?
```bash
kubectl get endpoints capstone-api -n production
```
If endpoints are empty, the Service selector does not match any pod labels.

### Check 5: Is the ALB target group healthy?
```bash
aws elbv2 describe-target-health --target-group-arn <arn>
```
If targets are `unhealthy`, check the health check path and port in the target group configuration.

### Quick Fix: Scale and Restart

```bash
# Scale up to clear any stuck pods
kubectl scale deployment/capstone-api -n production --replicas=10

# Restart if health checks are failing
kubectl rollout restart deployment/capstone-api -n production
```

### Key Takeaways

- 503 means the service is *available* but *unable to handle requests* — focus on backends, not the load balancer
- Empty endpoints = wrong Service selector or all pods crashed
- Always check ALB target health if the Kubernetes side looks normal
- A `kubectl rollout restart` can clear stale connections and cached bad state




[← Previous](18-access.md) | [↑ Index](index.md) | [Next →](20-troubleshooting-memory.md)
