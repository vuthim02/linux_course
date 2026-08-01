## 🔍 Section 16: systemd-networkd and systemd-resolved

### systemd-networkd — Lightweight Network Manager

Network manager for headless servers. No DBus dependency, minimal footprint.

```bash
# Enable
sudo systemctl enable --now systemd-networkd
```

```ini
# /etc/systemd/network/10-wired.network
[Match]
Name=eth0

[Network]
Address=10.0.0.100/24
Gateway=10.0.0.1
DNS=8.8.8.8
DNS=1.1.1.1
Domains=example.com
```

```ini
# VLAN interface
[Match]
Name=eth0

[Network]
VLAN=vlan100

# /etc/systemd/network/vlan100.netdev
[NetDev]
Name=vlan100
Kind=vlan

[VLAN]
Id=100
```

```bash
# Useful commands
networkctl status              # Overall status
networkctl list                # List all links
networkctl status eth0         # Link details
networkctl reload              # Reload config
```

### systemd-resolved — DNS Resolver

```bash
# Enable
sudo systemctl enable --now systemd-resolved

# Set up
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

```ini
# /etc/systemd/resolved.conf
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=9.9.9.9
Domains=~.
DNSSEC=allow-downgrade
Cache=yes
```

```bash
# Query DNS
resolvectl status              # DNS config per interface
resolvectl query example.com   # Resolve hostname
resolvectl flush-caches        # Clear DNS cache
resolvectl statistics          # Cache hit/miss stats

# Per-link DNS (via networkd config)
# /etc/systemd/network/10-wired.network
[Network]
DHCP=yes

[DHCPv4]
UseDNS=true

[Network]
DNS=10.0.0.1
DNS=10.0.0.2
```

### When to Use Which

| Scenario | Recommendation |
|----------|---------------|
| Desktop/laptop | NetworkManager |
| Server, single NIC | systemd-networkd |
| Complex networking (bonding, bridge) | Either works |
| DNS caching needed | systemd-resolved |
| Split DNS / VPN DNS | systemd-resolved |
| Legacy tools expecting `/etc/resolv.conf` | resolved's stub resolver |



[← Previous](24-section-15-user-services.md) | [↑ Index](index.md) | [Next →](26-section-17-tmpfiles-and-analyze.md)
