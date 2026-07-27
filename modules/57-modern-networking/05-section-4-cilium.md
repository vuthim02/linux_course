## 🔍 Section 4: Cilium

### What Is Cilium?

Cilium is an eBPF-based CNI (Container Network Interface) plugin for Kubernetes. It replaces the entire kube-proxy and iptables-based networking with a high-performance eBPF datapath. It provides:

- **eBPF-based service translation** (replaces kube-proxy)
- **Network policies** at L3, L4, and L7
- **Hubble** — observability for network flows
- **Transparent encryption** via WireGuard or IPsec
- **Service mesh** — L7 traffic management, ingress, gateway API
- **ClusterMesh** — multi-cluster networking

### Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                    Kubernetes Node                                 │
│                                                                    │
│  ┌──────────────────────┐  ┌────────────────────┐                 │
│  │  Cilium Agent        │  │  Cilium Operator   │                 │
│  │  (cilium-agent)      │  │  (cluster-level)   │                 │
│  │                      │  │                    │                 │
│  │  • eBPF datapath     │  │  • IPAM            │                 │
│  │  • Policy enforcement│  │  • Node management │                 │
│  │  • Service handling  │  │  • CNI integration │                 │
│  │  • Hubble server     │  │  • CiliumEndpoint  │                 │
│  └──────────┬───────────┘  └────────────────────┘                 │
│             │                                                      │
│  ┌──────────▼───────────┐                                         │
│  │  eBPF Programs       │                                         │
│  │  ┌──────┐ ┌───────┐ │ ┌──────────────┐ ┌──────────────────┐   │
│  │  │ XDP  │ │ tc    │ │ │ cgroup/skb   │ │ cgroup/sock      │   │
│  │  └──────┘ └───────┘ │ └──────────────┘ └──────────────────┘   │
│  │  ┌────────┐ ┌─────┐ │ ┌──────────┐                            │
│  │  │ l3_l4  │ │ l7  │ │ │ encap    │                            │
│  │  └────────┘ └─────┘ │ └──────────┘                            │
│  └─────────────────────┘                                          │
│                                                                    │
│  ┌──────────────────────┐                                         │
│  │  Hubble              │                                         │
│  │  • Flow collector    │                                         │
│  │  • Service map       │                                         │
│  │  • Metrics (Prom)    │                                         │
│  └──────────────────────┘                                         │
└────────────────────────────────────────────────────────────────────┘
```

### Installing Cilium

**Prerequisites:**
```bash
# Install kind (Kubernetes in Docker)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/

# Create a kind cluster
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

**Install Cilium CLI:**
```bash
# Download and install Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}
```

**Install Cilium with kube-proxy replacement:**
```bash
cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=<KUBERNETES_API_SERVER_IP> \
  --set k8sServicePort=6443

# Or for a kind cluster (simpler):
cilium install --set kubeProxyReplacement=true

# Verify
cilium status
cilium connectivity test
```

### How Cilium Replaces kube-proxy

Traditional Kubernetes networking:

```
Pod A (10.0.1.5) → Service IP (10.96.0.10:80) → iptables NAT → Pod B (10.0.2.7)
                                                            ↓
                                                    Every packet traverses
                                                    iptables chains (O(n) rules)
```

Cilium's eBPF approach:

```
Pod A (10.0.1.5) → Service IP (10.96.0.10:80)
                            ↓
                    eBPF program (tc or XDP)
                            ↓
                    BPF map lookup:
                    {service_ip, port} → {backend_ip, port}
                            ↓
                    Direct XDP_TX or tc redirect
                    No iptables involved — O(1) lookup
```

The eBPF program runs in the kernel and performs a hash table lookup (BPF_MAP_TYPE_HASH) to translate service VIPs to backend pods. This is **O(1)**, compared to iptables which chains through rules linearly.

```bash
# Verify kube-proxy is not needed
kubectl -n kube-system get pods | grep proxy
# Should show nothing if kubeProxyReplacement=true

# Inspect Cilium's eBPF programs
cilium bpf service list
# Shows service-to-backend mapping

# Example output:
# 10.96.0.10:80 (1) 10.0.2.7:8080 (1)
#                   10.0.2.8:8080 (1)
```

---



---

[← Previous](04-section-3-xdp-express-data.md) | [↑ Index](index.md) | [Next →](06-section-5-cilium-network-policies.md)
