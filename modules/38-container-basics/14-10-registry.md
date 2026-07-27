## 10. Registry

### Docker Hub

```bash
# Login
docker login
docker login -u username -p password

# Pull public image
docker pull nginx:latest

# Push to Docker Hub
docker tag myapp:latest username/myapp:latest
docker push username/myapp:latest

# Logout
docker logout
```

### Private Registry

```bash
# Run local registry
docker run -d -p 5000:5000 --name registry registry:2

# Push to local
docker tag myapp:latest localhost:5000/myapp:latest
docker push localhost:5000/myapp:latest

# Pull from local
docker pull localhost:5000/myapp:latest

# With TLS (self-signed)
docker run -d -p 5000:5000 \
  -v /certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  --name registry registry:2
```

### Insecure Registry

```json
// /etc/docker/daemon.json
{
  "insecure-registries": ["192.168.1.100:5000"]
}
```

```bash
sudo systemctl restart docker
```

### Harbor (Enterprise Registry)

```bash
# Harbor includes vulnerability scanning, replication, RBAC
# Download from https://github.com/goharbor/harbor
wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-offline-installer-v2.10.0.tgz
tar xzf harbor-offline-installer-*.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml
# Edit harbor.yml (hostname, password)
./install.sh
```

### Quay.io

Red Hat's registry — supports Clair vulnerability scanning, robot accounts, geo-replication.

### Container Registry Config

```toml
# /etc/containers/registries.conf (Podman)
[registries.search]
registries = ["docker.io", "quay.io"]

[registries.insecure]
registries = ["192.168.1.100:5000"]

[registries.block]
registries = []
```

---



---

[← Previous](13-9-networking.md) | [↑ Index](index.md) | [Next →](15-11-docker-compose.md)
