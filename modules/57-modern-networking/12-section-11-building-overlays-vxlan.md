## 🔍 Section 11: Building Overlays — VXLAN + FRR (BGP EVPN)

### EVPN Overview

EVPN (Ethernet VPN) uses BGP to distribute MAC address reachability across a VXLAN fabric. Instead of flooding to learn MACs, each VTEP advertises its locally-learned MAC addresses via BGP.

```
┌─Spine──────────────────────────────────────────────────────────────────┐
│  BGP Route Reflector (optional)                                         │
└────────────┬──────────────────────────────────────┬─────────────────────┘
             │ BGP EVPN NLRI                         │ BGP EVPN NLRI
             │                                        │
┌────────────▼──────────────┐      ┌─────────────────▼────────────────────┐
│ Leaf-1 (VTEP)             │      │ Leaf-2 (VTEP)                       │
│ 10.0.0.1                  │      │ 10.0.0.2                            │
│                           │      │                                      │
│ VNI 1001:                  │      │ VNI 1001:                            │
│   MAC-A → 10.0.0.1         │◄────►│   MAC-B → 10.0.0.2                  │
│ Advertises:                │      │ Advertises:                          │
│   MAC-A → 10.0.0.1 via BGP│      │   MAC-B → 10.0.0.2 via BGP           │
└────────────────────────────┘      └─────────────────────────────────────┘
```

### FRR (Free Range Routing) Configuration

**Install FRR:**
```bash
# Ubuntu/Debian
sudo apt install frr frr-pythontools

# Enable BGP daemon
sudo sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
sudo systemctl enable frr
sudo systemctl restart frr
```

**FRR Configuration for EVPN/VXLAN:**

`/etc/frr/frr.conf` on Leaf-1:
```
!
router bgp 65001
  bgp router-id 10.0.0.1
  bgp bestpath as-path multipath-relax
  neighbor 10.0.0.100 remote-as 65000      # Spine / Route Reflector
  neighbor 10.0.0.100 update-source 10.0.0.1
  !
  address-family l2vpn evpn
    neighbor 10.0.0.100 activate
    advertise-all-vni
    advertise-subnet
  exit-address-family
!
```

`/etc/frr/frr.conf` on Leaf-2:
```
router bgp 65002
  bgp router-id 10.0.0.2
  neighbor 10.0.0.100 remote-as 65000
  neighbor 10.0.0.100 update-source 10.0.0.2
  !
  address-family l2vpn evpn
    neighbor 10.0.0.100 activate
    advertise-all-vni
    advertise-subnet
  exit-address-family
!
```

### Anycast Gateways

For seamless VM/container mobility, use the same gateway IP across all VTEPs:

```bash
# On every leaf:
sudo ip addr add 10.100.1.1/24 dev vxlan1001
# This IP is the same on every leaf (anycast)
# The leaf that owns the MAC will respond to ARP/ND
# BGP EVPN distributes the MAC-to-VTEP mapping
```

The combination of VXLAN + EVPN with anycast gateways enables:
- VM mobility (vMotion) without IP address changes
- Active-active load balancing across multiple VTEPs
- Subnet extension across the entire fabric

---



---

[← Previous](11-section-10-vxlan.md) | [↑ Index](index.md) | [Next →](13-section-12-performance-and-tuning.md)
