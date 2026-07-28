## 🔍 Section 6: Cilium Service Mesh

### L7 Traffic Management

Cilium's service mesh is built into the eBPF datapath — no sidecar proxies needed (unless you want them). It provides:

- **HTTP/1.1, HTTP/2, gRPC aware routing**
- **Transparent encryption** (WireGuard) between pods
- **Mutual authentication** via SPIFFE identities
- **Ingress and Gateway API** support
- **ClusterMesh** for multi-cluster service connectivity

### Enabling L7 Policy

```yaml
# l7-visibility.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-ingress-visibility
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: httpbin
  ingress:
    - toPorts:
        - ports:
            - port: "80"
              protocol: TCP
          rules:
            http:
              - method: "GET"
                path: "/get"
              - method: "POST"
                path: "/post"
```

### Transparent Encryption with WireGuard

Cilium can automatically encrypt all pod-to-pod traffic using WireGuard without modifying application code:

```bash
# Install Cilium with WireGuard encryption
cilium install \
  --set encryption.enabled=true \
  --set encryption.type=wireguard

# Verify WireGuard is active
cilium status | grep Encryption
# Expected: Encryption: WireGuard

# List WireGuard peers on a node
cilium encrypt status

# Check WireGuard interfaces per pod
sudo ip link show | grep lxc
# Cilium creates one WireGuard device per node: cilium_wg0
```

### How Cilium WireGuard Works

```
Pod A (node-1) ──► cilium_wg0 ──► Node-2 ──► Pod B
                     │
                     ▼
              Encrypted tunnel
              ChaCha20Poly1305
              Noise protocol
```

Cilium assigns SPIFFE identities to each pod. When Pod A sends to Pod B:
1. eBPF program classifies the packet and determines it needs encryption
2. Packet is routed to `cilium_wg0` WireGuard interface
3. WireGuard encrypts with Node B's public key
4. Node B decrypts and delivers to Pod B

### Mutual Authentication with SPIFFE

Cilium uses SPIFFE (Secure Production Identity Framework for Everyone) to issue identities to pods:

```
spiffe://cluster.local/ns/default/sa/my-sa
```

These identities are embedded in the eBPF datapath — no sidecars needed.

### Ingress/Gateway API

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cilium-gateway
  namespace: default
spec:
  gatewayClassName: cilium
  listeners:
    - name: http
      protocol: HTTP
      port: 80
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-app-1
  namespace: default
spec:
  parentRefs:
    - name: cilium-gateway
  hostnames:
    - app1.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: app1-service
          port: 8080
```

```bash
kubectl apply -f gateway.yaml -f httproute.yaml
```

### ClusterMesh

ClusterMesh connects multiple Kubernetes clusters so that pods in one cluster can discover and connect to services in another cluster, with all eBPF benefits:

```bash
# Install Cilium on cluster-1 and cluster-2
cilium install --context cluster-1
cilium install --context cluster-2

# Enable ClusterMesh
cilium clustermesh enable --context cluster-1
cilium clustermesh enable --context cluster-2

# Connect them
cilium clustermesh connect --context cluster-1 --destination-context cluster-2

# Status
cilium clustermesh status --context cluster-1
```





[← Previous](06-section-5-cilium-network-policies.md) | [↑ Index](index.md) | [Next →](08-section-7-hubble.md)
