## 🎯 What You Will Achieve

- Understand what namespaces are, how they partition kernel resources, and their history
- Master PID namespaces: PID 1, orphan reaping, PID starvation, multi-level PID trees
- Configure Network namespaces: veth pairs, bridges, routing, and `ip netns`
- Work with Mount namespaces: chroot vs namespace, pivot_root, mount propagation
- Deploy UTS, IPC, and USER namespaces for hostname isolation, IPC separation, and unprivileged containers
- Understand cgroup namespaces and the v1 vs v2 resource controller landscape
- Use `unshare` and `nsenter` to create and enter namespaces from the command line
- Reverse-engineer how Docker and Podman build containers from namespaces + cgroups + seccomp
- Identify namespace escape vectors and harden container environments

---



---

[↑ Index](index.md) | [Next →](02-1-what-are-namespaces.md)
