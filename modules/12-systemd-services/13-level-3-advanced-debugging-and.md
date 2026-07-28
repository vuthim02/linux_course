## ⭐ Level 3: Advanced — Debugging and Deep Internals

> **Level 3 Goal:** Debug failed services, implement socket activation, manage resource limits with cgroups, and understand systemd's internals including the dependency graph, directory structure, journal binary format, and control groups.

### What You'll Cover
- Debugging failed services with `systemctl` and `journalctl`
- Socket activation for on-demand service startup
- Resource control with cgroups (CPU, memory, I/O limits)
- Systemd dependency graph and startup ordering

### Why This Level Matters

Level 3 separates the sysadmin who can restart a service from the one who can explain *why* it failed and prevent it from happening again. Debugging systemd services is not guesswork — it is a systematic process of reading status output, filtering journal logs, and tracing dependency chains.

Socket activation is one of systemd's most elegant features. Instead of starting a service at boot and wasting memory, systemd creates a socket and waits. The first connection triggers the service start. This is how many modern distributions handle SSH and other intermittent services.

### What You'll Practice

- Reading `systemctl show` output to trace dependency graphs
- Using `journalctl -u SERVICE -e --no-pager` to find the exact failure point
- Creating socket-activated services with `.socket` unit files
- Setting CPU quota, memory limits, and I/O weight with cgroup directives
- Interpreting `/sys/fs/cgroup/` to see resource allocation in real time

> ⚠️ Resource limits with cgroups are safety nets, not solutions. If a service needs more than 512MB of RAM, the answer is usually a code fix or architecture change, not a higher cgroup limit.





[← Previous](12-section-9-systemd-timers-modern.md) | [↑ Index](index.md) | [Next →](14-section-10-debugging-failed-services.md)
