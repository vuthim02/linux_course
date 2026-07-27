## 🔍 Section 11: Keepalived + HAProxy Integration

### Architecture

```
                        ┌─ [ Backend 1 :80 ]
                        │
[VIP: 192.168.1.100] → HAProxy (active) ──┼─ [ Backend 2 :80 ]
                        │          Keepalived│
                        └─ [ Backend 3 :80 ]
                                  │
                    ┌─ HAProxy (standby)
                    │   Keepalived
```

### HAProxy Configuration

```haproxy
# /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    maxconn 4096
    user haproxy
    group haproxy

defaults
    log global
    mode http
    option httplog
    option dontlognull
    retries 3
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend web_front
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /health
    server web1 192.168.1.21:80 check inter 2000 rise 3 fall 3
    server web2 192.168.1.22:80 check inter 2000 rise 3 fall 3
    server web3 192.168.1.23:80 check inter 2000 rise 3 fall 3
```

### track_script — Health Monitoring

Keepalived can track a script's exit status:

```
vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight -20
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    ...
    track_script {
        chk_haproxy
    }
}
```

If HAProxy dies, `killall -0 haproxy` returns non-zero. After 3 failures (6s), the instance weight drops by 20. If the other node has a higher effective priority, it becomes master.

### Complete HAProxy + Keepalived Configuration

```
global_defs {
    router_id HA_PROXY
}

vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight -50
    fall 2
    rise 2
}

vrrp_instance VI_WEB {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 200
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass mypass123
    }
    virtual_ipaddress {
        192.168.1.100/24
    }
    track_script {
        chk_haproxy
    }
    notify_master "/etc/keepalived/scripts/start-haproxy.sh"
    notify_backup "/etc/keepalived/scripts/stop-haproxy.sh"
    notify_fault "/etc/keepalived/scripts/stop-haproxy.sh"
}
```

### Testing the Integration

```bash
# Simulate HAProxy failure on master
systemctl stop haproxy

# Watch failover
tail -f /var/log/keepalived.log

# Verify VIP moved
ip addr show eth0 | grep 192.168.1.100

# Restore
systemctl start haproxy
```

---



---

[← Previous](11-section-10-keepalived-vrrp.md) | [↑ Index](index.md) | [Next →](13-section-12-drbd-distributed-replicated.md)
