## 🔍 Section 2: How NTP Works

### The NTP Hierarchy (Stratum)

```
Stratum 0: Atomic clocks, GPS receivers
    (not connected to network directly)
    │
Stratum 1: Servers directly connected to Stratum 0
    (time.apple.com, time.google.com, nist.gov)
    │
Stratum 2: Servers syncing from Stratum 1
    (pool.ntp.org servers, your ISP's NTP servers)
    │
Stratum 3: Your organization's NTP servers
    │
Stratum 4: Your workstations and servers
```

### The NTP Protocol

```
NTP Client                    NTP Server
    │                              │
    │── Request (sent at T1) ─────→│
    │                              │
    │←─ Response (T1, T2, T3) ────│
    │      (Received at T4)        │
    │                              │

Round-trip delay = (T4 - T1) - (T3 - T2)
Time offset = ((T2 - T1) + (T3 - T4)) / 2

NTP continuously adjusts the clock:
- Small corrections: slewed (gradually adjusted)
- Large corrections: stepped (jumped immediately)
- Default step threshold: 128ms (slew) vs 128ms+ (step)
```

### NTP vs Chrony

| Aspect | NTP (ntpd) | Chrony |
|--------|-----------|--------|
| Convergence speed | Slower | Faster |
| Accuracy | Excellent | Better (especially with variable latency) |
| Intermittent networks | Works | Works better |
| Virtual machines | Works | Works BETTER (handles suspend/resume) |
| Config format | Simple | Simple |
| Monitoring | ntpq, ntpstat | chronyc |
| Default on | Older distros | Newer distros (RHEL 8+, Ubuntu 18.04+, Debian 10+) |

---



---

[← Previous](03-section-1-why-time-matters.md) | [↑ Index](index.md) | [Next →](05-section-3-using-timedatectl.md)
