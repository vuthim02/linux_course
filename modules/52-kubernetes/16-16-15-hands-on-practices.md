## 16. 15 Hands-On Practices

### Practice 1: Install kubeadm, kubelet, kubectl on 2 VMs

Set up two Ubuntu 22.04 VMs (control-plane and worker-1):

```bash
# Run on BOTH nodes
cat <<EOF | sudo bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl containerd
apt-mark hold kubelet kubeadm kubectl
EOF
```

Verify:
```bash
kubeadm version
kubectl version --client
kubelet --version
```

### Practice 2: Initialize Cluster and Join Worker

```bash
# On control-plane:
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get nodes   # control-plane should be NotReady (no CNI yet)

# Copy the join command from init output
# On worker-1:
sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# If token expired:
kubeadm token create --print-join-command
```

### Practice 3: Install Calico CNI

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27/manifests/calico.yaml

watch kubectl get pods -n calico-system
watch kubectl get nodes   # wait for Ready
```

### Practice 4: kubectl Basics

```bash
kubectl get nodes -o wide
kubectl describe node worker-1

# Run a test pod
kubectl run test --image=nginx --restart=Never --port=80

kubectl get pods -w
kubectl describe pod test
kubectl logs test
kubectl exec -it test -- sh -c "echo hello > /usr/share/nginx/html/index.html"
kubectl port-forward pod/test 8080:80

# Clean up
kubectl delete pod test
```

### Practice 5: Deployment with 3 Replicas and Service

```yaml
# nginx-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
kubectl apply -f nginx-deploy.yaml
kubectl get pods -l app=nginx
kubectl get svc nginx

# Access the service
kubectl run test --image=busybox --rm -it -- wget -qO- http://nginx
```

### Practice 6: Rolling Update and Rollback

```bash
# Update image
kubectl set image deployment/nginx nginx=nginx:1.26-alpine

# Watch rollout
kubectl rollout status deployment/nginx

# Check history
kubectl rollout history deployment/nginx

# Rollback
kubectl rollout undo deployment/nginx

# Verify rollback
kubectl rollout status deployment/nginx
kubectl describe deployment nginx | grep Image
```

### Practice 7: StatefulSet with PVC Template

```yaml
# postgres-statefulset.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None       # headless service for stable DNS
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 2
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: testpass
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

```bash
kubectl apply -f postgres-statefulset.yaml
kubectl get pods -l app=postgres -w
kubectl get pvc
kubectl exec -it postgres-0 -- psql -U postgres -c "CREATE DATABASE testdb;"
kubectl delete pod postgres-0    # pvc persists, data survives
# Verify data survives on new postgres-0
kubectl exec -it postgres-0 -- psql -U postgres -c "\l"
```

### Practice 8: DaemonSet for Logging

```yaml
# fluentbit-ds.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:2.1
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: containers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
```

```bash
kubectl apply -f fluentbit-ds.yaml
kubectl get daemonsets -n kube-system
kubectl get pods -n kube-system -l app=fluent-bit -o wide
```

### Practice 9: ConfigMaps and Secrets

```yaml
# config-and-secrets.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: production
  APP_DEBUG: "false"
  DB_HOST: postgres.production.svc.cluster.local
---
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  DB_USER: YWRtaW4=              # base64(admin)
  DB_PASSWORD: cDNjcjN0          # base64(p3cr3t)
---
apiVersion: v1
kind: Pod
metadata:
  name: config-demo
spec:
  containers:
  - name: app
    image: alpine:3.19
    command: ["sleep", "3600"]
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: db-secret
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

```bash
kubectl apply -f config-and-secrets.yaml
kubectl exec config-demo -- env | sort
kubectl exec config-demo -- cat /etc/config/APP_ENV
kubectl exec config-demo -- ls -la /etc/config
```

### Practice 10: Ingress Resource with NGINX Ingress Controller

```bash
# Install ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Wait for it
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
```

```yaml
# ingress-demo.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: demo.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

```bash
kubectl apply -f ingress-demo.yaml
kubectl get ingress

# Test (add to /etc/hosts or use curl --resolve)
kubectl get svc -n ingress-nginx ingress-nginx-controller
curl -H "Host: demo.local" http://<ingress-controller-external-ip>
```

### Practice 11: NetworkPolicy

```yaml
# network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-db
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx
    ports:
    - port: 5432
```

