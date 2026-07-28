## ⭐ Level 1: Basic — DHCP Concepts

> **Level Goal:** Understand how DHCP assigns IP addresses and the DORA process that makes it work.

### What You'll Cover
- What DHCP is and why it matters for network administration
- The DORA process: Discover, Offer, Request, Acknowledge
- Lease lifecycle: expiry, renewal, rebinding
- Key DHCP terms: scope, pool, reservation, options
- Common DHCP options: router, DNS servers, domain name, lease time

DHCP (Dynamic Host Configuration Protocol) automatically assigns IP addresses and network configuration to devices. It is the foundation of network connectivity in every organization.

At this level you will learn:

- **DORA process**: The client broadcasts a **Discover** packet. The server responds with an **Offer** (IP + lease). The client sends a **Request** for the offered IP. The server sends an **Acknowledge** confirming the lease. This four-step handshake happens in milliseconds.
- **Lease lifecycle**: A lease has a duration (e.g., 24 hours). At 50% of the lease time (T1), the client tries to renew with the original server. At 87.5% (T2), it broadcasts to any server. If the lease expires, the client releases the IP and starts DORA again.
- **Scope and pool**: A scope defines the IP range for a subnet (e.g., 192.168.1.0/24). A pool is a subset of that range available for dynamic assignment. Reservations are excluded from the pool for static assignments.
- **Options**: DHCP options provide additional configuration. Option 3 (router) sets the default gateway. Option 6 (DNS servers) sets nameservers. Option 15 (domain name) sets the search domain. Option 51 (lease time) controls lease duration.
- **Address conflicts**: When two devices have the same IP, connectivity breaks. DHCP prevents this with ARP probes — before assigning an IP, the server (or client with IPv4Acd) checks if anyone else is using it.


[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-section-1-what-is-dhcp.md)
