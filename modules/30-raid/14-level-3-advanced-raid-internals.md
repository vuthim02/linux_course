## ⭐ Level 3: Advanced — RAID Internals & Hardware

![XOR parity calculation — the math behind RAID 5 and RAID 6 recovery](https://www.sqlpassion.at/wp-content/uploads/2017/05/RAID5_Parity.png)

*XOR parity logic — how RAID 5 reconstructs data after a disk failure (SQLpassion)*

> **Level 3 Goal:** Master RAID internals — hardware RAID controllers, the md driver architecture, XOR parity math, superblock formats, performance tuning, and enterprise-grade RAID practices.

### What You'll Cover
- Hardware RAID controllers: MegaRAID, HBA, and the differences
- The Linux md driver architecture and `/sys/block/md*/` interfaces
- XOR parity math: how RAID 5/6 calculate and reconstruct data
- Superblock formats: 0.90 vs 1.x metadata
- Chunk size tuning and its impact on workload performance
- Enterprise RAID: battery-backed cache, consistency checks, patrol reads

Understanding RAID internals separates someone who runs `mdadm --create` from someone who can diagnose why an array is slow or recover from metadata corruption.

At this level you will master:

- **Hardware RAID**: MegaRAID controllers (Dell/LSI) have their own BIOS/UEFI and management tools (`storcli`, `megacli`). HBAs (Host Bus Adapters) pass disks directly to the OS for software RAID. Hardware RAID has battery-backed write cache but adds cost and vendor lock-in.
- **md driver architecture**: The Linux md driver creates virtual block devices (`/dev/md0`) from underlying partitions. The sysfs interface at `/sys/block/md0/md/` exposes component status, sync speed, and degraded mode. This is how monitoring tools get their data.
- **XOR parity**: RAID 5 computes parity as P = A ⊕ B ⊕ C. If any one disk fails, the missing data is reconstructed from the others using the same XOR operation. RAID 6 adds a second parity block (Q) for double-failure tolerance. The math is simple but powerful.
- **Superblock formats**: Version 0.90 stores the superblock at the end of the device (max 2TB arrays). Version 1.x stores it at the start, supports larger arrays, and includes a backup copy. Use `mdadm --examine /dev/sdX` to check which version is in use.
- **Chunk size**: The stripe unit size (4K to 512K) affects performance based on workload. Sequential workloads benefit from larger chunks. Random workloads benefit from smaller chunks. Match your chunk size to your I/O pattern.


[← Previous](13-section-10-raid-and-lvm.md) | [↑ Index](index.md) | [Next →](15-section-11-hardware-raid.md)
