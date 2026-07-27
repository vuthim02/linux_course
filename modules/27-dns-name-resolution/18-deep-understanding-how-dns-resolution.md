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



---

[← Previous](17-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](19-summary-complete-command-reference-for.md)
