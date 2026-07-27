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



---

[← Previous](10-section-7-dns-caching.md) | [↑ Index](index.md) | [Next →](12-section-9-llmnr-link-local-multicast.md)
