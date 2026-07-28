## 🔍 Section 12: Resource Control with systemd

systemd can limit CPU, memory, and I/O for services using control groups (cgroups).

```ini
[Service]
# CPU limits
CPUAccounting=yes
CPUQuota=50%               # Max 50% of one CPU

# Memory limits
MemoryAccounting=yes
MemoryMax=512M             # Max 512 MB memory
MemoryHigh=256M            # Memory throttle limit
MemoryLow=128M             # Memory guarantee

# I/O limits
IOAccounting=yes
IOWeight=100               # I/O priority (100-1000)

# Process limits
TasksMax=100               # Max number of tasks/threads

# File descriptor limits
LimitNOFILE=4096           # Max open files
LimitNPROC=100             # Max user processes
```

### Check Current Resource Usage

```bash
# Show resource usage for a service
systemctl show nginx -p MemoryCurrent
systemctl show nginx -p CPUUsageNSec

# Show cgroup
systemctl status nginx
# Look at the CGroup section
```





[← Previous](15-section-11-systemd-sockets-activation.md) | [↑ Index](index.md) | [Next →](17-deep-understanding-how-systemd-really.md)
