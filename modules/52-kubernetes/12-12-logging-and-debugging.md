## 12. Logging and Debugging

### kubectl logs

```bash
# Basic
kubectl logs nginx-7f8b9c6d9-abc12

# Previous instance (if container crashed and restarted)
kubectl logs nginx-7f8b9c6d9-abc12 --previous

# Tail and follow
kubectl logs nginx-7f8b9c6d9-abc12 --tail=50 -f

# Multi-container pod
kubectl logs nginx-7f8b9c6d9-abc12 -c sidecar

# All pods matching label
kubectl logs -l app=nginx --tail=20 -f

# Timestamps
kubectl logs nginx-7f8b9c6d9-abc12 --timestamps

# Max lines (avoid truncation)
kubectl logs nginx-7f8b9c6d9-abc12 --tail=500
```

### kubectl debug (Kubernetes 1.20+)

Creates a temporary container or pod with debugging tools.

```bash
# Debug a running pod (add ephemeral container)
kubectl debug nginx-7f8b9c6d9-abc12 -it --image=busybox -- sh

# Debug a node (creates a pod running on the node)
kubectl debug node/worker-1 -it --image=alpine -- sh

# Copy of a pod for debugging (matches pod spec)
kubectl debug nginx-7f8b9c6d9-abc12 -it --copy-to=debug-pod --image=nicolaka/netshoot
```

### Ephemeral Containers

Ephemeral containers are temporary debugging containers attached to a running pod. They have no resource guarantees, no ports, and are not restarted.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  ephemeralContainers:
  - name: debug
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
    targetContainerName: app
```

```bash
kubectl alpha debug -it myapp --image=nicolaka/netshoot
```

### Events

```bash
# Cluster events
kubectl get events -A --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -A -w

# Filter by resource
kubectl get events --field-selector involvedObject.name=nginx-deploy-7f8b9c6d9

# Describe includes events
kubectl describe pod nginx-7f8b9c6d9-abc12
```

### crictl — Debugging Container Runtime

On the node directly:

```bash
# List all containers
crictl ps -a

# Container logs (not truncated like docker)
crictl logs <container-id>

# Inspect
crictl inspect <container-id>

# Execute
crictl exec -it <container-id> sh

# List images
crictl images

# Pull image
crictl pull nginx:1.25-alpine
```

### Node Conditions

```bash
kubectl describe node worker-1
kubectl get node worker-1 -o yaml | grep -A10 conditions:
```

Common conditions:
- `Ready` (True/False/Unknown)
- `DiskPressure` (True/False)
- `MemoryPressure` (True/False)
- `PIDPressure` (True/False)
- `NetworkUnavailable` (True/False)

### Debugging a CrashLoopBackOff

1. Check logs of the previous (crashed) instance:
   ```bash
   kubectl logs pod-name --previous
   ```
2. Describe the pod for events and container status:
   ```bash
   kubectl describe pod pod-name
   ```
3. Check the exit code in container status (137 = SIGKILL from OOM, 1 = app error).
4. If OOM (exit 137), increase memory limits.
5. Check image name/pull policy — wrong image or registry auth.
6. Check liveness/readiness probe timing — too aggressive probes restart pods.

---



---

[← Previous](11-11-horizontal-pod-autoscaler-hpa.md) | [↑ Index](index.md) | [Next →](13-13-upgrades.md)
