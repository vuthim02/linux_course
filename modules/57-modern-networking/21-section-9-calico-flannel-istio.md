## Section 9: Calico, Flannel, and Service Meshes

### Calico — Network Policy for Kubernetes

Calico provides networking and network security for containers, VMs, and bare metal.

```bash
# Install Calico on Kubernetes
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27/manifests/calico.yaml

# NetworkPolicy example
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

### Flannel — Simple Overlay Network

Minimalist overlay that assigns a /24 subnet to each node.

```bash
# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Backends: VXLAN (default), host-gw, UDP, IPIP, WireGuard
```

### Istio — Service Mesh

```yaml
# Install Istio
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: default
  components:
    ingressGateways: [{name: istio-ingressgateway, enabled: true}]
```

### Linkerd — Lightweight Service Mesh

```bash
# Install Linkerd CLI
curl -sL https://run.linkerd.io/install | sh
linkerd install | kubectl apply -f -
linkerd check          # Verify installation
linkerd inject deploy/myapp.yml | kubectl apply -f -
```

**Comparison**: Istio is feature-rich but heavy; Linkerd is lighter with Rust-based data plane; Calico focuses on network policy; Flannel is minimal overlay only.
