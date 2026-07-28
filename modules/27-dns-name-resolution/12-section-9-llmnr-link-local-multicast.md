## 🔍 Section 9: LLMNR — Link-Local Multicast Name Resolution

LLMNR (Link-Local Multicast Name Resolution) is a Microsoft protocol (RFC 4795) similar to mDNS. It resolves hostnames on the local network using multicast.

### How It's Different from mDNS

| Feature | mDNS | LLMNR |
|---------|------|-------|
| Standard | RFC 6762 | RFC 4795 |
| Port | 5353 | 5355 |
| Multicast address | 224.0.0.251 | 224.0.0.252 |
| Domain | `.local` only | Any single-label name |
| Used by | Apple, Linux (Avahi) | Windows, Linux (systemd) |
| Scope | Link-local | Link-local |

### Checking LLMNR Status

```bash
# systemd-resolved manages LLMNR
resolvectl status | grep LLMNR

# Enable/disable LLMNR
sudo resolvectl llmnr global yes
sudo resolvectl llmnr global no

# Check link status
resolvectl llmnr eth0
```

### How LLMNR Works

```
1. Host tries to resolve "server" via normal DNS → fails
2. Host sends LLMNR query to 224.0.0.252:5355
3. Host named "server" responds with its IP
4. Resolution succeeds without a DNS server
```

### systemd-resolved LLMNR Configuration

```
# /etc/systemd/resolved.conf
[Resolve]
LLMNR=yes          # Enable LLMNR (default: yes)
# LLMNR=resolve    # Only resolve, don't answer
# LLMNR=no         # Disable LLMNR
```





[← Previous](11-section-8-mdns-multicast-dns.md) | [↑ Index](index.md) | [Next →](13-section-10-troubleshooting-name-resolution.md)
