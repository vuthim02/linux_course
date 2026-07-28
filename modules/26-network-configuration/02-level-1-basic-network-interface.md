## ⭐ Level 1: Basic — Network Interface Concepts and Hostname Configuration

![Network Interfaces](https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Ethernet_Connection.svg/220px-Ethernet_Connection.svg.png)  
*Ethernet connection — the foundation of Linux networking. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand network interface naming conventions and types. Configure hostnames via `/etc/hostname` and `/etc/hosts`. Grasp basic DNS resolution through `/etc/resolv.conf`.

### What You'll Cover
- Network interface naming: predictable names (enp0s3, wlp2s0) vs legacy (eth0)
- Interface types: Ethernet, loopback, virtual, and bridge
- Configuring hostname with `hostnamectl` and `/etc/hostname`
- Static DNS entries with `/etc/hosts`
- DNS resolution order: `/etc/nsswitch.conf` and `/etc/resolv.conf`

Linux network interfaces have evolved from simple names like `eth0` to predictable names based on hardware topology. Understanding this system prevents confusion when managing multiple NICs.

At this level you will learn:

- **Predictable naming**: Names like `enp0s3` encode bus position (PCI slot 0, function 3). `en` = Ethernet, `wlan` = wireless, `lo` = loopback. Disable with `net.ifnames=0` in kernel parameters to revert to `eth0`.
- **Interface types**: Ethernet (`en*`), loopback (`lo` — always 127.0.0.1), virtual (bridges `br*`, bonds `bond*`, tunnels `tun*`). The `ip link show` command lists all interfaces and their state.
- **Hostname**: `hostnamectl set-hostname myserver` updates both `/etc/hostname` and the running hostname. This is critical for services that bind to or report the hostname (SSH, mail, databases).
- **`/etc/hosts`**: Maps hostnames to IPs. Used for local overrides and development. Entries take priority over DNS when nsswitch is configured with `files` before `dns`.
- **`/etc/resolv.conf`**: Lists nameserver IPs and search domains. On systems using systemd-resolved, this is often a symlink to `/run/systemd/resolve/stub-resolv.conf`. Never edit the symlink target directly.


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-network-interfaces-overview.md)
