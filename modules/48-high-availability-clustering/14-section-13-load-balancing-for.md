## 🔍 Section 13: Load Balancing for HA

### DNS Round-Robin

Simplest load balancing — multiple A records for one hostname:

```
web.example.com. IN A 192.168.1.10
web.example.com. IN A 192.168.1.11
web.example.com. IN A 192.168.1.12
```

**Problems:**
- No health checking — clients get dead server IPs
- DNS caching defeats rotation
- Uneven load distribution

### IPVS (LVS — Linux Virtual Server)

Kernel-level load balancing built into Linux:

```bash
# Install ipvsadm
dnf install -y ipvsadm

# Add virtual service
ipvsadm -A -t 192.168.1.100:80 -s rr

# Add real servers
ipvsadm -a -t 192.168.1.100:80 -r 192.168.1.21:80 -g  # direct routing
ipvsadm -a -t 192.168.1.100:80 -r 192.168.1.22:80 -g
ipvsadm -a -t 192.168.1.100:80 -r 192.168.1.23:80 -g

# View status
ipvsadm -L -n
```

Scheduling algorithms: `rr` (round-robin), `wrr` (weighted), `lc` (least connection), `wlc` (weighted LC), `sh` (source hashing).

### HAProxy

Layer 7 load balancer with health checks:

```haproxy
global
    maxconn 4096
    user haproxy
    group haproxy
    daemon

defaults
    mode tcp
    retries 3
    timeout connect 5s
    timeout client 30s
    timeout server 30s

frontend mysql_front
    bind *:3306
    default_backend mysql_back

backend mysql_back
    balance leastconn
    option mysql-check user haproxy_check
    server db1 192.168.1.31:3306 check
    server db2 192.168.1.32:3306 check backup
```

### Nginx Upstream

```nginx
upstream backend {
    server 192.168.1.21 weight=3;
    server 192.168.1.22;
    server 192.168.1.23 backup;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Active-Active vs Active-Passive

| Aspect | Active-Active | Active-Passive |
|--------|--------------|----------------|
| All nodes serve? | Yes | No (one standby) |
| Resource utilization | High | Low (wasted capacity) |
| Failover | Instant (other node already serving) | 10-60s |
| Complexity | Higher (session state, data sync) | Lower |
| Cost | Lower per-request (no idle hardware) | Higher (idle hardware) |





[← Previous](13-section-12-drbd-distributed-replicated.md) | [↑ Index](index.md) | [Next →](15-section-14-disaster-recovery.md)
