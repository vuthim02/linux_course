## 🔍 Section 4: /etc/nsswitch.conf — Name Service Switch

The Name Service Switch controls the order of resolution for various databases — not just hosts.

### The Big Picture

```
/etc/nsswitch.conf controls:
- hosts:    How hostnames → IP addresses
- passwd:   How user accounts are looked up (local files, LDAP, etc.)
- group:    How groups are looked up
- services: How port numbers map to service names
- networks: Network name resolution
- protocols: Protocol name resolution
```

### hosts Line

```bash
grep ^hosts /etc/nsswitch.conf
```

```
hosts:          files dns myhostname
```

Each "service" is a shared library loaded by glibc:

| Service | Library | What It Does |
|---------|---------|-------------|
| `files` | `libnss_files.so` | Reads `/etc/hosts` |
| `dns` | `libnss_dns.so` | Queries DNS via `/etc/resolv.conf` |
| `myhostname` | `libnss_myhostname.so` | Returns system's own hostname |
| `resolve` | `libnss_resolve.so` | Uses systemd-resolved's D-Bus API |
| `mdns` | `libnss_mdns.so` | Multicast DNS (Bonjour/Avahi) |
| `mdns_minimal` | `libnss_mdns.so` | mDNS only for `.local` |
| `wins` | `libnss_wins.so` | Windows Internet Name Service |

### Customizing the Order

```bash
# Check current configuration
cat /etc/nsswitch.conf

# Common variations:
hosts: files dns                       # Standard
hosts: files mdns_minimal [NOTFOUND=return] dns  # mDNS for .local first
hosts: dns files                       # DNS first, then hosts (unusual)
hosts: files resolve dns               # systemd-resolved D-Bus API
```

### The [NOTFOUND=return] Directive

```
hosts: files mdns_minimal [NOTFOUND=return] dns
```

This means: try `files` first, then `mdns_minimal`. If mdns returns "NOTFOUND" (name is not `.local` and won't be resolved), return immediately — don't try `dns`. This is a performance optimization.

### Real-World Configurations

```bash
# Ubuntu 22.04+ (systemd-resolved)
hosts:          files mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns

# This means:
# 1. Check /etc/hosts
# 2. Try mDNS for .local names
# 3. Try systemd-resolved D-Bus API
#    - If UNAVAIL (resolved not running), skip to DNS
#    - If available, use it and return
# 4. Fallback to traditional DNS
```

### Testing nsswitch Behavior

```bash
# getent uses nsswitch — shows the FULL resolution chain
getent hosts localhost        # From /etc/hosts
getent hosts google.com       # From DNS
getent hosts $(hostname)      # From myhostname

# strace shows which libraries are loaded
strace -e openat getent hosts google.com 2>&1 | grep nss
```

Output:
```
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libnss_files.so.2", ...) = 3
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libnss_dns.so.2", ...) = 3
```

---



---

[← Previous](06-level-2-intermediary-resolution-configuration.md) | [↑ Index](index.md) | [Next →](08-section-5-systemd-resolved-the-modern.md)
