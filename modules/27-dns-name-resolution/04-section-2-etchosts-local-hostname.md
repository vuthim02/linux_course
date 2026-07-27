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



---

[← Previous](03-section-1-what-is-dns.md) | [↑ Index](index.md) | [Next →](05-section-3-etcresolvconf-the-resolver.md)
