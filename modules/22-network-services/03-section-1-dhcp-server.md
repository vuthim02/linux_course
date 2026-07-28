## 🔍 Section 1: DHCP Server

### What is DHCP?

DHCP (Dynamic Host Configuration Protocol) automatically assigns IP addresses and network configuration to clients.

### How DHCP Works (DORA)

```
Client                    DHCP Server
  │                            │
  │ 1. DHCP Discover (broadcast) → │
  │                            │
  │ ← 2. DHCP Offer            │
  │                            │
  │ 3. DHCP Request →          │
  │                            │
  │ ← 4. DHCP Acknowledge      │
  │                            │
```

### Installing DHCP Server

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install isc-dhcp-server

# Fedora/RHEL
sudo dnf install dhcp-server
```

### Configuration

```bash
sudo cat /etc/dhcp/dhcpd.conf
```

```
# Global settings
option domain-name "example.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 600;
max-lease-time 7200;
authoritative;

# Subnet definition
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option broadcast-address 192.168.1.255;
}

# Static reservation
host printer {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 192.168.1.50;
}
```

### Key Configuration Directives

| Directive | Purpose |
|-----------|---------|
| `subnet` | Define a subnet with range |
| `range` | Pool of assignable IPs |
| `option routers` | Default gateway |
| `option domain-name-servers` | DNS servers |
| `default-lease-time` | Lease duration (seconds) |
| `max-lease-time` | Maximum lease duration |
| `host` | Static reservation for MAC |
| `fixed-address` | IP for static reservation |
| `authoritative` | This is the official DHCP server |

### Managing DHCP Server

```bash
# Start/stop/restart
sudo systemctl start isc-dhcp-server
sudo systemctl stop isc-dhcp-server
sudo systemctl restart isc-dhcp-server

# Enable on boot
sudo systemctl enable isc-dhcp-server

# Check status
sudo systemctl status isc-dhcp-server

# View leases
cat /var/lib/dhcp/dhcpd.leases
```

### DHCP Client

```bash
# Release and renew IP
sudo dhclient -r       # Release current lease
sudo dhclient          # Request new lease

# View DHCP info
ip addr show           # See assigned IP
ip route               # See default gateway
cat /etc/resolv.conf   # See DNS servers
```





[← Previous](02-level-1-basic-dhcp-and.md) | [↑ Index](index.md) | [Next →](04-section-2-http-server.md)
