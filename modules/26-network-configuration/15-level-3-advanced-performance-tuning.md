## ⭐ Level 3: Advanced — Performance Tuning and Kernel Network Internals

![Network Performance Tuning](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Network_Stack.svg/220px-Network_Stack.svg.png)  
*The Linux network stack — understanding the path from application to wire. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Tune network interface performance with ethtool, configure MTU and offloading, adjust ring buffer sizes, and understand how the kernel network stack processes packets from arrival to delivery.

### What You'll Cover
- `ethtool` for link speed, duplex, and offloading settings
- Jumbo frames: setting MTU above 1500 for high-throughput networks
- Ring buffer tuning to reduce packet drops under load
- TCP offloading: TSO, GRO, and checksum offload
- Kernel network stack: from NIC interrupt to socket delivery

Network performance tuning is where theory meets production. A NIC dropping packets under load is often not a hardware problem — it is a configuration problem.

At this level you will master:

- **`ethtool`**: `ethtool eth0` shows link speed, duplex, and supported features. `ethtool -K eth0 tso on` enables TCP Segmentation Offload. `ethtool -G eth0 rx 4096` sets the receive ring buffer to 4096 descriptors.
- **Jumbo frames**: Set MTU above 1500 (commonly 9000) for storage networks and high-throughput links. `ip link set enp0s3 mtu 9000`. All devices on the segment must agree — mismatched MTU causes silent packet drops.
- **Ring buffer tuning**: The ring buffer is a fixed-size queue in NIC memory. When it fills, packets are dropped. Increase it with `ethtool -G`. Monitor drops with `ethtool -S eth0 | grep rx_dropped`.
- **TCP offloading**: TSO (TCP Segmentation Offload) lets the NIC split large TCP segments. GRO (Generic Receive Offload) merges small incoming packets. Both reduce CPU overhead. Check with `ethtool -k eth0`.
- **Kernel stack path**: Packets flow from NIC interrupt → NAPI polling → netfilter/iptables → TCP stack → socket buffer → application. Understanding this path helps you identify which layer is the bottleneck.


[← Previous](14-section-11-vlan-tagging-8021q.md) | [↑ Index](index.md) | [Next →](16-section-12-tuning-ethtool-mtu.md)
