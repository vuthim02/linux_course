## 📋 Section 4: Static Assignments (Reservations)

### 4.1 Why Reservations?

Servers, printers, network equipment need the **same IP every time** but should still get DHCP options via the `host` statement.

### 4.2 Basic Reservation

```bash
host printer-01 {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 192.168.1.10;
    option host-name "printer-01";
}
```

### 4.3 Reservations Inside a Subnet (Outside the Range)

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;

    host mail-server {
        hardware ethernet aa:bb:cc:dd:ee:01;
        fixed-address 192.168.1.10;
        option host-name "mail";
    }
    host web-server {
        hardware ethernet aa:bb:cc:dd:ee:02;
        fixed-address 192.168.1.11;
        option host-name "www";
    }
    host printer-01 {
        hardware ethernet 00:11:22:33:44:55;
        fixed-address 192.168.1.20;
        option host-name "hp-laserjet-4200";
    }
}
```

### 4.4 Reservations with Custom Options

```bash
host dev-laptop {
    hardware ethernet 52:54:00:ab:cd:ef;
    fixed-address 192.168.1.50;
    option domain-name-servers 1.1.1.1, 9.9.9.9;
    default-lease-time 604800;    # 7 days
}
```

### 4.5 Finding a Client's MAC Address

```bash
# On the client
ip link show eth0 | grep ether

# On the DHCP server — check lease file
sudo cat /var/lib/dhcp/dhcpd.leases | grep -A 5 "192.168.1.100"

# Check DHCP logs for MAC
sudo grep "DHCPACK" /var/log/syslog | grep -i "192.168.1.100"
```

---



---

[← Previous](06-section-3-isc-dhcp-configuration.md) | [↑ Index](index.md) | [Next →](08-section-5-dhcp-options.md)
