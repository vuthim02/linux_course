## 🌍 Section 11: DHCPv6

### 11.1 IPv6 Address Assignment Methods

| Method | DHCPv6 Role |
|--------|-------------|
| **SLAAC** | Client generates own address from RA + EUI-64 |
| **Stateless DHCPv6** | Client uses SLAAC for address, DHCPv6 for DNS/NTP (O flag) |
| **Stateful DHCPv6** | DHCPv6 provides addresses + options (M flag) |

### 11.2 Stateless DHCPv6

Router Advertises with **O flag** (Other Configuration). Client gets address via SLAAC, DNS via DHCPv6.

### 11.3 Stateful DHCPv6 (ISC DHCP)

```bash
# /etc/dhcp/dhcpd6.conf
option dhcp6.name-servers 2001:4860:4860::8888, 2001:4860:4860::8844;
option dhcp6.domain-search "example.com";
default-lease-time 86400;
max-lease-time 172800;

subnet6 2001:db8:1::/64 {
    range6 2001:db8:1::100 2001:db8:1::200;
    option dhcp6.name-servers 2001:db8:1::1, 2001:4860:4860::8888;
}
```

```bash
sudo dhcpd -6 -cf /etc/dhcp/dhcpd6.conf -lf /var/lib/dhcp/dhcpd6.leases eth0
```

### 11.4 IA_NA and IA_PD

| IA Type | Purpose |
|---------|---------|
| **IA_NA** | Assigns a regular IPv6 address to a client |
| **IA_TA** | Assigns temporary (privacy) addresses |
| **IA_PD** | Prefix Delegation — assigns an entire prefix to a router |

### 11.5 Prefix Delegation Example

```bash
subnet6 2001:db8:0::/48 {
    range6 2001:db8:0:1::/64 2001:db8:0:1::1000;    # Client addresses
    prefix6 2001:db8:0:: 2001:db8:ff:: /56;           # Delegated prefixes
}
```

### 11.6 Kea DHCPv6 Config

```json
{
    "Dhcp6": {
        "interfaces-config": { "interfaces": [ "eth0" ] },
        "valid-lifetime": 86400,
        "subnet6": [
            {
                "subnet": "2001:db8:1::/64",
                "id": 1,
                "pools": [
                    { "pool": "2001:db8:1::100 - 2001:db8:1::200" }
                ],
                "pd-pools": [
                    {
                        "prefix": "2001:db8::",
                        "prefix-len": 48,
                        "delegated-len": 56
                    }
                ],
                "option-data": [
                    { "name": "dns-servers", "data": "2001:4860:4860::8888" }
                ]
            }
        ]
    }
}
```

---



---

[← Previous](14-section-10-kea-the-modern.md) | [↑ Index](index.md) | [Next →](16-section-12-pxe-booting.md)
