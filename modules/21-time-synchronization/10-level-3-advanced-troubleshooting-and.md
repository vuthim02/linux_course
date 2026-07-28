## ⭐ Level 3: Advanced — Troubleshooting and Internals

![NTP algorithm diagram — clock filter and offset calculation](https://upload.wikimedia.org/wikipedia/commons/f/fb/NTP-Algorithm.svg)

*NTP algorithm showing clock offset calculation (Wikimedia Commons / public domain)*

> **Level 3 Goal:** Diagnose and resolve time synchronization issues, understand the NTP protocol internals, leap second handling, and Chrony's advanced filtering algorithms.

### What You'll Cover
- Debugging time drift: `chronyc tracking`, `journalctl -u chronyd`
- NTP protocol internals: offset, delay, jitter calculations
- Leap second insertion and how Chrony handles it
- Firewall issues blocking NTP (UDP port 123)
- Selecting accurate time sources with `chronyc select`

### Why This Level Matters

Time drift is a silent killer. A server that drifts by one second per day will be over 15 minutes off after five months. That is enough to break Kerberos authentication, invalidate SSL certificates, and corrupt log correlation. Level 3 gives you the tools to find and fix drift before it causes damage.

The NTP algorithm is sophisticated. It does not just ask one server for the time. It sends packets to multiple servers, filters out outliers, accounts for network delay, and calculates a weighted average. Understanding this algorithm helps you interpret `chronyc` output and choose the right troubleshooting steps.

### What You'll Practice

- Using `chronyc tracking` to read offset, frequency, and jitter values
- Filtering `journalctl` output to find Chrony startup and sync events
- Configuring firewall rules to allow NTP traffic on UDP port 123
- Using `chronyc select` to manually choose preferred time sources
- Understanding how Chrony handles leap seconds without disrupting services

> ⚠️ If `chronyc tracking` shows an offset greater than 100ms for more than a few minutes, something is wrong. Check network connectivity, firewall rules, and whether your time sources are actually reachable.





[← Previous](09-section-6-systemd-timesyncd.md) | [↑ Index](index.md) | [Next →](11-section-7-troubleshooting-time-sync.md)
