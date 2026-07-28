## 🔍 Section 10: RAID and LVM

### Why Put LVM on Top of RAID?

RAID provides: reliability, performance, and device-level redundancy.
LVM provides: flexible volume management, snapshots, resizing, striping across arrays.

The recommended stack:

```
Filesystem (ext4/xfs)
    ↑
LVM logical volume (lv)
    ↑
LVM volume group (vg)
    ↑
Physical volumes (md0, md1, md2 — RAID arrays)
    ↑
md driver (RAID)
    ↑
Physical drives (/dev/sda, /dev/sdb, ...)
```

### Why NOT Put RAID on Top of LVM?

The reverse (LVM then RAID) is a bad idea because:
- LVM stripes would break RAID redundancy
- LVM snapshots mixed with RAID create complications
- The kernel md driver does not understand LVM layout

### Building RAID + LVM

```bash
# Create a RAID 5 array
mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd

# Initialize as LVM physical volume
pvcreate /dev/md0

# Create volume group
vgcreate vg_data /dev/md0

# Create logical volumes
lvcreate -n lv_database -L 100G vg_data
lvcreate -n lv_backups -L 200G vg_data

# Create filesystems
mkfs.ext4 /dev/vg_data/lv_database
mkfs.xfs /dev/vg_data/lv_backups

# Mount
mount /dev/vg_data/lv_database /var/lib/mysql
mount /dev/vg_data/lv_backups /var/backups
```

### Extending RAID + LVM

```bash
# 1. Add a new drive to the RAID array (grow it)
mdadm --add /dev/md0 /dev/sde
mdadm --grow /dev/md0 --raid-devices=4

# 2. After reshape, tell LVM the PV has grown
pvresize /dev/md0

# 3. Extend the logical volume
lvextend -L +50G /dev/vg_data/lv_database

# 4. Resize the filesystem
resize2fs /dev/vg_data/lv_database      # ext4
xfs_growfs /var/lib/mysql               # XFS
```

### RAID Metadata on LVM — Not Recommended

You CAN put an md superblock on an LVM logical volume, but this is extremely unusual and not recommended for production. The LVM layer adds complexity, and if the LV is ever removed or snapshotted, the md array becomes inconsistent.

### LVM RAID (md raid in LVM)

Modern LVM (since lvm2 2.02.132) has built-in RAID support. Instead of creating mdadm arrays and then adding them to LVM, you can create RAID directly in LVM:

```bash
# Create a RAID 1 logical volume (uses md internally)
lvcreate --type raid1 --mirrors 1 -L 10G -n lv_mirror vg_data /dev/sdb /dev/sdc

# Create a RAID 5 logical volume
lvcreate --type raid5 --stripes 2 -L 10G -n lv_raid5 vg_data /dev/sdb /dev/sdc /dev/sdd

# Create a RAID 10 logical volume
lvcreate --type raid10 --mirrors 1 --stripes 2 -L 10G -n lv_raid10 vg_data \
    /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

Behind the scenes, LVM RAID uses the same kernel md driver. But it manages the arrays automatically, creating the md devices and handling failures through LVM commands:

```bash
# Convert a linear LV to RAID 1
lvconvert --type raid1 --mirrors 1 vg_data/lv_linear

# Repair a failed RAID LV
lvconvert --repair vg_data/lv_mirror
```

The advantage is that LVM handles all the md configuration. The disadvantage is that you lose some fine-grained mdadm control.






[← Previous](12-section-9-monitoring-raid-health.md) | [↑ Index](index.md) | [Next →](14-level-3-advanced-raid-internals.md)
