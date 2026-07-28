## 🔧 Section 3: ISC DHCP Configuration

### 3.1 The Main Config File

`/etc/dhcp/dhcpd.conf` uses a **declarative** syntax with curly braces.

```bash
sudo dhcpd -t    # Always test syntax after changes
```

### 3.2 Basic Configuration

```bash
option domain-name "example.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
option ntp-servers pool.ntp.org;
default-lease-time 86400;
max-lease-time 172800;
authoritative;
log-facility local7;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.1.255;
    option domain-name-servers 192.168.1.1, 8.8.8.8;
    option domain-name "example.com";
    default-lease-time 86400;
    max-lease-time 172800;
}
```

### 3.3 Directive Reference

| Directive | Purpose | Example |
|-----------|---------|---------|
| `subnet` | Declare a subnet pool | `subnet 10.0.0.0 netmask 255.255.255.0 { ... }` |
| `range` | IP range to assign | `range 10.0.0.100 10.0.0.200;` |
| `option routers` | Default gateway | `option routers 10.0.0.1;` |
| `option subnet-mask` | Subnet mask | `option subnet-mask 255.255.255.0;` |
| `option broadcast-address` | Broadcast address | `option broadcast-address 10.0.0.255;` |
| `option domain-name-servers` | DNS servers | `option domain-name-servers 8.8.8.8, 1.1.1.1;` |
| `option domain-name` | DNS search domain | `option domain-name "example.com";` |
| `option ntp-servers` | NTP servers | `option ntp-servers time.example.com;` |
| `default-lease-time` | Default lease length (s) | `default-lease-time 86400;` |
| `max-lease-time` | Maximum lease | `max-lease-time 172800;` |
| `authoritative` | This server is the authority | `authoritative;` |
| `log-facility` | Syslog facility | `log-facility local7;` |

### 3.4 The `authoritative` Directive

Without `authoritative`, the server is **timid** — it will not send NAK even if a client has an IP from the wrong subnet. With it, the server sends DHCPNAK to force clients to get a correct IP.

### 3.5 Multi-Subnet Example

```bash
option domain-name "example.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 86400;
max-lease-time 172800;
authoritative;

subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.100 10.0.0.200;
    option routers 10.0.0.1;
}

subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.50 192.168.10.200;
    option routers 192.168.10.1;
}

subnet 172.16.0.0 netmask 255.255.255.0 {
    range 172.16.0.100 172.16.0.200;
    option routers 172.16.0.1;
}
```





[← Previous](05-section-2-isc-dhcp-server.md) | [↑ Index](index.md) | [Next →](07-section-4-static-assignments-reservations.md)
