## 8. ConfigMaps and Secrets

### ConfigMaps

ConfigMaps store non-sensitive configuration data as key-value pairs.

**Creation:**

```bash
# From literal values
kubectl create configmap app-config --from-literal=log.level=info --from-literal=app.name=microservice

# From files (each file becomes a key)
kubectl create configmap nginx-config --from-file=nginx.conf

# From .env file
kubectl create configmap app-config --from-env-file=.env
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  log.level: info
  app.name: microservice
  app.debug: "false"
  nginx.conf: |
    server {
      listen 80;
      server_name example.com;
      location / {
        proxy_pass http://backend:8080;
      }
    }
immutable: true    # prevent modification, improves performance
```

**Consumption — As environment variables:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log.level
    envFrom:
    - configMapRef:
        name: app-config
```

**Consumption — As a volume:**

```yaml
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    volumeMounts:
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
  volumes:
  - name: config
    configMap:
      name: nginx-config
```

### Secrets

Secrets store sensitive data (passwords, tokens, TLS certs, SSH keys). Values are base64-encoded in YAML (not encrypted by default — enable encryption at rest).

**Creation:**

```bash
# From literal values
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=s3cret

# From files
kubectl create secret generic tls-secret --from-file=tls.crt=server.crt --from-file=tls.key=server.key

# From .docker/config.json (for image pull secrets)
kubectl create secret docker-registry regcred --docker-server=registry.example.com --docker-username=tim --docker-password=token --docker-email=tim@example.com

# TLS secret
kubectl create secret tls app-tls --cert=app.crt --key=app.key
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: production
type: Opaque                   # default, arbitrary key-value
data:
  username: YWRtaW4=           # base64(admin)
  password: czNjcmV0           # base64(s3cret)
---
apiVersion: v1
kind: Secret
metadata:
  name: app-tls
  namespace: production
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTiBD...   # base64 of PEM
  tls.key: LS0tLS1CRUdJTiBS...
---
apiVersion: v1
kind: Secret
metadata:
  name: regcred
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6...   # base64 of Docker config JSON
```

**Consumption — As environment variables:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    envFrom:
    - secretRef:
        name: db-secret
```

**Consumption — As a volume:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: secrets
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secrets
    secret:
      secretName: db-secret
      defaultMode: 0400          # restrict permissions
```

**Image Pull Secrets — add to ServiceAccount:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: production
imagePullSecrets:
- name: regcred
```

**Immutable ConfigMaps and Secrets** (Kubernetes 1.21+):

```yaml
immutable: true
```

Immutable resources are not watched for changes (less API server load), and kubelet does not re-sync them. You must delete and recreate to change them.

---



---

[← Previous](07-7-services-and-networking.md) | [↑ Index](index.md) | [Next →](09-9-storage.md)
