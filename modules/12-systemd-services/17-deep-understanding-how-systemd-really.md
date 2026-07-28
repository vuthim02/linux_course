## 🧠 Deep Understanding — How systemd Really Works

### The Dependency Graph

systemd doesn't run things in order. It builds a dependency graph:

```
                  multi-user.target
                 /        |         \
          network.target  |    sshd.service
               |          |         |
     NetworkManager   cron.service  |
               |                    |
   network-online.target     network.target (already satisfied)
```

systemd resolves this graph and starts everything in parallel where possible.

### The /etc/systemd/system/ Directory Structure

```bash
ls -la /etc/systemd/system/

# multi-user.target.wants/          ← services enabled for this target
# basic.target.wants/               ← services enabled for basic.target
# network-online.target.wants/      ← services for network readiness
# sockets.target.wants/             ← socket-activated services
# timers.target.wants/              ← timer units
# *.service.d/                      ← drop-in override directories
```

When you `systemctl enable nginx`, systemd creates a symlink:

```
/etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service
```

This is how "enable" works — it's just a symlink!

### The systemd Journal Binary Format

The journal is NOT text files. It's a binary format:

```bash
file /var/log/journal/*/system.journal
# Output: "system.journal: data"

# Advantages:
# - Structured fields (not just text)
# - Signed entries (tamper-evident)
# - Fast indexed search
# - Automatic log rotation

# To export as text to legacy syslog:
journalctl -o export > journal_export.txt
```

### Control Groups (cgroups)

systemd uses cgroups v2 to track and limit processes:

```bash
# Every service gets its own cgroup
ls /sys/fs/cgroup/system.slice/
# nginx.service  sshd.service  cron.service  ...

# Show cgroup of a service
systemctl show -p ControlGroup nginx

# The cgroup ensures:
# - When you stop a service, ALL its child processes die
# - Resource limits apply to the entire process tree
# - Clean accounting of CPU/memory/IO
```





[← Previous](16-section-12-resource-control-with.md) | [↑ Index](index.md) | [Next →](18-practice-section-15-hands-on-exercises.md)
