## ⚙️ Section 2: ISC DHCP Server Installation

### 2.1 What is ISC DHCP?

The reference implementation from the Internet Systems Consortium (same as BIND). Provides `dhcpd` (server), `dhcrelay` (relay), and `dhclient` (client).

### 2.2 Installation

```bash
sudo apt update
sudo apt install -y isc-dhcp-server
dhcpd --version
```

### 2.3 Configure Which Interface to Listen On

```bash
# /etc/default/isc-dhcp-server
INTERFACESv4="eth0"
INTERFACESv6=""
OPTIONS=""
```

### 2.4 Start and Enable

```bash
sudo systemctl enable --now isc-dhcp-server
sudo systemctl status isc-dhcp-server
sudo ss -tulpn | grep ':67'
```

### 2.5 RHEL/CentOS

```bash
sudo dnf install -y dhcp-server
echo 'DHCPDARGS="eth0"' | sudo tee /etc/sysconfig/dhcpd
sudo systemctl enable --now dhcpd
```

### 2.6 Troubleshooting

```bash
sudo dhcpd -t                    # Test syntax
sudo dhcpd -f -d                 # Foreground debug mode
sudo ss -tulpn | grep :67        # Check port 67
sudo aa-status | grep dhcp       # AppArmor
```





[← Previous](04-level-2-intermediary-dhcp-server.md) | [↑ Index](index.md) | [Next →](06-section-3-isc-dhcp-configuration.md)
