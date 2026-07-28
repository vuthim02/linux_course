## ⭐ Level 1: Basic — Time Concepts and Basics

![NTP architecture — stratum hierarchy from atomic clocks to clients](https://upload.wikimedia.org/wikipedia/commons/0/0d/Architecture_NTP_no_labels.svg)

*NTP stratum hierarchy (Roland Geider / Wikimedia Commons / public domain)*

> **Level 1 Goal:** Understand why accurate time is critical for servers, how the NTP hierarchy works, and how to use `timedatectl` to manage basic time settings.

### What You'll Cover
- Why correct time matters: log correlation, Kerberos, certificate validation
- NTP stratum hierarchy: stratum 0 (atomic clocks) through stratum 15
- UTC vs local time and why servers should use UTC
- Checking time with `timedatectl status`
- Enabling/disabling NTP synchronization with `timedatectl set-ntp`

### Why This Level Matters

Time is invisible until it is wrong. When your web server logs say a request happened at 3:00 AM but the database logs say 3:00 PM, debugging becomes impossible. When a Kerberos token appears to be from the future, authentication fails. When an SSL certificate shows an expiry date that has already passed, users see scary warnings.

Servers should always use UTC. Local timezones are for humans looking at screens. Databases, logs, and certificates need a single, unambiguous time reference. UTC is that reference. Convert to local time only in display, never in storage.

### Key Concepts to Remember

**NTP uses a hierarchy called strata.** Stratum 0 is an atomic clock or GPS receiver. Stratum 1 servers synchronize to stratum 0. Stratum 2 servers synchronize to stratum 1, and so on up to stratum 15. Each layer adds a tiny bit of drift, so lower stratum numbers are more accurate.

**Hardware clocks and system clocks are different.** The hardware clock (RTC) runs even when the machine is off. The system clock is maintained by the kernel. At boot, the system clock reads from the hardware clock. After that, NTP keeps it accurate.

> 💡 Run `timedatectl status` on any Linux system right now. It shows your current time, timezone, whether NTP is active, and whether the hardware clock is in UTC. This single command tells you if your time setup is correct.



[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-why-time-matters.md)
