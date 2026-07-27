## 6. OOM Killer — Last Resort Defense

### How OOM Killer Selects Victims

When the system runs completely out of memory (and swap is full), the OOM Killer activates:

```bash
# View OOM scores for all processes
for pid in /proc/[0-9]*/oom_score; do
    echo "$(cat $pid) $(cat $(dirname $pid)/comm)"
done 2>/dev/null | sort -rn | head -10
# 999 java
# 850 postgres
# 600 nginx
# 400 sshd
# 200 init

# OOM score calculation:
# score = (RSS + page cache + swap) / total memory
# Higher score = more likely to be killed
# Processes with CAP_SYS_ADMIN get score 0 (protected)

# View OOM score for specific process
cat /proc/<PID>/oom_score
cat /proc/<PID>/oom_score_adj

# OOM killer log messages
dmesg | grep -i "oom\|out of memory\|killed"
# [123456.789] Out of memory: Killed process 12345 (java) total-vm:8192000kB,
#              anon-rss:4096000kB, file-rss:0kB, shmem-rss:0kB

# Disable OOM killer for specific process
echo -1000 | sudo tee /proc/<PID>/oom_score_adj    # -1000 = never kill

# Make process more likely to be killed
echo 1000 | sudo tee /proc/<PID>/oom_score_adj     # 1000 = kill first

# oom_score_adj range: -1000 to 1000
#   -1000: completely protected (init, kernel threads)
#        0: default (most processes)
#   +1000: first to be killed (test programs, expendable services)
```

### OOM Killer and cgroups

```bash
# cgroup v2: OOM control
# Create a cgroup for an application
sudo mkdir /sys/fs/cgroup/myapp

# Set memory limit for cgroup
echo 4G | sudo tee /sys/fs/cgroup/myapp/memory.max

# Set OOM group kill (kill entire cgroup, not just one process)
echo 1 | sudo tee /sys/fs/cgroup/myapp/memory.oom.group

# Control OOM behavior
echo 0 | sudo tee /sys/fs/cgroup/myapp/memory.oom.group
#   0 = kill single process in cgroup
#   1 = kill entire cgroup

# Disable OOM for cgroup (just fail the allocation)
echo -1 | sudo tee /sys/fs/cgroup/myapp/memory.oom.max

# Run a process in the cgroup
echo $$ | sudo tee /sys/fs/cgroup/myapp/cgroup.procs
./my_application

# Monitor cgroup memory usage
cat /sys/fs/cgroup/myapp/memory.current
cat /sys/fs/cgroup/myapp/memory.stat
```

### Preventing OOM Kills

```bash
# 1. Set memory limits (prevent runaway processes)
# Using systemd:
# [Service]
# MemoryMax=4G
# MemoryHigh=3G
# (MemoryHigh = soft limit, MemoryMax = hard limit triggers OOM)

# 2. Use cgroup memory limits
echo 4G | sudo tee /sys/fs/cgroup/myapp/memory.max

# 3. Reserve memory for critical processes
echo -1000 | sudo tee /proc/$(pgrep sshd)/oom_score_adj    # Protect SSH

# 4. Add swap as safety net
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile

# 5. Monitor memory pressure
sudo dmesg | grep -i "low memory\|oom\|killed"
```

> 🔍 **Reverse Engineering Insight:** The OOM Killer uses `oom_score_adj` to influence victim selection. Setting a process to -1000 doesn't prevent the OOM condition — it just protects that specific process. The only way to truly prevent OOM is to have enough memory (physical + swap) or to use cgroup limits that trigger allocation failures before OOM.

---



---

[← Previous](06-5-numa-topology-memory-where.md) | [↑ Index](index.md) | [Next →](08-7-memory-overcommit-the-kernels.md)
