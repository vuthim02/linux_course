## 🔍 Section 12: Custom Hostname Resolution

### libnss-myhostname — Always Know Your Own Name

This module ensures the system's own hostname always resolves, even without `/etc/hosts` or DNS.

```bash
# Installed by default with systemd
# Library: /lib/x86_64-linux-gnu/libnss_myhostname.so.2

# /etc/nsswitch.conf line:
hosts: files dns myhostname

# What it resolves:
getent hosts $(hostname)         # Any hostname returned by hostname
getent hosts localhost           # 127.0.0.1 and ::1
getent hosts _gateway            # The default gateway IP
getent hosts _outbound           # Preferred outbound IP
```

This is why even if `/etc/hosts` is empty and DNS is down, `ping $(hostname)` still works.

### libnss-wins — Windows Internet Name Service

WINS is Microsoft's NetBIOS name resolution protocol.

```bash
# Install
sudo apt install libnss-wins

# /etc/nsswitch.conf
hosts: files wins dns

# Now the system can resolve NetBIOS names
# This requires a WINS server on the network
```

### libnss-mdns — Multicast DNS

```bash
# Install
sudo apt install libnss-mdns

# /etc/nsswitch.conf
hosts: files mdns_minimal [NOTFOUND=return] dns

# mdns_minimal only resolves .local
# Full mdns resolves any domain via multicast
```

### Custom NSS Modules

You can write custom NSS modules for:

- LDAP directories (`libnss-ldap`)
- Database-backed hostnames
- Container-hostname resolution
- Cloud metadata services

```bash
# Check all available NSS modules on your system
ls /lib/*/libnss_* 2>/dev/null || ls /lib/x86_64-linux-gnu/libnss_*
```

Typical output:
```
libnss_compat.so.2     libnss_dns.so.2       libnss_files.so.2
libnss_hesiod.so.2    libnss_ldap.so.2      libnss_mdns.so.2
libnss_myhostname.so.2 libnss_mymachines.so.2 libnss_resolve.so.2
libnss_systemd.so.2   libnss_wins.so.2
```

### Manual Name Resolution Scripts

Sometimes you need custom resolution logic. You can use `getaddrinfo` hooks:

```bash
# /etc/nsswitch.conf with a custom module:
hosts: files dns mycustom

# The custom module would be at:
# /lib/libnss_mycustom.so.2
```

For most admins, understanding and configuring the standard modules is sufficient.

---



---

[← Previous](15-section-11-etchostsallow-and-hostsdeny.md) | [↑ Index](index.md) | [Next →](17-15-hands-on-practices.md)
