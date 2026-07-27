## 14. Logging and Monitoring

### Default Log Driver

```bash
# Default: json-file — logs written as JSON to /var/lib/docker/containers/<id>/
docker logs web
```

### Log Drivers

```bash
# journald
docker run --log-driver journald nginx
journalctl -u docker CONTAINER_NAME=web

# syslog
docker run --log-driver syslog --log-opt syslog-address=udp://192.168.1.5:514 nginx

# fluentd
docker run --log-driver fluentd --log-opt fluentd-address=localhost:24224 nginx

# awslogs
docker run --log-driver awslogs --log-opt awslogs-group=my-group nginx

# gelf
docker run --log-driver gelf --log-opt gelf-address=udp://1.2.3.4:12201 nginx

# none
docker run --log-driver none nginx
```

### Log Rotation

```json
// /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
sudo systemctl restart docker
```

### Podman Logs

```bash
podman logs web
podman logs -f web
podman logs --tail 100 web
```

### docker stats

```bash
# Live resource usage
docker stats
docker stats web
docker stats web db api

# No stats streaming
docker stats --no-stream
```

### cAdvisor

```bash
docker run -d \
  --name=cadvisor \
  -p 8080:8080 \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  gcr.io/cadvisor/cadvisor:latest

# Open http://localhost:8080
```

---



---

[← Previous](17-13-security.md) | [↑ Index](index.md) | [Next →](19-level-3-advanced-practices-internals.md)
