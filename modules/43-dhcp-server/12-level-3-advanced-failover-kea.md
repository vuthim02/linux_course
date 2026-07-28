## ⭐ Level 3: Advanced — Failover, Kea, and PXE Booting

> **Level Goal:** Achieve DHCP high availability with ISC failover, migrate to Kea, and configure PXE boot infrastructure.

### What You'll Cover
- ISC DHCP failover protocol (primary/secondary split)
- Kea DHCP: the modern ISC replacement
- Kea configuration, Control Agent, and REST API
- DHCPv6 for IPv6 networks
- PXE boot setup for network-based OS installation
- TFTP server configuration and boot file management

At the advanced level, you deploy DHCP with high availability and prepare for modern alternatives like Kea.

At this level you will master:

- **ISC DHCP failover**: Configure `failover peer "dhcp-failover"` with `primary` and `secondary` declarations. The primary handles leases during normal operation; the secondary takes over during outages. Both servers share the same subnet configuration. Load balancing is possible with `load balance max balance 3`.
- **Kea DHCP**: The modern ISC replacement, written in C++ with a REST API. Install with `dnf install kea` or build from source. Configuration is JSON (`kea-dhcp4.conf`). Kea supports MySQL/PostgreSQL backends, dynamic reconfiguration via API, and built-in logging.
- **Kea features**: `kea-ctrl-agent` provides a REST API for runtime management. `kea-admin` manages the database. `kea-dhcp4` and `kea-dhcp6` are the DHCP daemons. Kea supports host reservations by MAC, circuit-id, and client-id.
- **PXE boot**: Preboot Execution Environment allows machines to boot and install an OS over the network. The DHCP server sends option 66 (TFTP server) and option 67 (boot file). The TFTP server serves the boot image (pxelinux.0 or grubx64.efi).
- **TFTP setup**: Install `tftp-hpa` or `atftpd`. Place boot files in `/var/lib/tftpboot/`. Configure the DHCP server to point to the TFTP server. PXE clients download the boot image, which then fetches the OS installer via HTTP or NFS.


[← Previous](11-section-8-dhcp-logging.md) | [↑ Index](index.md) | [Next →](13-section-9-isc-dhcp-failover.md)
