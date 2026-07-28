## ⭐ Level 1: Basic — LVM Fundamentals and Initial Setup

![LVM abstraction stack: Physical Volumes → Volume Groups → Logical Volumes](https://upload.wikimedia.org/wikipedia/commons/e/e6/Lvm.svg)

> **Level 1 Goal:** Understand the LVM architecture (PV → VG → LV), initialize physical volumes, create volume groups, create and extend logical volumes, and build filesystems on top of them.

### What You'll Cover
- The three layers: Physical Volumes (PV), Volume Groups (VG), Logical Volumes (LV)
- Initializing disks/partitions as PVs with `pvcreate`
- Creating VGs with `vgcreate` and adding PVs with `vgextend`
- Creating LVs with `lvcreate` and extending them online with `lvextend`
- Building filesystems (`mkfs`) and mounting LVs
- Examining the stack: `pvs`, `vgs`, `lvs`, and `lsblk`

LVM adds a layer of abstraction between physical disks and filesystems. Instead of creating a filesystem directly on `/dev/sda1`, you create a PV, add it to a VG, and carve out LVs from the VG.

At this level you will learn:

- **PV → VG → LV**: A Physical Volume (PV) is a disk or partition initialized with `pvcreate`. A Volume Group (VG) aggregates multiple PVs into a pool. Logical Volumes (LVs) are carved from the VG and can be resized, moved, or snapshotted.
- **Creating PVs**: `pvcreate /dev/sdb /dev/sdc` initializes both disks. `pvs` shows all PVs, their VG membership, and free space. `pvdisplay` shows detailed per-PV information.
- **Creating VGs**: `vgcreate vg_data /dev/sdb /dev/sdc` creates a VG from two disks. `vgextend vg_data /dev/sdd` adds another disk. `vgs` shows VG size, free PE count, and PV count.
- **Creating LVs**: `lvcreate -L 50G -n lv_home vg_data` creates a 50GB LV. `lvcreate -l 100%FREE -n lv_data vg_data` uses all free space. Extend online with `lvextend -L +20G /dev/vg_data/lv_home` and `resize2fs` (ext4) or `xfs_growfs` (XFS).
- **Mounting**: `mkfs.ext4 /dev/vg_data/lv_home && mount /dev/vg_data/lv_home /home`. Add to `/etc/fstab` for persistence. Use `/dev/vg_data/lv_home` paths (stable) not `/dev/dm-0` (changes on reboot).


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-what-is-lvm.md)
