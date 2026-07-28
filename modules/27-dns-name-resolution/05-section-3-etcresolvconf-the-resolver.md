## 🔍 Section 3: /etc/resolv.conf — The Resolver Configuration

This file tells the system which DNS servers to use and what search domains to apply.

### Basic Format

```bash
cat /etc/resolv.conf
```

```
nameserver 8.8.8.8
nameserver 1.1.1.1
search example.com prod.example.com
options timeout:2 attempts:3 rotate
```

| Directive | Purpose | Example |
|-----------|---------|---------|
| `nameserver` | DNS server to query (up to 3) | `8.8.8.8` |
| `search` | Domains to append to unqualified names | `example.com` |
| `options` | Tuning parameters | `timeout:2 attempts:3 rotate` |
| `domain` | Local domain name (replaces search) | `example.com` |
| `sortlist` | Prefer specific networks | `130.155.160.0/255.255.240.0` |

### Options Explained

```bash
# /etc/resolv.conf options:
options timeout:2          # Query timeout in seconds (default: 5)
options attempts:3         # Number of retries (default: 2)
options rotate             # Round-robin through nameservers
options single-request     # Use same socket for A and AAAA queries
options single-request-reopen  # Open new socket for each query type
options ndots:1            # Minimum dots before trying absolute query
options edns0              # Enable EDNS0 (larger UDP packets)
options trust-ad           # Trust AD (Authentic Data) bit
```

### How the Resolver Uses This

When you type `ping server`:

1. Resolver checks if `server` contains a dot
2. If no dot: tries `server` + each search domain (e.g., `server.example.com`, `server.prod.example.com`)
3. Each attempt queries nameservers in order (or rotated)
4. If `timeout` expires, tries next nameserver
5. After `attempts` tries, gives up

```bash
# Without search domain
nameserver 8.8.8.8
# "ping server" → fails (not a FQDN)

# With search domain
search example.com
# "ping server" → tries "server.example.com"
```

### How /etc/resolv.conf Gets Generated

This is where it gets interesting. `/etc/resolv.conf` is often managed by another service:

```bash
# Check who manages resolv.conf
ls -la /etc/resolv.conf
```

```
lrwxrwxrwx 1 root root 32 Jan 15 10:00 /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf
```

Three common scenarios:

**1. NetworkManager** — traditional (standalone file):
```
lrwxrwxrwx 1 root root 29 Jan 15 10:00 /etc/resolv.conf -> /run/NetworkManager/resolv.conf
```

**2. systemd-resolved** — stub resolver (most modern distros):
```
lrwxrwxrwx 1 root root 32 Jan 15 10:00 /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf
```
This points to `127.0.0.53` — systemd's local DNS stub.

**3. resolvconf** — legacy framework:
```
# /etc/resolv.conf is a regular file
# Managed by resolvconf package
```

**4. Manually managed** — static file (not recommended but works):
```bash
# Make it a real file (break the symlink)
sudo rm /etc/resolv.conf
sudo tee /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
```

### Debugging resolv.conf

```bash
# Who is providing DNS?
resolvectl status
# or
nmcli device show | grep DNS

# What does the resolver actually see?
cat /etc/resolv.conf

# What would systemd-resolved use?
cat /run/systemd/resolve/resolv.conf
```





[← Previous](04-section-2-etchosts-local-hostname.md) | [↑ Index](index.md) | [Next →](06-level-2-intermediary-resolution-configuration.md)
