## 🔍 Section 5: Configuring Chrony as a Server

If you have many machines on a network, set up one internal NTP server:

```bash
# /etc/chrony/chrony.conf on the NTP server

# Use public NTP servers upstream
pool 2.debian.pool.ntp.org iburst

# Allow clients from your network
allow 192.168.1.0/24

# Serve time even if upstream is temporarily unavailable
local stratum 10

# Log client requests
log measurements statistics tracking
```

On client machines:

```bash
# /etc/chrony/chrony.conf

# Use your internal NTP server
server ntp.internal.example.com iburst

# Fallback to public pool if internal is unreachable
pool 2.debian.pool.ntp.org iburst
```

---



---

[← Previous](07-section-4-chrony.md) | [↑ Index](index.md) | [Next →](09-section-6-systemd-timesyncd.md)
