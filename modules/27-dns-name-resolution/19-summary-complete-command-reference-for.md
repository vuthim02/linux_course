## 📋 Summary — Complete Command Reference for Part 27

### ⭐ Level 1 Commands: Basic DNS Queries and Files

| Command | Description |
|---------|-------------|
| `dig DOMAIN` | Standard DNS lookup |
| `dig +short DOMAIN` | Short, machine-friendly output |
| `dig +trace DOMAIN` | Follow full resolution chain |
| `dig @SERVER DOMAIN` | Query specific nameserver |
| `dig -x IP` | Reverse DNS lookup |
| `dig TYPE DOMAIN` | Query specific record type (MX, NS, TXT, etc.) |
| `host DOMAIN` | Simple DNS lookup |
| `host -t TYPE DOMAIN` | Query specific type |
| `nslookup DOMAIN` | Legacy interactive lookup |

| File | Purpose |
|------|---------|
| `/etc/hosts` | Static hostname-to-IP mappings |
| `/etc/resolv.conf` | DNS resolver configuration |

### ⭐ Level 2 Commands: Configuration, Caching, and Troubleshooting

**Name Service Switch**

| File / Command | Purpose |
|----------------|---------|
| `/etc/nsswitch.conf` | Name Service Switch order |
| `getent hosts NAME` | Resolve using nsswitch order |

**systemd-resolved**

| Command | Description |
|---------|-------------|
| `resolvectl status` | Show DNS configuration |
| `resolvectl query NAME` | Resolve via systemd-resolved |
| `resolvectl dns IFACE SERVER` | Set DNS server for interface |
| `resolvectl domain IFACE DOMAIN` | Set search domain |
| `resolvectl flush-caches` | Clear all DNS caches |
| `resolvectl statistics` | Cache and query statistics |
| `resolvectl llmnr global yes/no` | Enable/disable LLMNR |
| `resolvectl dnssec yes/no` | Enable/disable DNSSEC |

**Cache Management**

| Command | Description |
|---------|-------------|
| `sudo nscd -i hosts` | Flush nscd hosts cache |
| `sudo nscd -g` | Show nscd statistics |
| `sudo resolvectl flush-caches` | Flush systemd-resolved cache |
| `resolvectl statistics` | Show systemd-resolved stats |

**Troubleshooting**

| Command | Description |
|---------|-------------|
| `getent hosts NAME` | Resolve using nsswitch order |
| `ping -c 1 8.8.8.8` | Test network reachability |
| `nc -zv 8.8.8.8 53` | Test DNS port reachability |
| `tcpdump -i any port 53` | Capture DNS traffic |

### ⭐ Level 3 Commands: Advanced Debugging and Internals

| Command | Description |
|---------|-------------|
| `strace -e network getent hosts NAME` | Trace resolution system calls |
| `resolvectl dnssec yes/no` | Enable/disable DNSSEC |

| File | Purpose |
|------|---------|
| `/etc/hosts.allow` | TCP wrappers — allow rules |
| `/etc/hosts.deny` | TCP wrappers — deny rules |
| `/etc/mdns.allow` | mDNS service whitelist |





[← Previous](18-deep-understanding-how-dns-resolution.md) | [↑ Index](index.md) | [Next →](20-whats-coming-in-part-28.md)
