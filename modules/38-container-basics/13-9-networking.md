## 9. Networking

### Network Drivers

| Driver | Use Case | Scope |
|--------|----------|-------|
| **bridge** | Default — isolated network on host | Single host |
| **host** | No isolation — use host networking | Single host |
| **none** | No networking | Single host |
| **overlay** | Multi-host (Swarm) | Multi-host |
| **macvlan** | Assign MAC to container | Single host |
| **ipvlan** | Multiple IPs on same MAC | Single host |

### Bridge Network (Default)

```bash
# Default bridge — containers linked by IP
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# Get IP on default bridge
docker inspect web1 --format '{{.NetworkSettings.IPAddress}}'
# 172.17.0.2

# Communication between containers on default bridge (by IP only)
docker exec web2 ping 172.17.0.2
```

### User-Defined Bridge Network

```bash
# Create network
docker network create --driver bridge mynet

# Run containers on the same network
docker run -d --name web --network mynet nginx
docker run -d --name app --network mynet nginx

# DNS resolution by container name!
docker exec app ping web

# Add container to multiple networks
docker network connect mynet2 web
docker network disconnect mynet web

# List networks
docker network ls
docker network inspect mynet
```

### Host Network

```bash
# No isolation — container uses host's IP
docker run -d --network host nginx
# Now accessible on host's IP on port 80

# Useful for high-performance networking
# No port mapping needed
```

### None Network

```bash
# No network at all
docker run -d --network none nginx
# Only loopback interface
```

### Overlay Network (Docker Swarm)

```bash
# Requires Swarm mode
docker swarm init
docker network create --driver overlay --attachable myoverlay

# Create service on overlay network
docker service create --name web --network myoverlay --replicas 3 nginx
```

### Port Publishing

```bash
# Publish to random host port
docker run -d -P nginx

# Publish specific port
docker run -d -p 8080:80 nginx

# Publish to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx

# UDP port
docker run -d -p 53:53/udp dns

# Range
docker run -d -p 8000-8010:80 nginx
```

### DNS Configuration

```bash
# Custom DNS servers
docker run --dns 8.8.8.8 --dns 1.1.1.1 nginx

# Custom hosts entries
docker run --add-host db.local:10.0.0.5 nginx

# DNS search domain
docker run --dns-search example.com nginx
```

---



---

[← Previous](12-8-volumes-and-bind-mounts.md) | [↑ Index](index.md) | [Next →](14-10-registry.md)
