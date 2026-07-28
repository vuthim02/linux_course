## ⭐ Level 3: Advanced — LVM Internals and Performance Tuning

![Device Mapper kernel stack — LVM2 is built on the Linux device-mapper framework](https://upload.wikimedia.org/wikipedia/commons/6/6f/Lvm_snapshot.svg)

> **Level 3 Goal:** Configure striped LVs with optimal alignment, deploy LVM RAID (raid1/5/6/10), recover from PV failures using low-level tools (`dmsetup`, `pvck`, `vgcfgrestore`), understand the Device Mapper kernel layer, and tune LVM for performance.

### What You'll Cover
- LVM striping: distributing data across PVs for performance
- LVM RAID (lvmraid): md-based RAID within LVM
- Device Mapper internals: how LVM maps block devices
- Recovery tools: `dmsetup`, `pvck`, `vgcfgrestore`, `vgcfgbackup`
- Metadata recovery when PV headers are corrupted
- Performance tuning: alignment, I/O schedulers, striping parameters

At the deepest level, LVM is a userspace interface to the kernel's Device Mapper framework. Understanding this stack lets you recover from failures that no higher-level tool can fix.

At this level you will master:

- **LVM striping**: `lvcreate -L 100G -i 4 -I 64K -n lv_stripe vg_data` creates a 4-way striped LV with 64KB stripe units. Striping spreads data across PVs for parallel reads. Unlike RAID, there is no redundancy — if one PV fails, all data is lost.
- **LVM RAID**: `lvcreate --type raid1 -m 1 -L 50G -n lv_mirror vg_data` creates a mirrored LV using the md driver. Supports raid1, raid5, raid6, raid10. This combines LVM flexibility with RAID redundancy.
- **Device Mapper**: LVM creates device-mapper targets (`/dev/dm-0`). The `dmsetup ls` command lists all targets. `dmsetup table` shows the mapping table. `dmsetup status` shows I/O statistics. This is how the kernel knows which physical blocks correspond to which logical blocks.
- **Recovery tools**: `pvck /dev/sdb` checks PV metadata integrity. `vgcfgbackup vg_data` saves VG metadata to a file. `vgcfgrestore vg_data` restores VG metadata from backup. These tools save you when metadata areas are corrupted.
- **Metadata corruption**: LVM stores metadata at the start of each PV. If it is overwritten (e.g., by creating a new partition table), the VG becomes invisible. Recovery involves finding the metadata copy in the PV's metadata area and restoring it.


[← Previous](15-section-12-troubleshooting-basic.md) | [↑ Index](index.md) | [Next →](17-section-9-lvm-striping.md)
