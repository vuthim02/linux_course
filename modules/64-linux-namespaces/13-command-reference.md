## Command Reference

| Task | Command |
|------|---------|
| List namespaces of a process | `ls -la /proc/<PID>/ns/` |
| List all namespaces on system | `lsns` |
| List namespaces by type | `lsns -t pid` / `lsns -t net` |
| Compare two process namespaces | `readlink /proc/<PID1>/ns/pid /proc/<PID2>/ns/pid` |
| Create PID namespace | `unshare --pid --fork --mount-proc bash` |
| Create network namespace | `ip netns add <name>` |
| Execute in namespace | `ip netns exec <name> <cmd>` |
| Enter all namespaces of process | `nsenter -t <PID> --all` |
| Enter specific namespace | `nsenter -t <PID> -n -m -p bash` |
| Create veth pair | `ip link add <a> type veth peer name <b>` |
| Create bridge | `ip link add <name> type bridge` |
| Set namespace hostname | `hostname <name>` (inside UTS NS) |
| Create user namespace | `unshare --user --map-root-user bash` |
| View user namespace mapping | `cat /proc/<PID>/uid_map` |
| Create cgroup v2 | `mkdir /sys/fs/cgroup/<name>` |
| Set memory limit | `echo <bytes> > /sys/fs/cgroup/<name>/memory.max` |
| Set CPU limit | `echo "<quota> <period>" > /sys/fs/cgroup/<name>/cpu.max` |
| Move process to cgroup | `echo <PID> > /sys/fs/cgroup/<name>/cgroup.procs` |
| View mount propagation | `cat /proc/self/mountinfo \| grep shared` |
| List all PID namespaces | `lsns -t pid` |
| View namespace limits | `cat /proc/sys/user/max_*_namespaces` |
| Container namespace info | `docker inspect --format '{{.State.Pid}}' <container>` |
| Decode capabilities | `capsh --decode=<hex>` |

---



---

[← Previous](12-deep-understanding.md) | [↑ Index](index.md) | [Next →](14-whats-coming-in-part-65.md)
