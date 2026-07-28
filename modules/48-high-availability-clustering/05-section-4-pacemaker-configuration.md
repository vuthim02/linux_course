## 🔍 Section 4: Pacemaker Configuration

### The crm Shell

Pacemaker management happens through the `crm` interactive shell or `pcs` (Red Hat style).

```bash
# Enter CRM shell
crm

# Interactive mode
crm(live) # configure
crm(live)configure # show
crm(live)configure # primitive webip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24
crm(live)configure # commit
crm(live)configure # exit
```

### Resources: Primitives, Groups, Clones, Multi-State

**Primitive** — a single resource:

```bash
crm configure primitive webip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
    op monitor interval=30s timeout=20s
```

**Group** — resources that must run together on the same node:

```bash
crm configure group webservice \
    webip \
    webserver \
    filesystem
```

**Clone** — a resource that runs on multiple nodes simultaneously:

```bash
crm configure clone cl-dlm dlm \
    meta clone-max=2 clone-node-max=2
```

**Multi-State (master/slave)** — a resource that runs as master on one node, slave on others:

```bash
crm configure ms ms-postgresql pgsqlms \
    meta master-max=1 master-node-max=1 \
    clone-max=2 clone-node-max=1 notify=true
```

### Constraints

**Colocation** — resources must run together (or apart):

```bash
# webip and webserver must be on the same node
crm configure colocation col-web inf: webip webserver

# Never run these on the same node
crm configure colocation col-anti neg: db1 db2
```

**Ordering** — resources must start in sequence:

```bash
# Start webip before webserver
crm configure order ord-web inf: webip webserver

# Stop in reverse order
crm configure order ord-web-stop inf: webserver webip
symmetrical=true
```

**Location** — prefer or avoid specific nodes:

```bash
# Prefer node1 for this resource
crm configure location loc-web webserver prefers node1=50

# Ban resource from node2
crm configure location loc-ban webserver rule -inf: #uname eq node2
```

### Resource Defaults

```bash
# Global resource defaults
crm configure rsc_defaults \
    resource-stickiness=100 \
    migration-threshold=3

# Global operation defaults
crm configure op_defaults \
    timeout=120s \
    record-pending=true
```

### Resource Operations

Each resource can define operations:

| Operation | Purpose |
|-----------|---------|
| `monitor` | Periodic health check |
| `start` | Start the resource |
| `stop` | Stop the resource |
| `reload` | Reload configuration |
| `migrate_to` / `migrate_from` | Live migration |

```bash
primitive webip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 \
    op start timeout=60s \
    op stop timeout=60s \
    op monitor interval=10s timeout=20s depth=0
```

### Viewing Cluster Status

```bash
# Summary
crm status

# Detailed
crm_mon -1 -r -f

# XML configuration
crm configure show

# Resource history
crm history

# Failcounts
crm resource failcount show
```





[← Previous](04-section-3-corosync-configuration.md) | [↑ Index](index.md) | [Next →](06-section-5-resource-agents.md)
