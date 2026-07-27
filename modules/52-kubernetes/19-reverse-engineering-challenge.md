## Reverse Engineering Challenge

You are given a Kubernetes cluster that is broken. Diagnose and fix it using only the command line. No documentation.

**Symptoms:**
- `kubectl get nodes` shows 2 of 3 nodes as `NotReady`.
- `kubectl get pods -A` shows several pods in `Pending` state.
- `kubectl get pods -n kube-system` shows `coredns` pods in `CrashLoopBackOff`.
- `kubectl describe node worker-2` shows `KubeletNotReady` with reason `PLEG is not healthy`.

**Your task (walk through this mentally or on a real cluster):**

1. Check kubelet logs on `worker-2`: `journalctl -u kubelet -n 100 --no-pager`.
2. Check container runtime: `crictl ps` and `crictl images`.
3. Check DNS resolution from the node: `nslookup kubernetes.default.svc.cluster.local <cluster-dns-ip>` (or check `/etc/resolv.conf`).
4. Verify the CNI plugin is running: `kubectl get pods -n kube-system -l k8s-app=calico-node` or `k8s-app=flannel`.
5. If `PLEG is not healthy`, restart containerd and kubelet: `systemctl restart containerd && systemctl restart kubelet`.
6. If CoreDNS CrashLoopBackOff: check logs (`kubectl logs -n kube-system coredns-xxx --previous`). Check CoreDNS ConfigMap. Check network policy or CNI configuration.

**What you should have learned:** Troubleshooting Kubernetes requires understanding the chain: API server → kubelet → container runtime → CNI. Break the chain at any point, and the cluster fails silently. The tools are `journalctl`, `crictl`, `kubectl`, and `systemctl`. No magic. Just systematic elimination.

---

```
*Linux SysAdmin Course | Part 52 of ∞ | Reverse Engineering Approach*
*Previous → Part 51: Infrastructure as Code — Terraform*
*Next → Part 53: CI/CD Pipelines — GitHub Actions, GitLab CI, Jenkins*
```

[← Previous](part51.md) | [Next →](part53.md)


---

[← Previous](18-self-test.md) | [↑ Index](index.md)
