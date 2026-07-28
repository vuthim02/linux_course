## Self-Test

1. What is a Linux namespace and how does it differ from a virtual machine?
2. Which namespaces does `docker run` create by default?
3. Why must a process fork before entering a PID namespace?
4. What is PID 1's special responsibility in a PID namespace?
5. How does a veth pair work for container networking?
6. What is the difference between `chroot` and `pivot_root`?
7. Explain mount propagation types: private vs slave vs shared.
8. What does a USER namespace mapping of `0 100000 65536` mean?
9. What is the purpose of `/etc/subuid`?
10. How does the cgroup namespace differ between v1 and v2?
11. What command enters all namespaces of a running container?
12. What is the security risk of `docker run --privileged`?
13. Name three container escape CVEs and what they exploited.
14. Why is running a shell as PID 1 in a container problematic?
15. How does Docker implement `docker exec` internally?

**Answers:**
1. Namespace = kernel partitioning of global resources into isolated views; VMs use hardware virtualization (hypervisor), containers share the host kernel with resource isolation
2. All seven: PID, Network, Mount, UTS, IPC, User, Cgroup
3. PID namespace requires `CLONE_NEWPID` flag, which only works with `clone()` or `unshare()`; the calling process stays in the parent namespace; only the child enters the new PID namespace
4. PID 1 becomes the parent of all orphaned processes and must call `wait()` to reap zombies; if it doesn't, zombie processes accumulate
5. A veth pair creates two connected virtual network interfaces — packets entering one end exit the other; one end lives in the host, the other in the container namespace
6. `chroot` changes the apparent root directory but shares the mount table; `pivot_root` moves the root mount into a new mount namespace and can unmount the old root completely
7. Private = no propagation (changes invisible), Slave = one-way propagation (master → slave), Shared = bidirectional propagation (both see each other's mounts)
8. Inside the namespace, UID 0 maps to host UID 100000; a range of 65536 UIDs is available (0-65535 inside → 100000-165535 outside)
9. `/etc/subuid` defines subordinate UID ranges for users; tells the kernel which UID range a user can map in user namespaces (for rootless containers)
10. v1: separate hierarchies per controller (cpu, memory, blkio); v2: unified single tree with all controllers in one hierarchy; cgroup namespace hides the full tree, presenting the process's cgroup as root
11. `nsenter -t <PID> --all` enters all namespaces of the specified PID
12. `--privileged` grants ALL capabilities, access to all host devices, disables seccomp and AppArmor — effectively equivalent to root on the host
13. CVE-2019-5736 (runc binary overwrite), CVE-2022-0185 (heap overflow in legacy_parse_param), CVE-2024-21626 (runc /proc/self/fd escape)
14. Bash does not properly reap orphaned child processes; orphans become zombies in the PID namespace; use `tini` or `dumb-init` as PID 1 instead
15. Docker uses `nsenter -t <container_PID> --all` to enter the container's namespaces, then executes the specified command with the user's privileges within those namespaces

**Score:** 12/15 correct = ready for Part 65.


*Linux SysAdmin Course | Part 64 of ∞ | Reverse Engineering Approach*
*Previous → Part 63: eBPF & Modern Tracing*
*Next → Part 65: PAM & Centralized Authentication*

[← Previous](part63.md) | [Next →](part65.md)



[← Previous](14-whats-coming-in-part-65.md) | [↑ Index](index.md)
