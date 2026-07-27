# 🐧 Linux System Administrator — Complete Course
## Part 27 of ∞: DNS and Name Resolution — /etc/hosts, resolv.conf, nsswitch, dig

---

> **Reverse Engineering Approach:** DNS is the phonebook of the internet. When you type `google.com`, your system doesn't magically know where to go — it asks a chain of servers, each referring to the next, until it gets an IP address. But before DNS even gets involved, your system checks local files, caches, and configured overrides. Understanding every link in that resolution chain — from `/etc/hosts` to the root DNS servers — is what lets you diagnose why a hostname resolves on one machine but not another, why `curl` works but `ping` doesn't, and how to control name resolution at every level.

---

## 🎯 What You Will Achieve in Part 27

| Level | Focus | Skills Gained |
|-------|-------|--------------|
| **⭐ Level 1: Basic** | DNS Fundamentals | Understand the DNS hierarchy, `/etc/hosts`, `/etc/resolv.conf`, and basic query tools |
| **⭐ Level 2: Intermediary** | Resolution Configuration & Caching | Master nsswitch, systemd-resolved, dig/host/nslookup, caching (nscd/Unbound), mDNS, LLMNR, and troubleshooting |
| **⭐ Level 3: Advanced** | Resolution Internals & Custom Modules | Understand TCP wrappers, custom hostname resolution modules, glibc resolver internals, and deep strace-based debugging |

Complete **15 hands-on practices** across all levels.

---

## ⭐ Level 1: Basic — DNS Fundamentals and Local Resolution

