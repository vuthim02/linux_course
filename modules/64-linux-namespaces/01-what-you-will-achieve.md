## 🎯 What You Will Achieve

Containers are not magic — they are built from Linux kernel primitives: namespaces for isolation, cgroups for resource limits, and seccomp for syscall filtering. This part strips away the Docker abstraction and shows you exactly how containers work under the hood.

You will:

- Understand what namespaces are, how they partition kernel resources, and their history
- Master PID namespaces: PID 1, orphan reaping, PID starvation, multi-level PID trees
- Configure Network namespaces: veth pairs, bridges, routing, and `ip netns`
- Work with Mount namespaces: chroot vs namespace, pivot_root, mount propagation
- Deploy UTS, IPC, and USER namespaces for hostname isolation, IPC separation, and unprivileged containers
- Understand cgroup namespaces and the v1 vs v2 resource controller landscape
- Use `unshare` and `nsenter` to create and enter namespaces from the command line
- Reverse-engineer how Docker and Podman build containers from namespaces + cgroups + seccomp
- Identify namespace escape vectors and harden container environments





[↑ Index](index.md) | [Next →](02-1-what-are-namespaces.md)
