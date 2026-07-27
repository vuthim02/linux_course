## 🔍 Section 6: Kernel Parameters

### sysctl Overview

`sysctl` reads and writes kernel parameters at runtime through `/proc/sys/`.

```bash
# List all parameters
sudo sysctl -a | wc -l    # thousands of tunables

# Read a single parameter
sysctl net.ipv4.tcp_tw_reuse

# Write a parameter (runtime only, resets on reboot)
sudo sysctl vm.swappiness=10

# Make permanent
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Apply from config files
sudo sysctl -p              # /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.d/99-custom.conf
```

### Configuration File Layout

```
/etc/sysctl.conf              # Main config (legacy)
/etc/sysctl.d/                # Drop-in directory
  ├── 10-network-security.conf
  ├── 99-custom.conf
  └── README
/usr/lib/sysctl.d/            # Distribution defaults
```

Files are loaded in lexicographic order. Later values override earlier ones.

### Parameter Groups

| Group | Prefix | Examples |
|-------|--------|---------|
| Kernel | `kernel.*` | `kernel.pid_max`, `kernel.sched_migration_cost_ns`, `kernel.numa_balancing` |
| Virtual Memory | `vm.*` | `vm.swappiness`, `vm.dirty_ratio`, `vm.overcommit_memory`, `vm.nr_hugepages` |
| Network | `net.*` | `net.ipv4.tcp_rmem`, `net.core.rmem_max`, `net.ipv4.ip_forward` |
| Filesystem | `fs.*` | `fs.file-max`, `fs.inotify.max_user_watches`, `fs.aio-max-nr` |

### Applying Changes

```bash
# Immediate (but not persistent)
sudo sysctl -w vm.swappiness=10

# From a config file
sudo sysctl -p /etc/sysctl.d/custom.conf

# Reload all sysctl configs
sudo sysctl --system

# Check if change took effect
sysctl vm.swappiness
```

---



---

[← Previous](07-section-5-network-tuning.md) | [↑ Index](index.md) | [Next →](09-section-7-tuned-automated-performance.md)