![DNS Hierarchy](https://i.pinimg.com/1200x/1f/a3/d5/1fa3d5244b3534b414dc5b75a9e11685.jpg)  
*The DNS hierarchy — root servers, TLDs, and authoritative nameservers. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand the DNS hierarchy and how domain names are resolved. Master `/etc/hosts` for local overrides and decode `/etc/resolv.conf` for resolver configuration.

## 🔍 Section 1: What Is DNS?

The Domain Name System (DNS) is the distributed directory that maps human-readable hostnames to machine-readable IP addresses.

### The Hierarchy

DNS is not a single database — it's a tree:

```
. (root)
├── com. (TLD)
│   ├── google.com.  (authoritative)
│   ├── github.com.  (authoritative)
│   └── example.com. (authoritative)
├── org. (TLD)
│   ├── wikipedia.org.
│   └── kernel.org.
├── net. (TLD)
├── uk. (country-code TLD)
├── de.
└── io.
```

Each level delegates authority to the next:

| Level | Who Runs It | Example |
|-------|-------------|---------|
| Root (`.`) | 13 root server operators (a.root-servers.net through m.root-servers.net) | 198.41.0.4 |
| TLD (`.com`, `.org`) | Registry operators (Verisign, PIR, etc.) | a.gtld-servers.net |
| Authoritative | Domain owner or DNS provider | ns1.google.com |
| Recursive Resolver | ISP, Google (8.8.8.8), Cloudflare (1.1.1.1) | 8.8.8.8 |

### Resolution Process — Step by Step

```
Query: What is the IP of www.example.com?

Step 1: Client asks local resolver (e.g., 8.8.8.8)
Step 2: Resolver asks root server: "Who manages .com?"
Step 3: Root server replies: "Ask a.gtld-servers.net"
Step 4: Resolver asks TLD server: "Who manages example.com?"
Step 5: TLD server replies: "Ask ns1.example.com"
Step 6: Resolver asks authoritative server: "What is www.example.com?"
Step 7: Authoritative server replies: "93.184.216.34"
Step 8: Resolver returns answer to client
```

```bash
# Trace this live with dig
dig +trace www.example.com
```

Output (abbreviated):
```
; <<>> DiG 9.18.19 <<>> +trace www.example.com
;; global options: +cmd
.            517796  IN  NS  m.root-servers.net.
.            517796  IN  NS  a.root-servers.net.
;; Received 262 bytes from 8.8.8.8#53(8.8.8.8) in 4 ms

com.            172800  IN  NS  a.gtld-servers.net.
com.            172800  IN  NS  b.gtld-servers.net.
;; Received 1182 bytes from 198.41.0.4#53(a.root-servers.net) in 12 ms

example.com.        172800  IN  NS  a.iana-servers.net.
example.com.        172800  IN  NS  b.iana-servers.net.
;; Received 410 bytes from 192.5.6.30#53(a.gtld-servers.net) in 16 ms

www.example.com.    86400   IN  A   93.184.216.34
;; Received 64 bytes from 199.43.0.53#53(b.iana-servers.net) in 20 ms
```

### Recursive vs Iterative Resolution

**Iterative:** The server responds with the best answer it already knows (referral). The client must follow the chain. This is what `dig +trace` does manually.

**Recursive:** The server does all the work — it follows referrals on behalf of the client. Your ISP's resolver (or 8.8.8.8) is a recursive resolver. The client makes one query and gets the final answer.

```
Client → Recursive Resolver (does all the work) → Root → TLD → Authoritative
                                                      ↓
Client ← Final answer ← Recursive Resolver ←←←←←←←←←←←
```

### Record Types

| Type | Full Name | Purpose | Example |
|------|-----------|---------|---------|
| A | Address record | Maps hostname to IPv4 | 93.184.216.34 |
| AAAA | IPv6 Address record | Maps hostname to IPv6 | 2606:2800:220:1:248:1893:25c8:1946 |
| CNAME | Canonical Name | Alias (one name → another name) | www → example.com |
| MX | Mail Exchange | Mail server for domain | mail.example.com |
| TXT | Text record | Arbitrary text (SPF, DKIM, verification) | "v=spf1 mx ~all" |
| NS | Nameserver | Authoritative nameserver | ns1.example.com |
| SOA | Start of Authority | Zone metadata (serial, refresh, retry) | — |
| PTR | Pointer record | Reverse DNS (IP → hostname) | 34.216.184.93.in-addr.arpa |

```bash
# Query each record type
dig A google.com
dig AAAA google.com
dig MX google.com
dig NS google.com
dig TXT google.com
dig SOA google.com

# Short form (just the answer)
dig +short A google.com
dig +short MX google.com

# Specific nameserver query
dig @8.8.8.8 google.com
```

---

## 🔍 Section 2: /etc/hosts — Local Hostname Resolution

Before DNS existed, there was `/etc/hosts`. It's still the first place your system looks — if you define a hostname here, DNS is never consulted.

### Format

```
127.0.0.1    localhost
127.0.1.1    my-computer
192.168.1.10 server1.example.com server1
::1          localhost ip6-localhost ip6-loopback
```

Each line:
```
IP_address    canonical_hostname  [aliases...]
```

### Resolution Precedence

The order of resolution is controlled by `/etc/nsswitch.conf` (covered in Section 4). By default:

```
hosts: files dns myhostname
        ↑      ↑       ↑
    1st   2nd    3rd
```

1. **files** = check `/etc/hosts` first
2. **dns** = query DNS servers
3. **myhostname** = check own hostname

This means `/etc/hosts` ALWAYS wins over DNS.

### Practical Uses

```bash
# Block a domain (redirect to localhost)
echo "127.0.0.1    doubleclick.net" | sudo tee -a /etc/hosts

# Local development overrides
echo "127.0.0.1    myapp.local" | sudo tee -a /etc/hosts

# Map a LAN server (faster than DNS lookup)
echo "192.168.1.5   nas.local" | sudo tee -a /etc/hosts
```

### Testing Resolution Order

```bash
# Add a fake entry
echo "1.2.3.4    testoverride.com" | sudo tee -a /etc/hosts

# Dig will show NO override (bypasses /etc/hosts!)
dig +short testoverride.com   # Shows real IP from DNS

# But getent (glibc resolver) WILL show override
getent hosts testoverride.com  # Shows 1.2.3.4

# ping and curl also use glibc resolver
ping -c 1 testoverride.com     # Will ping 1.2.3.4
```

This is the critical distinction: **dig bypasses `/etc/hosts`** because it queries DNS servers directly. Normal applications use `getaddrinfo()` which checks `/etc/hosts` first.

### The Hosts File in Containers

In Docker containers, `/etc/hosts` is managed by Docker and includes the container's own hostname:

```bash
docker run --hostname mycontainer alpine cat /etc/hosts
# 127.0.0.1   localhost
# ::1         localhost ip6-localhost ip6-loopback
# 172.17.0.2  mycontainer
```

---

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

---

## ⭐ Level 2: Intermediary — Resolution Configuration and Caching

![dig command output](https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Dig_command_output.png/220px-Dig_command_output.png)  
*Querying DNS with dig — the sysadmin's primary DNS tool. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Control resolution order with nsswitch.conf. Master dig, host, and nslookup for all record types. Configure systemd-resolved, DNS caching (nscd/Unbound), mDNS, and LLMNR. Troubleshoot complex resolution failures.

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

---

## 🔍 Section 6: Dig Deep — dig, host, nslookup

### dig — Domain Information Groper

`dig` is THE DNS troubleshooting tool. It queries DNS servers directly and shows every detail.

```bash
# Basic query
dig google.com

# Short answer only
dig +short google.com

# Specific record type
dig MX google.com
dig NS google.com
dig TXT google.com
dig SOA google.com
dig AAAA google.com

# Query a specific nameserver
dig @8.8.8.8 google.com
dig @1.1.1.1 google.com

# Query a specific port (non-standard)
dig @8.8.8.8 -p 53 google.com
```

### Understanding dig Output

```
; <<>> DiG 9.18.19 <<>> google.com         ← Version and query
;; global options: +cmd                     
;; Got answer:                              ← Response received
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345  ← Response header
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1  ← Flags

;; OPT PSEUDOSECTION:                       ← EDNS options
; EDNS: version: 0, flags:; udp: 512

;; QUESTION SECTION:                        ← What was asked
;google.com.            IN      A

;; ANSWER SECTION:                          ← The answer
google.com.         164     IN      A       142.250.80.14

;; AUTHORITY SECTION:                       ← Name servers (if no answer)
google.com.         24413   IN      NS      ns2.google.com.
google.com.         24413   IN      NS      ns1.google.com.

;; ADDITIONAL SECTION:                      ← Extra info (IPs of NS)
ns1.google.com.     24413   IN      A       216.239.32.10

;; Query time: 12 msec                      ← Performance data
;; SERVER: 8.8.8.8#53(8.8.8.8)             ← Who answered
;; WHEN: Wed Jun 24 10:00:00 UTC 2026      ← Timestamp
;; MSG SIZE  rcvd: 164                      ← Packet size
```

### dig +trace — Follow the Chain

```bash
dig +trace www.example.com
```

Shows every step: root → TLD → authoritative → answer.

### dig +short — Machine-Friendly

```bash
# Just the IP
dig +short google.com
# 142.250.80.14

# All IPs (multiple A records)
dig +short google.com A

# MX records (just priority and hostname)
dig +short MX google.com
# 10 smtp.google.com
```

### Reverse DNS Lookups

```bash
# Find hostname for an IP
dig -x 8.8.8.8
# Or
dig PTR 8.8.8.8.in-addr.arpa

dig +short -x 8.8.8.8
# dns.google.
```

### Advanced dig Tricks

```bash
# Query ANY type
dig ANY google.com   # Returns all records (some resolvers ignore ANY)

# Show only specific sections
dig +nocomment +noquestion +noauthority +noadditional +nostats google.com

# Trace with specific root server
dig @a.root-servers.net +trace google.com

# Check zone transfer (usually blocked)
dig @ns1.google.com google.com AXFR

# Query with TCP (bypass UDP limitations)
dig +tcp google.com

# Show the raw DNS packet
dig +dnssec google.com

# Check DNSSEC
dig google.com +dnssec +multiline

# Batch queries from file
dig -f domains.txt +short
```

### host — Simpler, Faster

```bash
# Basic lookup
host google.com

# Specific type
host -t MX google.com
host -t NS google.com
host -t SOA google.com

# Reverse lookup
host 8.8.8.8

# Specific server
host google.com 8.8.8.8

# Verbose
host -v google.com
```

### nslookup — The Legacy Tool

```bash
# Interactive mode
nslookup
> server 8.8.8.8
> set type=MX
> google.com
> exit

# One-shot
nslookup google.com
nslookup -type=MX google.com
nslookup google.com 8.8.8.8
```

### Comparison

| Feature | dig | host | nslookup |
|---------|-----|------|----------|
| Detail level | Maximum | Medium | Medium |
| Parseable output | Yes (+short) | Yes | No (legacy) |
| +trace | Yes | No | No |
| EDNS/DNSSEC | Full | Basic | Basic |
| Batch queries | Yes (-f) | No | No |
| Scripting | Excellent | Good | Poor |

---

## 🔍 Section 7: DNS Caching

Every DNS query takes time. Caching avoids repeated lookups.

### How Caching Works

```
TTL (Time To Live) — how long a record can be cached
google.com A 300 → cache for 300 seconds

Timeline:
t=0:  Query google.com → server responds with TTL=300
t=10: Query google.com → answered from cache (290s remaining)
t=310: Cache expires → new query to upstream
```

### nscd — Name Service Cache Daemon

The traditional caching daemon for glibc.

```bash
# Install
sudo apt install nscd     # Debian/Ubuntu
sudo dnf install nscd     # RHEL/Fedora

# Start and enable
sudo systemctl enable --now nscd

# Check status
sudo systemctl status nscd

# Configuration
cat /etc/nscd.conf
```

```
# /etc/nscd.conf
enable-cache            hosts           yes
positive-time-to-live   hosts           3600
negative-time-to-live   hosts           20
suggested-size          hosts           211
check-files             hosts           yes
persistent              hosts           yes
shared                  hosts           yes
```

```bash
# Invalidate cache
sudo nscd -i hosts

# Statistics
sudo nscd -g

# Test: first lookup is slow, cache makes it instant
time getent hosts google.com
time getent hosts google.com
```

### systemd-resolved Caching

systemd-resolved includes built-in caching:

```bash
# Check cache statistics
resolvectl statistics

# Flush cache
sudo resolvectl flush-caches

# Verify
resolvectl statistics | grep -i cache
```

### Unbound — Full DNS Resolver

Unbound is a validating, recursive, caching DNS resolver. It acts as a local DNS server that does full resolution.

```bash
# Install
sudo apt install unbound     # Debian/Ubuntu
sudo dnf install unbound     # RHEL/Fedora

# Basic configuration
sudo tee /etc/unbound/unbound.conf.d/local.conf << 'EOF'
server:
    interface: 127.0.0.1
    port: 53
    access-control: 127.0.0.0/8 allow
    do-daemonize: yes
    prefetch: yes
    cache-min-ttl: 3600
    cache-max-ttl: 86400
EOF

# Start
sudo systemctl enable --now unbound

# Now use localhost as DNS
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf

# Query — first is slow (recursive), then fast (cached)
dig @127.0.0.1 google.com
time dig @127.0.0.1 google.com
time dig @127.0.0.1 google.com
```

### Cache Comparison

| Cache | Scope | Persistence | Negative Caching |
|-------|-------|-------------|------------------|
| nscd | All glibc queries | Configurable | Yes (20s default) |
| systemd-resolved | Systemd-managed hosts | Runtime only | Yes |
| Unbound | Full recursive resolver | Optional | Yes |

### Prefetching

Unbound can refresh entries before they expire:

```
prefetch: yes   # Refresh when TTL is 10% of original
```

This means popular domains never expire from cache.

---

## 🔍 Section 8: mDNS — Multicast DNS

mDNS (Multicast DNS) lets devices resolve `.local` hostnames without a DNS server. It's used by Apple Bonjour, Avahi (Linux), and many IoT devices.

### How It Works

```
1. Host "printer.local" sends a multicast query to 224.0.0.251:5353
2. The device named "printer" receives it and answers with its IP
3. No DNS server needed — all on the local network
```

### Avahi — The Linux mDNS Implementation

```bash
# Install
sudo apt install avahi-daemon avahi-utils

# Check if running
sudo systemctl status avahi-daemon

# Browse services on the network
avahi-browse -a -t

# Browse specific service type
avahi-browse _http._tcp

# Resolve a service
avahi-resolve-hostname printer.local

# Publish a service (advertise this machine)
avahi-publish-service myservice _http._tcp 80
```

### Configuring mDNS Resolution

```bash
# /etc/nsswitch.conf — enable mDNS for .local
hosts: files mdns_minimal [NOTFOUND=return] dns

# The mdns_minimal module only handles .local
# Install the nss-mdns package:
sudo apt install libnss-mdns
```

### /etc/mdns.allow

The `mdns` (not minimal) module has a whitelist:

```
# /etc/mdns.allow
.local.       # Allow all .local names
.example.com. # Also allow example.com via mDNS
```

Without this file, `mdns_minimal` only responds to `.local`.

### Testing mDNS

```bash
# Ping a .local hostname
ping myraspberrypi.local

# Resolve via avahi
avahi-resolve-hostname -4 myraspberrypi.local

# Discover all mDNS services on network
avahi-browse -a -t -r
```

### mDNS TTL and Caching

mDNS records have low TTLs (typically 120 seconds) because local network devices come and go.

---

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

---

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

---

## ⭐ Level 3: Advanced — Resolution Internals and Custom Modules

![Linux Network Stack](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Network_Stack.svg/220px-Network_Stack.svg.png)  
*The glibc resolver — connecting applications to the DNS. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Understand TCP wrappers (hosts.allow/hosts.deny) and the libwrap mechanism. Configure custom hostname resolution modules. Trace the complete resolution chain from application to wire using strace and glibc internals.

## 🔍 Section 11: /etc/hosts.allow and hosts.deny — TCP Wrappers

TCP wrappers (tcpd) is a legacy host-based access control system. It wraps network services to allow or deny connections based on client hostname or IP.

### How TCP Wrappers Work

```
Client connects → inetd/xinetd or tcpd wrapper → checks /etc/hosts.allow → checks /etc/hosts.deny → grants or denies
```

### Format

```
# /etc/hosts.allow
service_list : client_list [: shell_command]

# /etc/hosts.deny
service_list : client_list [: shell_command]
```

### Rules

1. If a rule matches in `hosts.allow` → connection ALLOWED
2. If a rule matches in `hosts.deny` → connection DENIED
3. If neither matches → connection ALLOWED (default)

```bash
# /etc/hosts.allow — allow specific services/hosts
sshd: 192.168.1.0/255.255.255.0
sshd: 10.0.0.0/255.0.0.0
vsftpd: .example.com        # Allow all .example.com hosts

# /etc/hosts.deny — deny everything else
ALL: ALL                     # Default deny for everything
```

### Paranoid Configuration

```bash
# /etc/hosts.deny
ALL: ALL

# /etc/hosts.allow
sshd: 192.168.0.0/16 10.0.0.0/8
```

This denies everything EXCEPT SSH from private networks.

### Checking If a Service Uses TCP Wrappers

```bash
# Check if the binary is linked to libwrap
ldd /usr/sbin/sshd | grep libwrap     # If output: yes, uses wrappers
ldd /usr/sbin/vsftpd | grep libwrap   # Most modern binaries don't

# On modern systems, most services use their own ACLs or firewalls
# TCP wrappers are largely replaced by nftables/iptables
```

### hosts_options — Extended Syntax

```bash
# /etc/hosts.allow (with twist/bark)
sshd: 192.168.1.0/24 : deny           # Explicit deny within allow file
sshd: .evil.com : twist /bin/echo "Connection from %c rejected"
```

### Limitations

- Only works with services compiled against `libwrap`
- Hostname-based rules require reverse DNS (can be spoofed)
- Modern systems use firewalls instead (nftables, ufw, firewalld)
- Most distributions no longer compile services with libwrap

### Checking Current Status

```bash
# Do the files exist?
ls -la /etc/hosts.allow /etc/hosts.deny

# On modern systems, they often look like:
cat /etc/hosts.allow
# ALL: ALL  (or empty with comments)
cat /etc/hosts.deny
# ALL: ALL  (or empty)
```

---

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

## 🛠️ 15 Hands-On Practices

---

### 📘 Level 1 Practices: DNS Fundamentals and Local Resolution

Practice tracing DNS resolution, creating local hostname overrides, and experimenting with resolver configuration.

### ✅ Practice 1: Trace a DNS Resolution Step by Step with dig +trace

```bash
mkdir -p ~/linux-course/part27
cd ~/linux-course/part27

# Trace the full resolution chain
dig +trace www.example.com > trace_output.txt

# Analyze the output
cat trace_output.txt

# Count the steps
echo "Number of resolution steps:"
grep -c "received" trace_output.txt

# Identify root servers contacted
grep "root-servers.net" trace_output.txt
```

---

### ✅ Practice 2: Create Local Hostname Overrides in /etc/hosts

```bash
cd ~/linux-course/part27

# Backup hosts file
sudo cp /etc/hosts /etc/hosts.backup

# Add a local override
echo "127.0.0.1    mytest.local" | sudo tee -a /etc/hosts

# Verify with getent (uses nsswitch → includes /etc/hosts)
getent hosts mytest.local

# Verify dig bypasses it (queries DNS directly, not /etc/hosts)
dig +short mytest.local

# Remove the entry
sudo sed -i '/mytest.local/d' /etc/hosts
```

---

### ✅ Practice 3: Experiment with /etc/resolv.conf

```bash
cd ~/linux-course/part27

# Save current resolv.conf
cp /etc/resolv.conf resolv.conf.backup

# Check if it's a symlink
ls -la /etc/resolv.conf

# Show the actual content
cat /etc/resolv.conf

# Show the upstream DNS (if using systemd-resolved)
cat /run/systemd/resolve/resolv.conf 2>/dev/null || echo "Not using systemd-resolved"

# Test resolution speed
time dig google.com +short

# Restore
cp resolv.conf.backup /etc/resolv.conf 2>/dev/null || true
```

---

---

### 📘 Level 2 Practices: Resolution Configuration, Caching, and Troubleshooting

Configure search domains, compare resolvers, set up caching with nscd and Unbound, debug with strace, and test mDNS.

### ✅ Practice 4: Set Up a Custom Search Domain

```bash
cd ~/linux-course/part27

# Create a test resolv.conf with search domain
cat > test-resolv.conf << 'EOF'
search lab.example.com prod.example.com
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Test with a single-label name (no dots)
# First with default resolver
dig +short server  # Will fail normally

# Then with our custom search
dig +short server +search  # Will try server.lab.example.com

# Simulate the search order
time dig @8.8.8.8 server.lab.example.com +short
time dig @8.8.8.8 server.prod.example.com +short
```

---

### ✅ Practice 5: Query Every DNS Record Type

```bash
cd ~/linux-course/part27

# Create a report of all record types for a domain
DOMAIN="google.com"

echo "=== DNS Records for $DOMAIN ===" > dns_records_report.txt
echo "" >> dns_records_report.txt

for type in A AAAA MX NS CNAME TXT SOA; do
    echo "--- $type Records ---" >> dns_records_report.txt
    dig +short $DOMAIN $type >> dns_records_report.txt
    echo "" >> dns_records_report.txt
done

cat dns_records_report.txt
```

---

### ✅ Practice 6: Compare Resolvers — Google, Cloudflare, Quad9

```bash
cd ~/linux-course/part27

# Test different public resolvers
for resolver in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do
    echo "=== Testing $resolver ==="
    
    # Query time
    TIME=$( (time dig @$resolver google.com +short > /dev/null) 2>&1 | grep real | awk '{print $2}')
    
    # Answer
    ANSWER=$(dig @$resolver google.com +short)
    
    echo "Response: $ANSWER"
    echo "Time: $TIME"
    echo ""
done > resolver_comparison.txt

cat resolver_comparison.txt
```

---

### ✅ Practice 7: Perform a Reverse DNS Lookup

```bash
cd ~/linux-course/part27

# Reverse lookup for common DNS servers
for ip in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do
    HOSTNAME=$(dig +short -x $ip)
    echo "$ip → $HOSTNAME"
done

# Check your own IP
MY_IP=$(hostname -I | awk '{print $1}')
echo "My IP: $MY_IP"
echo "Reverse: $(dig +short -x $MY_IP)"

# Check if reverse matches forward
echo "Forward of reverse:"
rev_name=$(dig +short -x $MY_IP)
if [ -n "$rev_name" ]; then
    dig +short $rev_name
fi
```

---

### ✅ Practice 8: Set Up nscd and Observe Caching

```bash
cd ~/linux-course/part27

# Install nscd if not present
which nscd || sudo apt install -y nscd

# Ensure it's running
sudo systemctl enable --now nscd

# Clear the cache first
sudo nscd -i hosts

# Time first lookup (cold cache)
echo "Cold cache:"
time getent hosts google.com

# Time second lookup (hot cache)
echo "Hot cache:"
time getent hosts google.com

# Compare
echo "Cache statistics:"
sudo nscd -g | head -20

# Check cache for hosts specifically
sudo nscd -g | grep -A 10 "hosts cache"
```

---

### ✅ Practice 9: Flush Caches and Verify

```bash
cd ~/linux-course/part27

# Flush nscd cache
sudo nscd -i hosts

# Flush systemd-resolved cache (if available)
sudo resolvectl flush-caches 2>/dev/null || echo "Not using systemd-resolved"

# Verify flush
echo "systemd-resolved stats (if available):"
resolvectl statistics 2>/dev/null | grep -i cache || echo "resolvectl not available"

echo "nscd stats after flush:"
sudo nscd -g | grep -i "cache\|hits\|misses" | head -10
```

---

### ✅ Practice 10: Debug Resolution with strace

```bash
cd ~/linux-course/part27

# Trace what happens when you resolve a hostname
strace -e openat,connect,sendto,recvfrom,read -o strace_resolve.log getent hosts google.com

# Analyze the trace
echo "=== Files opened during resolution ==="
grep "openat" strace_resolve.log | grep -E "(hosts|resolv|nsswitch|nss)" | head -10

echo ""
echo "=== DNS queries sent ==="
grep "sendto" strace_resolve.log | wc -l

echo ""
echo "=== DNS responses received ==="
grep "recvfrom" strace_resolve.log | wc -l

echo ""
echo "=== Full trace ==="
cat strace_resolve.log
```

---

### ✅ Practice 11: Test mDNS with Avahi

```bash
cd ~/linux-course/part27

# Check if Avahi is running
sudo systemctl status avahi-daemon 2>/dev/null || echo "Avahi not installed"

# If Avahi is running:
if systemctl is-active --quiet avahi-daemon 2>/dev/null; then
    # Discover services on the network
    timeout 5 avahi-browse -a -t -r 2>/dev/null || echo "No mDNS services found"
    
    # Check if this host is publishing its name
    avahi-resolve-hostname -4 $(hostname).local 2>/dev/null || echo "$(hostname).local not published"
fi

# Check nss-mdns installation
dpkg -l libnss-mdns 2>/dev/null || rpm -q libnss-mdns 2>/dev/null || echo "libnss-mdns not installed"
```

---

### ✅ Practice 12: Modify /etc/nsswitch.conf and Observe Behavior Change

---

### 📘 Level 3 Practices: Advanced Analysis and Integration

Perform a full domain DNS configuration analysis, set up a local Unbound cache, and build a comprehensive DNS health report.

### ✅ Practice 13: Analyze a Domain's Full DNS Configuration

```bash
cd ~/linux-course/part27

# Backup
sudo cp /etc/nsswitch.conf /etc/nsswitch.conf.backup

# Show current hosts line
echo "Current config:"
grep ^hosts /etc/nsswitch.conf

# Create a test entry in /etc/hosts
echo "192.168.100.100    testnss.local" | sudo tee -a /etc/hosts

# Verify it resolves via files
getent hosts testnss.local

# Now test what happens if we put dns before files
# (Don't actually change — just observe the behavior difference)
echo ""
echo "Key insight: getent hosts uses nsswitch order."
echo "dig bypasses nsswitch entirely."

# Clean up
sudo sed -i '/testnss.local/d' /etc/hosts
```

---

### ✅ Practice 13: Analyze a Domain's Full DNS Configuration

```bash
cd ~/linux-course/part27

DOMAIN="kernel.org"

echo "=== Full DNS Analysis: $DOMAIN ===" > dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- Authority (SOA) ---" >> dns_analysis.txt
dig +short SOA $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- Nameservers ---" >> dns_analysis.txt
dig +short NS $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- A Records ---" >> dns_analysis.txt
dig +short A $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- AAAA Records ---" >> dns_analysis.txt
dig +short AAAA $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- Mail Servers ---" >> dns_analysis.txt
dig +short MX $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- TXT Records ---" >> dns_analysis.txt
dig +short TXT $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- DNSSEC (if enabled) ---" >> dns_analysis.txt
dig +dnssec +short $DOMAIN >> dns_analysis.txt
echo "" >> dns_analysis.txt

echo "--- Trace Path ---" >> dns_analysis.txt
dig +trace $DOMAIN +short >> dns_analysis.txt 2>/dev/null || true

echo "" >> dns_analysis.txt
echo "--- Nameserver Version Info ---" >> dns_analysis.txt
for ns in $(dig +short NS $DOMAIN); do
    echo "Querying $ns..." >> dns_analysis.txt
    dig @$ns chaos txt version.bind +short >> dns_analysis.txt 2>/dev/null
done

cat dns_analysis.txt
```

---

### ✅ Practice 14: Set Up a Local DNS Cache with Unbound

```bash
cd ~/linux-course/part27

# Install unbound
sudo apt install -y unbound 2>/dev/null || sudo dnf install -y unbound 2>/dev/null

# Create minimal config
sudo tee /etc/unbound/unbound.conf.d/local-cache.conf << 'EOF'
server:
    interface: 127.0.0.1
    port: 5353
    access-control: 127.0.0.0/8 allow
    verbosity: 1
    do-daemonize: yes
    prefetch: yes
    cache-min-ttl: 600
    cache-max-ttl: 86400
    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes
    hide-identity: yes
    hide-version: yes
EOF

# Start unbound
sudo systemctl restart unbound
sudo systemctl status unbound --no-pager | head -10

# Test: first query is cold (recursive, may be slow)
echo "First query (cold cache):"
time dig @127.0.0.1 -p 5353 google.com +short

# Second query (should be fast, from cache)
echo "Second query (hot cache):"
time dig @127.0.0.1 -p 5353 google.com +short

# Third query (cached, near-instant)
echo "Third query (cached):"
time dig @127.0.0.1 -p 5353 google.com +short
```

---

### ✅ Practice 15: Real-World Integration — DNS Health Report

```bash
cd ~/linux-course/part27

cat > dns_health_report.sh << 'EOF'
#!/bin/bash
set -euo pipefail

REPORT="dns_health_report.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

cat > "$REPORT" << HEADER
============================================
  DNS HEALTH REPORT
  Hostname: $HOSTNAME
  Date:     $TIMESTAMP
============================================

HEADER

# 1. System configuration
echo "[1] System DNS Configuration" >> "$REPORT"
echo "  resolv.conf:" >> "$REPORT"
ls -la /etc/resolv.conf >> "$REPORT" 2>&1
cat /etc/resolv.conf >> "$REPORT" 2>&1
echo "" >> "$REPORT"

echo "  nsswitch hosts line:" >> "$REPORT"
grep ^hosts /etc/nsswitch.conf >> "$REPORT"
echo "" >> "$REPORT"

# 2. DNS server availability
echo "[2] DNS Server Availability" >> "$REPORT"
for ns in $(grep nameserver /etc/resolv.conf | awk '{print $2}') 8.8.8.8 1.1.1.1; do
    if ping -c 1 -W 2 "$ns" > /dev/null 2>&1; then
        echo "  $ns: ONLINE (RTT: $(ping -c 1 -W 2 $ns 2>/dev/null | tail -1 | awk -F '/' '{print $5}')ms)" >> "$REPORT"
    else
        echo "  $ns: OFFLINE" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# 3. Test common domains
echo "[3] Domain Resolution Tests" >> "$REPORT"
for domain in google.com cloudflare.com kernel.org example.com; do
    IP=$(dig +short "$domain" | head -1)
    TIME=$( (time dig +short "$domain" > /dev/null) 2>&1 | grep real | awk '{print $2}')
    if [ -n "$IP" ]; then
        echo "  $domain -> $IP ($TIME)" >> "$REPORT"
    else
        echo "  $domain -> FAILED ($TIME)" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# 4. Cache status
echo "[4] DNS Cache Status" >> "$REPORT"
if command -v resolvectl &> /dev/null; then
    resolvectl statistics >> "$REPORT" 2>&1
elif command -v nscd &> /dev/null; then
    sudo nscd -g 2>/dev/null | grep -E "hosts|cache|hits|misses" >> "$REPORT"
else
    echo "  No caching daemon detected" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 5. Reverse DNS check
echo "[5] Reverse DNS Check" >> "$REPORT"
MY_IP=$(hostname -I | awk '{print $1}')
REV_NAME=$(dig +short -x "$MY_IP" 2>/dev/null)
if [ -n "$REV_NAME" ]; then
    echo "  $MY_IP -> $REV_NAME" >> "$REPORT"
else
    echo "  $MY_IP -> No PTR record" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 6. mDNS/LLMNR status
echo "[6] Local Name Resolution" >> "$REPORT"
if command -v resolvectl &> /dev/null; then
    resolvectl status | grep -E "LLMNR|mDNS|Protocols" >> "$REPORT"
elif command -v avahi-browse &> /dev/null; then
    echo "  Avahi daemon is available" >> "$REPORT"
else
    echo "  No local multicast resolution detected" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 7. DNSSEC validation
echo "[7] DNSSEC Validation Test" >> "$REPORT"
dig +dnssec +short com > /dev/null 2>&1 && echo "  DNSSEC: OK" >> "$REPORT" || echo "  DNSSEC: Not supported/Enabled" >> "$REPORT"
echo "" >> "$REPORT"

# 8. Performance summary
echo "[8] Resolution Performance" >> "$REPORT"
echo "  Average resolution time (3 queries to google.com):" >> "$REPORT"
for i in 1 2 3; do
    t=$( (time dig +short google.com > /dev/null) 2>&1 | grep real | awk '{print $2}')
    echo "    Attempt $i: $t" >> "$REPORT"
done
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF DNS HEALTH REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x dns_health_report.sh
./dns_health_report.sh
```

---

## 🧠 Deep Understanding — How DNS Resolution Really Works

### The glibc Resolver

When a program calls `getaddrinfo("google.com", ...)`, here's what happens inside glibc:

```
getaddrinfo("google.com", ...)
  │
  ├─► nsswitch.conf: check "hosts" database order
  │
  ├─► files module (libnss_files.so.2)
  │   ├─► open /etc/hosts
  │   ├─► parse lines, compare hostname
  │   └─► if found → return immediately
  │
  ├─► dns module (libnss_dns.so.2)
  │   ├─► open /etc/resolv.conf
  │   ├─► parse nameserver, search, options
  │   ├─► construct DNS query (type A and AAAA)
  │   ├─► send UDP packet to first nameserver:53
  │   ├─► wait for response
  │   │   ├─► timeout (default 5s) → try next nameserver
  │   │   ├─► SERVFAIL → try next nameserver
  │   │   └─► NXDOMAIN → return NOTFOUND
  │   ├─► if no dot in name: append each search domain
  │   └─► return IP address(es)
  │
  ├─► myhostname module (libnss_myhostname.so.2)
  │   ├─► is the name our own hostname?
  │   ├─► is it localhost?
  │   └─► if yes → return 127.0.0.1 or our IP
  │
  └─► return result to application
```

### The Resolver Library (/etc/resolv.conf Parser)

The glibc resolver (`resolv.conf` parser) is in `libc.so` itself. It:

1. Opens `/etc/resolv.conf` (or the `RESOLV.conf` override)
2. Reads up to 3 `nameserver` lines
3. Creates a list of up to 6 `search` domains
4. Applies `options` — timeout, attempts, rotate, ndots, etc.
5. Stores this in process memory

```bash
# See the resolver code in action
strace -e read,openat getent hosts google.com 2>&1 | grep resolv
```

### Retry and Timeout Logic

```
Query to nameserver[0]:
  │
  ├─► Send UDP query to port 53
  ├─► Wait timeout (default: 5 seconds)
  │   ├─► Response received → done
  │   └─► Timeout → try nameserver[1]
  │
  ├─► (if rotate) next query starts with nameserver[1]
  └─► After attempts (default: 2) → return failure

Total worst-case: 3 nameservers × 2 attempts × 5s = 30 seconds
```

This is why adding `options timeout:2 attempts:1` in `/etc/resolv.conf` dramatically speeds up resolution when a nameserver is down.

### Search Domain Logic

```bash
# /etc/resolv.conf
search example.com prod.example.com
```

When you query `server` (no dots):

```
1. Try "server.example.com."  (append search domain #1)
2. Try "server.prod.example.com."  (append search domain #2)
3. Try "server."  (as absolute query, one dot)
4. Fail with NXDOMAIN
```

The `ndots` option changes this:

```
options ndots:0   → Always try search domains first
options ndots:1   → Try search domains if name has < 1 dot (DEFAULT)
options ndots:5   → Try search domains if name has < 5 dots
```

With `ndots:1` (default):
- `server` → try search domains (0 dots < 1)
- `server.example.com` → try absolute query first (1 dot = 1)

### The Name Service Switch Module ABI

Each NSS module exports specific functions:

```c
// libnss_dns exports:
enum nss_status _nss_dns_gethostbyname4_r(
    const char *name,
    struct gaih_addrtuple **pat,
    char *buffer, size_t buflen,
    int *errnop, int *h_errnop,
    int32_t *ttlp);

enum nss_status _nss_dns_gethostbyaddr2_r(
    const void *addr, socklen_t len, int af,
    struct hostent *result, char *buffer, size_t buflen,
    int *errnop, int *h_errnop, int32_t *ttlp);
```

These are the functions that glibc calls when nsswitch says "dns".

### Memory Layout of the Resolution Chain

```
Process A: getaddrinfo("google.com")
  ├─ libc.so → nsswitch.conf → /etc/hosts → /etc/resolv.conf → fork? no
  ├─ libnss_dns.so → UDP socket → 8.8.8.8:53
  └─ returns IP

Process B: ping google.com
  ├─ libc.so → same resolution chain (independent)
  └─ unless nscd is running → shared cache via mmap
```

When nscd is active:

```
getaddrinfo → nscd socket (/var/run/nscd/socket) → nscd checks shared cache
                    ↕
              If cached → return from cache
              If not → query DNS, cache result, return
```

### systemd-resolved Deep Dive

systemd-resolved uses D-Bus for communication (not just the stub resolver on 127.0.0.53):

```
Application
    │
    ├─► libnss_resolve.so.2  (D-Bus) → systemd-resolved → upstream
    │        or
    ├─► 127.0.0.53:53  (stub resolver, UDP/TCP) → systemd-resolved → upstream
    │        or
    └─► Direct DNS (if /etc/resolv.conf points upstream)
```

The D-Bus API provides richer data:

```bash
# Query via D-Bus directly
busctl call org.freedesktop.resolve1 /org/freedesktop/resolve1 \
    org.freedesktop.resolve1.Manager ResolveHostname \
    "isit" 0 "google.com" 0 0
```

### What Happens When No DNS Server Responds

```
1. Query to 8.8.8.8: no response (timeout 5s)
2. Query to 1.1.1.1: no response (timeout 5s)
3. Query to 9.9.9.9: no response (timeout 5s)
4. Return "Temporary failure in name resolution" (EAI_AGAIN)
5. Application retries or fails

Total: 15+ seconds of blocking
```

The `options timeout:1` and `options attempts:1` can reduce this to 3 seconds.

---

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

---

## 🚀 What's Coming in Part 28

**Part 28: Network File System (NFS)**

You will learn:
- NFS protocol versions (v3, v4, v4.1, v4.2)
- Setting up an NFS server and client
- Exporting filesystems with /etc/exports
- NFS security — root_squash, no_all_squash, kerberos
- NFSv4 pseudo-filesystem
- Performance tuning and troubleshooting
- Autofs — automatic NFS mounting on demand
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between a recursive and iterative DNS query?
2. What are the three services (sources) listed in the default `hosts` line of `/etc/nsswitch.conf`?
3. Why does `dig google.com` work even when `ping google.com` fails with "Temporary failure in name resolution"?
4. What does `options timeout:2` in `/etc/resolv.conf` control?
5. What is the purpose of the stub resolver at `127.0.0.53`?
6. How does `dig +trace` work? What servers does it contact?
7. What is the difference between mDNS and LLMNR?
8. How do you flush the DNS cache on a system using systemd-resolved?
9. What record type would you query to find a domain's mail servers?
10. What does `search example.com` in `/etc/resolv.conf` do?
11. How does TCP wrappers (`/etc/hosts.allow`, `/etc/hosts.deny`) decide whether to allow a connection?
12. What is the TTL field in a DNS response, and how does it affect caching?
13. How would you block `facebook.com` on a Linux machine using only local configuration files?
14. What is the difference between `nscd -i hosts` and `resolvectl flush-caches`?
15. When you call `getaddrinfo()` in a C program, in what order does glibc consult `files`, `dns`, and `myhostname`?

**Score:** 12/15 correct = ready for Part 28.

---

*Linux SysAdmin Course | Part 27 of ∞ | Reverse Engineering Approach*
*Previous → Part 26: Network Configuration*
*Next → Part 28: Network File System (NFS)*

[← Previous](part26.md) | [Next →](part28.md)
