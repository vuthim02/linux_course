## 13. Upgrades

### kubeadm Upgrade Process

Upgrade one minor version at a time (1.29 → 1.30 → 1.31). Never skip.

**Step 1: Upgrade kubeadm on control plane**

```bash
# Check available versions
apt-cache madison kubeadm

# Drain the control plane node (optional, for multi-CP clusters)
kubectl drain control-plane-1 --ignore-daemonsets

# Upgrade kubeadm
apt-get update && apt-get install -y kubeadm=1.30.x-*
kubeadm upgrade plan
kubeadm upgrade apply v1.30.x

# Uncordon
kubectl uncordon control-plane-1
```

**Step 2: Upgrade kubelet and kubectl on control plane**

```bash
apt-get install -y kubelet=1.30.x-* kubectl=1.30.x-*
systemctl daemon-reload
systemctl restart kubelet
```

**Step 3: Upgrade worker nodes**

```bash
# Drain
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# On worker-1:
apt-get install -y kubeadm=1.30.x-* kubelet=1.30.x-* kubectl=1.30.x-*
kubeadm upgrade node
systemctl daemon-reload
systemctl restart kubelet

# Uncordon on control plane
kubectl uncordon worker-1
```

### Drain and Cordon

```bash
# Cordon (mark unschedulable, but running pods stay)
kubectl cordon worker-1

# Drain (evict all pods gracefully)
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data --force

# Uncordon (resume scheduling)
kubectl uncordon worker-1
```

`--ignore-daemonsets`: DaemonSet pods are ignored (they run on every node).
`--delete-emptydir-data`: Allow eviction of pods with emptyDir volumes.
`--force`: Force eviction even if not managed by a controller.

### Pod Disruption Budgets

PDB limits the number of voluntary disruptions a deployment can tolerate during maintenance.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
  namespace: production
spec:
  minAvailable: 2           # or maxUnavailable: 1
  selector:
    matchLabels:
      app: nginx
```

```bash
# Check PDB status
kubectl get pdb
kubectl describe pdb nginx-pdb
```

`drain` respects PDB: if draining would violate the PDB, it waits (or eventually times out with `--force`).

### Cluster Version Skew Policy

| Component | Allowed Skew |
|---|---|
| kube-apiserver | Latest version |
| kube-controller-manager, kube-scheduler | ≤ 1 minor version behind API server |
| kubelet | ≤ 2 minor versions behind API server |
| kube-proxy | ≤ 2 minor versions behind API server |
| kubectl | ±1 minor version from API server |





[← Previous](12-12-logging-and-debugging.md) | [↑ Index](index.md) | [Next →](14-14-deep-understanding.md)
