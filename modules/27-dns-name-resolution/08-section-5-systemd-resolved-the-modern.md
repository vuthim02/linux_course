## 🔍 Section 5: systemd-resolved — The Modern Stub Resolver

systemd-resolved is systemd's name resolution service. It acts as a local DNS stub resolver on `127.0.0.53`.

### Architecture

```
Application → getaddrinfo() → nsswitch.conf → libnss_resolve → systemd-resolved → Upstream DNS
                                                    ↕
                                             127.0.0.53 (stub)
```

When systemd-resolved is active:

1. `/etc/resolv.conf` is a symlink to `/run/systemd/resolve/stub-resolv.conf`
2. It points to `nameserver 127.0.0.53`
3. systemd-resolved listens on `127.0.0.53:53`
4. It forwards queries to upstream DNS servers (configured via DHCP or manual)

### Managing systemd-resolved

```bash
# Check if it's running
systemctl status systemd-resolved

# View current DNS configuration
resolvectl status

# Set DNS servers for a specific interface
sudo resolvectl dns eth0 8.8.8.8 1.1.1.1

# Set DNS servers globally (for all interfaces)
sudo resolvectl dns global 8.8.8.8

# Set search domain
sudo resolvectl domain eth0 example.com

# Flush cache
sudo resolvectl flush-caches

# Show cache statistics
resolvectl statistics

# Query via systemd-resolved (bypasses nsswitch)
resolvectl query google.com
```

### resolvectl status Example

```
Global
       Protocols: +LLMNR +mDNS -DNSOverTLS DNSSEC=no/unsupported
resolv.conf mode: stub

Link 2 (eth0)
  Current Scopes: DNS
       Protocols: +DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 192.168.1.1
       DNS Servers: 192.168.1.1 8.8.8.8
        DNS Domain: example.com
```

### Stub Resolver vs Direct

systemd-resolved provides two resolv.conf options:

```bash
# Symlink to stub resolver (127.0.0.53) — DEFAULT
ls -la /etc/resolv.conf
# /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf

# Direct upstream DNS (bypasses stub)
cat /run/systemd/resolve/resolv.conf
# This file lists the REAL upstream DNS servers

# Switch to direct upstream
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

### DNS over TLS (DoT)

```bash
# Enable DNS over TLS globally
sudo resolvectl dnssec default
sudo resolvectl tls-server-name global dns.google
sudo resolvectl dns global 8.8.8.8#dns.google 1.1.1.1#cloudflare-dns.com

# Enable on specific interface
sudo resolvectl dns eth0 1.1.1.1#cloudflare-dns.com
sudo resolvectl tls-server-name eth0 cloudflare-dns.com
```

### The 3 resolv.conf Files

```
/etc/resolv.conf                        → symlink to stub (127.0.0.53)
/run/systemd/resolve/stub-resolv.conf   → "nameserver 127.0.0.53"
/run/systemd/resolve/resolv.conf        → "nameserver 8.8.8.8" (real upstream)
```





[← Previous](07-section-4-etcnsswitchconf-name-service.md) | [↑ Index](index.md) | [Next →](09-section-6-dig-deep-dig.md)
