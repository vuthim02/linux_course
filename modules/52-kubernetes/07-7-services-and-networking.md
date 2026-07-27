## 7. Services and Networking

### Service Types

**ClusterIP** — internal cluster IP, reachable only from within the cluster. Default type.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80              # service port
    targetPort: 8080       # container port
    protocol: TCP
```

**NodePort** — exposes the service on a static port (30000-32767) on every node.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080        # optional, otherwise random
```

```bash
# Access via any node IP
curl http://192.168.1.10:30080
curl http://192.168.1.11:30080
```

**LoadBalancer** — provisions an external load balancer (cloud provider) that forwards traffic to NodePorts.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl get svc nginx-lb    # shows EXTERNAL-IP once provisioned
```

**ExternalName** — returns a CNAME record for the service. Used to reference external services by DNS.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.com
```

```bash
# Now pods can reach it as: external-db.production.svc.cluster.local
```

### DNS Inside the Cluster

CoreDNS runs as a Deployment in the kube-system namespace. Every service gets a DNS name:

```
<service>.<namespace>.svc.cluster.local
<service>.<namespace>.svc.<cluster-domain>
```

Pods also get DNS (based on `hostname` and `subdomain`):

```
<pod-ip-addr>.<service>.<namespace>.svc.cluster.local
```

```bash
# Test DNS resolution from a pod
kubectl run test --image=busybox --rm -it -- nslookup kubernetes.default.svc.cluster.local
```

### Endpoints and EndpointSlice

When a Service has a pod selector, Kubernetes creates Endpoints (or EndpointSlice, newer API) tracking the pod IPs.

```bash
kubectl get endpoints nginx
kubectl get endpointslices -l kubernetes.io/service-name=nginx
```

### Ingress and Ingress Controller

Ingress is an API object that manages external HTTP/HTTPS access to services. It provides virtual hosting, path-based routing, TLS termination.

An **Ingress Controller** (like nginx-ingress, Traefik, HAProxy, AWS ALB) must be installed in the cluster — the Ingress resource is just a config spec, inert without a controller.

```bash
# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### NetworkPolicy

NetworkPolicy controls traffic flow at the IP address or port level. It is **enforced by the CNI plugin** — plain Flannel does not enforce it, Calico and Cilium do.

By default, all pods can communicate with all pods. A NetworkPolicy changes that.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
    ports:
    - port: 5432
      protocol: TCP
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8
    ports:
    - port: 443
      protocol: TCP
```

```bash
# Test network policy
kubectl run test --image=busybox --rm -it -- wget --timeout=2 http://postgres.production:5432
```

---



---

[← Previous](06-6-workloads.md) | [↑ Index](index.md) | [Next →](08-8-configmaps-and-secrets.md)
