## 🔍 Section 10: Keepalived + VRRP

### What Is VRRP?

**Virtual Router Redundancy Protocol (VRRP)** is a standard (RFC 5798) that lets multiple routers share a virtual IP. One is master, the rest are backup.

Keepalived implements VRRP for Linux.

### Installation

```bash
# Debian/Ubuntu
apt update && apt install -y keepalived

# RHEL/CentOS/Fedora
dnf install -y keepalived

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

### Configuration: /etc/keepalived/keepalived.conf

**Master node (node1):**

```
global_defs {
    notification_email {
        admin@example.com
    }
    notification_email_from keepalived@example.com
    smtp_server 127.0.0.1
    smtp_connect_timeout 30
    router_id LVS_MASTER
    vrrp_skip_check_adv_addr
    vrrp_strict
    vrrp_garp_interval 0
    vrrp_gna_interval 0
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 200
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass Sup3rS3cr3t
    }
    virtual_ipaddress {
        192.168.1.100/24 dev eth0 label eth0:vip
    }
}
```

**Backup node (node2):**

```
global_defs {
    router_id LVS_BACKUP
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass Sup3rS3cr3t
    }
    virtual_ipaddress {
        192.168.1.100/24 dev eth0 label eth0:vip
    }
}
```

### Key VRRP Parameters

| Parameter | Description |
|-----------|-------------|
| `state` | MASTER or BACKUP (determines startup role) |
| `virtual_router_id` | Unique VRID (0-255), must match on all nodes |
| `priority` | Higher = more likely to be master (0-255) |
| `advert_int` | Advertisement interval in seconds (default 1) |
| `auth_pass` | Simple password (max 8 chars in older versions) |
| `nopreempt` | Prevent preemption (non-preemptive mode) |
| `preempt_delay` | Delay before preempting (seconds) |

### Starting Keepalived

```bash
systemctl enable --now keepalived

# Check status
systemctl status keepalived

# Check VIP
ip addr show eth0

# Check logs
journalctl -u keepalived -f

# Test failover
systemctl stop keepalived  # VIP moves to backup
```

### How VRRP Works

1. **Master** sends VRRP multicast advertisements (`224.0.0.18`) every `advert_int` second
2. **Backup** listens for advertisements; if 3 × `advert_int` pass without hearing from master, it assumes master is dead
3. **Backup** transitions to MASTER and takes the VIP
4. **Gratuitous ARP** is sent to update switch ARP tables
5. When original master recovers, it sees a higher-priority master and stays BACKUP (or preempts if configured)

```
Normal state:
  [Client] → VIP (192.168.1.100) → Master (node1)
  
Master fails:
  [Client] → VIP (192.168.1.100) → Backup (node2)
  (transparent to client)

Master recovers:
  [Client] → VIP (192.168.1.100) → Master (node1) [with preemption]
  [Client] → VIP (192.168.1.100) → Backup (node2) [without preemption]
```

### Notify Scripts

```bash
vrrp_instance VI_1 {
    ...
    notify /etc/keepalived/notify.sh
    notify_master /etc/keepalived/master.sh
    notify_backup /etc/keepalived/backup.sh
    notify_fault /etc/keepalived/fault.sh
}
```

Example notify script:

```bash
#!/bin/bash
# /etc/keepalived/notify.sh
log_file="/var/log/keepalived-notify.log"

echo "$(date): State transition: $1 → $2 (VIP: $3)" >> $log_file

case "$2" in
    MASTER)
        systemctl start haproxy   # Start HAProxy when becoming master
        ;;
    BACKUP|FAULT)
        systemctl stop haproxy    # Stop HAProxy when backup
        ;;
esac
```





[← Previous](10-section-9-cluster-filesystems.md) | [↑ Index](index.md) | [Next →](12-section-11-keepalived-haproxy-integration.md)
