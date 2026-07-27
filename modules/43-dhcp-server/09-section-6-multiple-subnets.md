## 🌐 Section 6: Multiple Subnets

### 6.1 Shared-Network (Same Wire, Multiple Subnets)

```bash
shared-network "office" {
    subnet 192.168.1.0 netmask 255.255.255.0 {
        range 192.168.1.100 192.168.1.200;
        option routers 192.168.1.1;
    }
    subnet 10.0.0.0 netmask 255.255.255.0 {
        range 10.0.0.100 10.0.0.200;
        option routers 10.0.0.1;
    }
}
```

### 6.2 Multi-Homed DHCP Server

```bash
# /etc/default/isc-dhcp-server
INTERFACESv4="eth0 eth1 eth2"
```

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
}
subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.100 10.0.0.200;
    option routers 10.0.0.1;
}
subnet 172.16.0.0 netmask 255.255.255.0 {
    range 172.16.0.100 172.16.0.200;
    option routers 172.16.0.1;
}
```

### 6.3 Conditional Pool Assignment with Classes

```bash
class "Intel" {
    match if substring (hardware, 1, 3) = 00:1b:21;
}
class "Realtek" {
    match if substring (hardware, 1, 3) = 00:e0:4c;
}

subnet 192.168.1.0 netmask 255.255.255.0 {
    pool { allow members of "Intel";  range 192.168.1.100 192.168.1.120; }
    pool { allow members of "Realtek"; range 192.168.1.121 192.168.1.140; }
    pool { range 192.168.1.141 192.168.1.200; }
}
```

---



---

[← Previous](08-section-5-dhcp-options.md) | [↑ Index](index.md) | [Next →](10-section-7-dhcp-relay.md)