```bash
kubectl apply -f network-policies.yaml

# Test: run a pod without app=nginx label, try to reach postgres
kubectl run test1 --image=busybox --rm -it -- wget -qO- --timeout=2 http://postgres:5432 || echo "blocked"

# Test: run a pod with app=nginx label
kubectl run test2 --image=busybox --labels="app=nginx" --rm -it -- wget -qO- --timeout=2 http://postgres:5432 || echo "blocked"
```

### Practice 12: RBAC — ServiceAccount with Read-Only Access

```yaml
# rbac-demo.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: readonly-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: readonly-binding
subjects:
- kind: ServiceAccount
  name: readonly-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f rbac-demo.yaml

# Get the token
kubectl get secret $(kubectl get sa readonly-sa -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d

# Use the token
kubectl --token=<token> get pods          # works
kubectl --token=<token> delete pod test   # fails (forbidden)
```

### Practice 13: HPA with metrics-server

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait
kubectl wait --namespace kube-system --for=condition=ready pod --selector=k8s-app=metrics-server --timeout=120s

kubectl top nodes
```

```yaml
# hpa-demo.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

```bash
kubectl apply -f hpa-demo.yaml
kubectl get hpa -w

# Generate load
kubectl run load-generator --image=busybox --rm -it -- sh -c "while true; do wget -q -O- http://nginx; done"

# Watch scale-up in another terminal
watch kubectl get pods -l app=nginx
```

### Practice 14: Drain and Cordon a Node

```bash
# Cordon
kubectl cordon worker-1
kubectl get nodes    # STATUS shows Ready,SchedulingDisabled

# Drain
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# Verify pods moved
kubectl get pods -o wide

# Perform maintenance (simulate)
sleep 10

# Uncordon
kubectl uncordon worker-1
kubectl get nodes
```

### Practice 15: Real-World Full Stack Application

Deploy a three-tier application: React frontend, Node.js backend, PostgreSQL database.

```yaml
# 01-db.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  POSTGRES_USER: app
  POSTGRES_PASSWORD: changeme
  POSTGRES_DB: myapp
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - secretRef:
            name: db-secret
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 5Gi
```

```yaml
# 02-backend.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  DB_HOST: postgres.default.svc.cluster.local
  DB_PORT: "5432"
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: api
        image: node:20-alpine
        command:
        - sh
        - -c
        - |
          npm init -y && npm install express pg && cat <<'SCRIPT' > server.js
          const express = require('express');
          const { Pool } = require('pg');
          const app = express();
          const pool = new Pool({
            host: process.env.DB_HOST,
            port: process.env.DB_PORT,
            user: process.env.POSTGRES_USER,
            password: process.env.POSTGRES_PASSWORD,
            database: process.env.POSTGRES_DB,
          });
          app.get('/health', (req, res) => res.json({ status: 'ok' }));
          app.get('/users', async (req, res) => {
            const { rows } = await pool.query('SELECT NOW() as time');
            res.json(rows);
          });
          app.listen(3000);
          SCRIPT
          node server.js
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: backend-config
        - secretRef:
            name: db-secret
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

```yaml
# 03-frontend.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  API_URL: http://backend.default.svc.cluster.local:3000
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: frontend-config
```

```yaml
# 04-ingress.yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

```yaml
# 05-rbac.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backend-role
rules:
- apiGroups: [""]
  resources: ["endpoints", "pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-rb
subjects:
- kind: ServiceAccount
  name: backend-sa
roleRef:
  kind: Role
  name: backend-role
  apiGroup: rbac.authorization.k8s.io
```

```bash
# Deploy the full stack
kubectl apply -f 01-db.yaml
kubectl apply -f 02-backend.yaml
kubectl apply -f 03-frontend.yaml
kubectl apply -f 04-ingress.yaml
kubectl apply -f 05-rbac.yaml

# Watch everything come up
kubectl get all

# Test the backend
kubectl run test --image=curlimages/curl --rm -it -- curl http://backend:3000/health

# Test via ingress
curl -H "Host: myapp.example.com" http://<ingress-ip>/api/health

# Clean up entire stack
kubectl delete -f 01-db.yaml -f 02-backend.yaml -f 03-frontend.yaml -f 04-ingress.yaml -f 05-rbac.yaml
```

---



---

[← Previous](15-15-command-reference.md) | [↑ Index](index.md) | [Next →](17-whats-coming-in-part-53.md)
