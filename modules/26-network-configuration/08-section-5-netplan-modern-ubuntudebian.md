## 🔍 Section 5: Netplan — Modern Ubuntu/Debian Network Configuration

Netplan is a YAML-based network configuration utility introduced in Ubuntu 17.10. It reads configuration from `/etc/netplan/` and generates backend configuration for either NetworkManager or systemd-networkd.

### Netplan Configuration Files

```bash
# Location of Netplan configs
ls /etc/netplan/

# Typical file: /etc/netplan/01-netcfg.yaml or 00-installer-config.yaml
```

### Basic Netplan Syntax

```yaml
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd   # or NetworkManager
  ethernets:
    enp0s3:
      dhcp4: true
```

### DHCP Configuration

```yaml
# /etc/netplan/01-dhcp.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
      dhcp6: false
      dhcp-identifier: mac   # Use MAC-based DHCP ID
```

### Static IP Configuration

```yaml
# /etc/netplan/01-static.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.1.100/24
        - 10.0.0.1/24      # Secondary IP
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
        search:
          - example.com
      optional: true       # Don't wait for this interface at boot
```

### Multiple Interfaces

```yaml
# /etc/netplan/02-multi-interface.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses:
        - 192.168.100.10/24
      routes:
        - to: 10.0.0.0/8
          via: 192.168.100.1
```

### Apply Netplan Configuration

```bash
# Test the configuration (dry run)
sudo netplan try

# This shows the diff and asks for confirmation (auto-reverts in 120 seconds)

# Apply the configuration
sudo netplan apply

# Generate backend configs without applying
sudo netplan generate

# Debug/show current config
sudo netplan get
sudo netplan status
sudo netplan status --diff
```

### Netplan Backend: systemd-networkd

Under the hood, Netplan generates configuration for systemd-networkd:

```bash
# See the generated configs
ls /run/systemd/network/
cat /run/systemd/network/*.network
```

Generated file example:
```ini
# /run/systemd/network/10-netplan-enp0s3.network
[Match]
Name=enp0s3

[Network]
DHCP=ipv4
DNS=8.8.8.8
DNS=8.8.4.4
Domains=example.com

[DHCP]
RouteMetric=100
UseDNS=false
```

### Netplan with NetworkManager as Renderer

```yaml
# /etc/netplan/01-nm.yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s3:
      dhcp4: true
```

This makes NetworkManager manage the interface, and you can still use `nmcli` for additional configuration.

### Network Bonding with Netplan

```yaml
# /etc/netplan/03-bond.yaml
network:
  version: 2
  renderer: networkd
  bonds:
    bond0:
      interfaces:
        - enp0s3
        - enp0s8
      parameters:
        mode: active-backup
        mii-monitor-interval: 100
        primary: enp0s3
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
```

### Bridging with Netplan

```yaml
# /etc/netplan/04-bridge.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
  bridges:
    br0:
      interfaces:
        - enp0s3
      addresses:
        - 192.168.1.200/24
      routes:
        - to: default
          via: 192.168.1.1
      parameters:
        stp: true
        forward-delay: 4
```

### VLAN with Netplan

```yaml
# /etc/netplan/05-vlan.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
  vlans:
    vlan100:
      id: 100
      link: enp0s3
      addresses:
        - 192.168.100.1/24
    vlan200:
      id: 200
      link: enp0s3
      addresses:
        - 192.168.200.1/24
```





[← Previous](07-section-4-networkmanager-nmcli-nmtui.md) | [↑ Index](index.md) | [Next →](09-section-6-traditional-etcnetworkinterfaces-debianubuntu.md)
