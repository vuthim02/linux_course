## 🔍 Section 5: Resource Agents

### OCF (Open Cluster Framework)

OCF scripts are the standard resource agents for Pacemaker. Located at `/usr/lib/ocf/resource.d/`.

```bash
# List available OCF providers
ls /usr/lib/ocf/resource.d/

# List agents for heartbeat provider
ls /usr/lib/ocf/resource.d/heartbeat/

# Get metadata for an agent
crm ra info ocf:heartbeat:IPaddr2

# List all agents
crm ra list ocf
```

**Common OCF agents:**

| Agent | Purpose |
|-------|---------|
| `IPaddr2` | Virtual IP address |
| `Filesystem` | Mount filesystem |
| `apache` | Apache httpd |
| `nginx` | Nginx web server |
| `postgresql` | PostgreSQL database |
| `pgsqlms` | PostgreSQL multi-state (master/slave) |
| `mysql` | MySQL/MariaDB |
| `Xen` | Xen virtual machine |
| `VirtualDomain` | libvirt/KVM VM |
| `LVM` | LVM volume group activation |
| `DRBD` | DRBD resource management |

### LSB (init.d) Scripts

Traditional init scripts work with Pacemaker via the `lsb` agent type:

```bash
crm configure primitive myapp lsb:myapp \
    op monitor interval=30s
```

Pacemaker calls `/etc/init.d/myapp start|stop|status`.

### systemd Resources

Systemd services can be managed directly:

```bash
crm configure primitive nginx systemd:nginx \
    op monitor interval=30s
```

### STONITH (Fence) Agents

```bash
# List fence agents
crm ra list stonith

# Get fence agent metadata
crm ra info stonith:fence_ipmilan
```

---



---

[← Previous](05-section-4-pacemaker-configuration.md) | [↑ Index](index.md) | [Next →](07-section-6-stonith-shoot-the.md)
