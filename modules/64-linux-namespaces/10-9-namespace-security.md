## 9. Namespace Security

### Known Attack Vectors

```
┌─────────────────────────────────────────────────────────────────┐
│  NAMESPACE ESCAPE VECTORS                                        │
│                                                                  │
│  1. Kernel exploits (CVEs in namespace code)                    │
│     → CVE-2022-0185: heap overflow in legacy_parse_param        │
│     → CVE-2022-0492: cgroup escape via write                    │
│     → CVE-2024-1086: nf_tables privilege escalation             │
│                                                                  │
│  2. Misconfigured capabilities                                   │
│     → CAP_SYS_ADMIN allows mounting host filesystem             │
│     → CAP_SYS_PTRACE allows /proc inspection                    │
│     → CAP_NET_ADMIN allows network reconfiguration              │
│                                                                  │
│  3. Dangerous bind mounts                                        │
│     → /var/run/docker.sock: host Docker API access              │
│     → /proc/sysrq-trigger: kernel magic SysRq                   │
│     → /dev: device access escapes namespace                      │
│                                                                  │
│  4. User namespace escapes                                       │
│     → CVE-2021-3493: overlayfs user namespace bypass            │
│     → CVE-2022-25636: nf_tables double-free                    │
│                                                                  │
│  5. Container runtime bugs                                        │
│     → runc CVE-2019-5736: overwrite host runc binary            │
│     → CVE-2024-21626: runc container escape via /proc/self/fd   │
└─────────────────────────────────────────────────────────────────┘
```

### Hardening Checklist

```bash
# 1. Drop ALL capabilities, add only what's needed
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx

# 2. Never run as privileged
# BAD:  docker run --privileged ...
# GOOD: docker run --cap-drop=ALL --cap-add=... nginx

# 3. Use read-only rootfs
docker run --read-only --tmpfs /tmp:rw,noexec,nosuid nginx

# 4. Restrict syscalls with seccomp
docker run --security-opt seccomp=default-profile.json nginx

# 5. Use AppArmor or SELinux
docker run --security-opt apparmor=docker-default nginx

# 6. Limit resources
docker run --memory=256m --cpus=1 --pids-limit=100 nginx

# 7. No new privileges
docker run --security-opt no-new-privileges nginx

# 8. Use user namespaces (rootless Docker)
# In /etc/docker/daemon.json:
# { "userns-remap": "default" }

# 9. Drop seccomp with additional restrictions
# 10. Use minimal images (distroless, alpine, scratch)
```

### Securing Namespace Operations

```bash
# Limit who can create namespaces
# /etc/sysctl.conf:
# kernel.unprivileged_userns_clone = 0   ← disable unprivileged user NS
# user.max_user_namespaces = 0           ← disable user NS entirely

# If disabling user namespaces breaks rootless containers:
# user.max_user_namespaces = 28633      ← default

# Check current namespace limits
cat /proc/sys/user/max_user_namespaces
cat /proc/sys/user/max_pid_namespaces
cat /proc/sys/user/max_net_namespaces
cat /proc/sys/user/max_mnt_namespaces
cat /proc/sys/user/max_ipc_namespaces
cat /proc/sys/user/max_uts_namespaces

# Audit namespace creation
sudo auditctl -a always,exit -F arch=b64 -S clone -S unshare -k namespace_creation
sudo ausearch -k namespace_creation
```

### Detecting Container Escape

```bash
# Signs of namespace escape on host:
# 1. Unexpected processes in host PID namespace
ps aux | grep -v "\[" | grep -v systemd | grep -v bash

# 2. Unexpected network connections
ss -tlnp | grep -v -E "systemd|sshd|containerd"

# 3. Container process with host cgroup
cat /proc/<PID>/cgroup   # If root "/" — suspicious

# 4. Container with host PID namespace
ls -la /proc/<PID>/ns/pid  # Compare with host PID 1
readlink /proc/1/ns/pid     # Should differ from container PID

# 5. Unexpected mount points
cat /proc/<PID>/mountinfo | grep -v overlay | grep -v proc | grep -v sys

# 6. Container with CAP_SYS_ADMIN (dangerous)
capsh --decode=$(grep CapPrm /proc/<PID>/status | awk '{print $2}')

# 7. Use Falco for runtime detection
# falco --rule /etc/falco/rules.d/container-escape.yaml
```

> ⚠️ **Warning:** Namespaces alone are NOT security boundaries. The kernel is the security boundary. A kernel exploit can escape any namespace. Always combine namespaces with seccomp, AppArmor/SELinux, capability dropping, and minimal images for defense in depth.

---



---

[← Previous](09-8-container-internals.md) | [↑ Index](index.md) | [Next →](11-15-hands-on-practices.md)
