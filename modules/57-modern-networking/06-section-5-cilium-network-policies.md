## 🔍 Section 5: Cilium Network Policies

### Policy Basics

CiliumNetworkPolicy (CNP) is a Kubernetes custom resource that defines traffic rules. Unlike default Kubernetes NetworkPolicy (which works at L3/L4 with iptables), Cilium policies can:

- Match on L3 (CIDR, pod labels, service identities)
- Match on L4 (ports, protocols)
- Match on L7 (HTTP methods, paths, headers, gRPC methods, Kafka topics)
- Use FQDN-based rules (allow traffic to `api.example.com`)
- Egress and ingress on the same or separate rules

### Policy Structure

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: example-policy
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
  egress:
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
```

### Deny-All Policy

```yaml
# deny-all-ingress.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  ingress:
    - {}  # Empty rule = deny all ingress
```

```bash
kubectl apply -f deny-all-ingress.yaml
```

### L3/L4 Policy — Allow Specific Pod-to-Pod

```yaml
# allow-frontend-to-backend.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: backend
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
```

### L7 Policy — HTTP Methods, Paths, Headers

```yaml
# http-l7-policy.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-http
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: web-frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: "/api/v1/users"
              - method: POST
                path: "/api/v1/orders"
              - method: GET
                path: "/healthz"
              - method: GET
                path: "/api/v1/products/*"
```

```bash
kubectl apply -n default -f http-l7-policy.yaml
# Test:
# kubectl exec -it frontend-pod -- curl -X POST http://api-server:8080/api/v1/users  # Allowed
# kubectl exec -it frontend-pod -- curl -X DELETE http://api-server:8080/api/v1/users # Blocked (403)
```

### FQDN Policy — Allow Egress to Specific Domains

```yaml
# fqdn-egress.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-api-egress
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  egress:
    - toFQDNs:
        - matchName: api.example.com
        - matchPattern: "*.example.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
```

FQDN policies automatically resolve DNS names and update the BPF map when IPs change. Cilium intercepts DNS responses to learn new IP addresses.

### CIDR Rules — Direct IP Range Filtering

```yaml
# cidr-egress.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-cidr-egress
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  egress:
    - toCIDR:
        - 10.100.0.0/16
        - 192.168.1.0/24
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
    - toCIDRSet:
        - cidr: 10.0.0.0/8
          except:
            - 10.96.0.0/12  # Exclude Kubernetes service range
```

### Policy Enforcement Modes

| Mode | Behavior |
|------|----------|
| `default` | Deny-all ingress, allow-all egress (Kubernetes default) |
| `always` | Always enforce policies (even without rules — deny all) |
| `never` | Disable policy enforcement (for migration/testing) |
| Custom | Mix of enforce/audit per endpoint |

```bash
# Check per-endpoint enforcement mode
kubectl describe cep my-pod-xxxxx | grep Policy
```

---



---

[← Previous](05-section-4-cilium.md) | [↑ Index](index.md) | [Next →](07-section-6-cilium-service-mesh.md)
