## 🔍 Section 16: Linux Capabilities — Fine-Grained Privileges

Capabilities break root's unlimited power into small, assignable units — a modern alternative to SUID.

### Why Capabilities?

```bash
# Old way: SUID binary (runs as root — too much power)
-rwsr-xr-x 1 root ping         # Ping runs as root

# Better: capability on binary (only needs raw socket)
# Instead of SUID, grant just CAP_NET_RAW
```

### Common Capabilities

| Capability | What It Allows |
|------------|----------------|
| `CAP_NET_BIND_SERVICE` | Bind to a privileged port (<1024) |
| `CAP_NET_RAW` | Use raw sockets (ping, traceroute) |
| `CAP_NET_ADMIN` | Network administration (iptables, routing) |
| `CAP_SYS_ADMIN` | Mount, swapon, etc. (powerful — avoid) |
| `CAP_DAC_OVERRIDE` | Bypass file permission checks |
| `CAP_CHOWN` | Change file ownership |

### Managing Capabilities

```bash
# View capabilities on a binary
getcap /usr/bin/ping
# /usr/bin/ping cap_net_raw=ep

# Set a capability (replace SUID)
sudo setcap cap_net_bind_service=+ep /usr/bin/myapp

# Remove capabilities
sudo setcap -r /usr/bin/myapp

# View running process capabilities
getpcaps 1234                   # PID 1234
# Or from /proc:
cat /proc/1234/status | grep Cap

# Decode capability bitmasks
capsh --decode=0000000000002000
```

### Security Best Practice

```bash
# Find all SUID binaries that could be converted to capabilities
find / -perm -4000 -type f 2>/dev/null

# Audit capabilities on your system
getcap -r / 2>/dev/null

# Containers: drop all capabilities, add only what's needed
# docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE ...
```



[← Previous](24-section-15-file-attributes-chattr.md) | [↑ Index](index.md) | [Next →](26-section-17-password-aging-and-account-lockout.md)
