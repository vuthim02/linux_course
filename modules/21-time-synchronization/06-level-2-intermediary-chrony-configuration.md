## ⭐ Level 2: Intermediary — Chrony Configuration

![NTP servers and clients — hierarchical time distribution](https://upload.wikimedia.org/wikipedia/commons/6/6d/Network_Time_Protocol_servers_and_clients.svg)

*Network Time Protocol servers and clients distribution hierarchy (Wikimedia Commons / public domain)*

> **Level 2 Goal:** Install and configure Chrony as both client and server, understand configuration directives, use `chronyc` for monitoring, and compare with `systemd-timesyncd`.

### What You'll Cover
- Installing Chrony on Debian/Ubuntu and RHEL/Fedora
- Editing `/etc/chrony.conf`: server directives, pool entries, driftfile
- Starting and enabling `chronyd` with systemd
- Using `chronyc` to monitor synchronization status and source stats
- Comparing Chrony with `systemd-timesyncd` for simple setups

### Why This Level Matters

Chrony is the default NTP implementation on most modern Linux distributions. It is faster and more accurate than the classic `ntpd`, especially on systems with intermittent network connections or virtual machines with unstable clocks. Understanding Chrony configuration means you can fine-tune time synchronization for your specific environment.

The `chronyc` command-line tool is your window into what Chrony is doing. It shows which servers Chrony is syncing to, how accurate the synchronization is, and whether any sources are unreachable. This is essential for debugging time issues.

### What You'll Practice

- Installing Chrony and verifying the `chronyd` service is running
- Configuring `/etc/chrony.conf` with NTP pool entries for your region
- Using `chronyc sources -v` to see which servers Chrony is syncing to
- Checking synchronization accuracy with `chronyc tracking`
- Deciding between Chrony and `systemd-timesyncd` for your use case

> 💡 Use `pool pool.ntp.org iburst` in your Chrony config. The `iburst` option sends a burst of packets on startup, which speeds up initial synchronization. Without it, Chrony may take several minutes to settle.





[← Previous](05-section-3-using-timedatectl.md) | [↑ Index](index.md) | [Next →](07-section-4-chrony.md)
