## 🔍 Section 10: Troubleshooting Name Resolution

### Step 1: Is It a Local Problem?

```bash
# Can you reach the DNS server?
ping -c 1 8.8.8.8

# Is the DNS server answering?
dig @8.8.8.8 google.com

# Is DNS resolution working at all?
getent hosts google.com

# What does the resolver config say?
cat /etc/resolv.conf
```

### Step 2: Isolate the Layer

```bash
# Test glibc resolver (normal apps use this)
getent hosts google.com

# Test DNS directly (bypasses /etc/hosts and nsswitch)
dig google.com

# Test DNS over TCP (bypasses UDP issues)
dig +tcp google.com

# Test specific port
nc -zv 8.8.8.8 53
```

### Step 3: Debug with strace

```bash
# See every file the resolver opens
strace -e openat,connect,sendto,recvfrom getent hosts google.com 2>&1

# Key things to look for:
openat(AT_FDCWD, "/etc/nsswitch.conf"...)      ← checks order
openat(AT_FDCWD, "/etc/hosts"...)               ← checks local hosts
openat(AT_FDCWD, "/etc/resolv.conf"...)          ← reads DNS config
openat(AT_FDCWD, "/lib/libnss_files.so.2"...)   ← loads files module
openat(AT_FDCWD, "/lib/libnss_dns.so.2"...)     ← loads DNS module
sendto(3, "\x00\x01\x00\x00\x01\x00\x00\x00...") ← DNS query
recvfrom(3, ...)                                  ← DNS response
```

### Step 4: Check Specific Failure Modes

```bash
# DNS timeout — query takes too long
# Fix: Check firewall (port 53 UDP), check server reachability
time dig google.com   # If > 5 seconds, timeout

# SERVFAIL — server failure
# Fix: The upstream DNS server can't answer
dig google.com +tcp   # Maybe UDP response is blocked

# NXDOMAIN — domain doesn't exist
# Fix: Check your query for typos, check search domain
dig nonexistentdomain923874.com

# REFUSED — server refused query
# Fix: You're querying a server not configured for your query
dig @8.8.8.8 google.com AXFR  # Will be refused

# No answer — empty response
# Fix: The domain exists but no record of that type
dig google.com SOA  # Will work
dig google.com MX   # Will work (google has MX)
dig nonexistent.example.com TXT  # Might return empty
```

### Step 5: DNS Over TLS Troubleshooting

```bash
# Test DNS over TLS with systemd-resolved
resolvectl query google.com

# Check if DNS over TLS is working
resolvectl status | grep -i tls

# Test with kdig (from knot-dnsutils)
sudo apt install knot-dnsutils
kdig +tls @1.1.1.1 google.com

# Firewall check — DoT uses TCP 853
nc -zv 1.1.1.1 853
```

### Common Issues and Fixes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `ping google.com` fails, `ping 8.8.8.8` works | DNS resolution broken | Check `/etc/resolv.conf` |
| Some domains work, some don't | Search domain pollution | Clear search in resolv.conf |
| Random slow lookups | DNS server timeout | Add `options timeout:2` |
| `dig` works but `ping` doesn't | nsswitch or /etc/hosts issue | Check `/etc/nsswitch.conf` |
| "Temporary failure in name resolution" | No DNS server configured | Check resolver or service status |
| `.local` names not resolving | mDNS not configured | Install libnss-mdns, check avahi |
| Very slow resolution | IPv6 lookup failing | Add `options single-request-reopen` |

### The Ultimate Troubleshooting Script

```bash
#!/bin/bash
echo "=== DNS Troubleshooting Report ==="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo ""

echo "--- /etc/resolv.conf ---"
ls -la /etc/resolv.conf
cat /etc/resolv.conf
echo ""

echo "--- /etc/nsswitch.conf (hosts line) ---"
grep ^hosts /etc/nsswitch.conf
echo ""

echo "--- /etc/hosts (non-comment) ---"
grep -v '^#' /etc/hosts
echo ""

echo "--- DNS Server Reachability ---"
for ns in $(grep nameserver /etc/resolv.conf | awk '{print $2}'); do
    ping -c 1 -W 2 $ns > /dev/null 2>&1 && echo "$ns: reachable" || echo "$ns: UNREACHABLE"
    dig +short @$ns google.com > /dev/null 2>&1 && echo "$ns: answers queries" || echo "$ns: FAILS queries"
done
echo ""

echo "--- Test Resolutions ---"
for host in google.com kernel.org opencode.ai; do
    echo "$host -> $(dig +short $host | head -3)"
done
echo ""

echo "--- Reverse DNS ---"
getent hosts $(hostname -I | awk '{print $1}')
echo ""

echo "--- Resolver Statistics ---"
command -v resolvectl >/dev/null 2>&1 && resolvectl statistics || echo "resolvectl not available"
```





[← Previous](12-section-9-llmnr-link-local-multicast.md) | [↑ Index](index.md) | [Next →](14-level-3-advanced-resolution-internals.md)
