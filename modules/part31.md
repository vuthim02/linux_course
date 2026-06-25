# 🐧 Linux System Administrator — Complete Course
## Part 31 of ∞: LVM — Logical Volume Manager

---

> **Reverse Engineering Approach:** LVM was created to solve the fundamental rigidity of traditional disk partitioning. In the old model, you partition a disk, create a filesystem, and you're stuck — growing a partition means repartitioning, backing up, restoring, and hoping adjacent space exists. LVM reverses this by inserting a virtual abstraction layer between physical storage and the filesystem. Instead of filesystems talking directly to disk partitions, they talk to "logical volumes" that can span, shrink, grow, snapshot, mirror, stripe, cache, and thin-provision across underlying "physical volumes." This abstraction was inspired by HP-UX LVM and IBM AIX volume management, and was ported to Linux by Heinz Mauelshagen in 1998. Today, LVM2 (using the device-mapper kernel framework) is the standard volume manager on all major Linux distributions. Understanding LVM means understanding how to break the physical constraints of raw disks and build storage that adapts to your needs.

---

## 🎯 What You Will Achieve in Part 31

By the end of this part, you will:

| Level | Focus | Skills |
|-------|-------|--------|
| **Level 1 — Basic** | LVM Fundamentals & Initial Setup | Understand PV→VG→LV architecture, create PVs/VGs/LVs, build filesystems, extend LVs online |
| **Level 2 — Intermediary** | Daily Administration & Snapshots | Shrink LVs, create COW snapshots, thin provisioning, LVM cache, LUKS on LVM, basic troubleshooting |
| **Level 3 — Advanced** | Performance & Internals | Striped/RAID LVs, metadata recovery, Device Mapper internals, `dmsetup`, `pvck`, `vgcfgrestore` |

---

## ⭐ Level 1: Basic — LVM Fundamentals and Initial Setup

![LVM abstraction stack: Physical Volumes → Volume Groups → Logical Volumes](https://upload.wikimedia.org/wikipedia/commons/e/e6/Lvm.svg)

> **Level 1 Goal:** Understand the LVM architecture (PV → VG → LV), initialize physical volumes, create volume groups, create and extend logical volumes, and build filesystems on top of them.

---

## 🔍 Section 1: What Is LVM?

### The Abstraction Stack

```
┌──────────────────────────────────────────┐
│ Filesystem (ext4, XFS, btrfs, etc.)      │
├──────────────────────────────────────────┤
│ Logical Volume (LV)         /dev/vg/lv   │
├──────────────────────────────────────────┤
│ Volume Group (VG)           pool of space│
├──────────────────────────────────────────┤
│ Physical Volume (PV)        /dev/sda1    │
├──────────────────────────────────────────┤
│ Partition / Disk            /dev/sda     │
└──────────────────────────────────────────┘
```

*LVM abstraction stack: PV, VG, LV (Emanuel Duss / Wikimedia Commons / CC-BY-SA-3.0)*

### The Four Key Concepts

| Concept | Abbreviation | Description |
|---------|-------------|-------------|
| **Physical Volume** | PV | A block device initialized for LVM. Has a header with metadata. |
| **Volume Group** | VG | A pool of storage assembled from one or more PVs. |
| **Logical Volume** | LV | A virtual block device carved from a VG. Used like a disk partition. |
| **Physical Extent** | PE | The smallest allocatable unit on a PV (default 4 MiB). |
| **Logical Extent** | LE | The LV-side counterpart of a PE. Each LE maps to one PE. |

### Why LVM Exists

```
Traditional partitions:
  /dev/sda1 (100GB) → /         /dev/sda2 (200GB) → /var
  /dev/sda3 (300GB) → /home     /home fills up? Can't grow — no adjacent space
  Can't span /home across multiple disks

With LVM:
  PV: /dev/sda1, /dev/sdb1, /dev/sdc1 → VG: vg_data (pooled)
    ├─ LV root     (100GB) → /
    ├─ LV var      (200GB) → /var
    ├─ LV home     (200GB) → /home  (grow with lvextend + resize2fs)
    └─ LV backups  (400GB) → /backups  (spans 3 disks)
```

### PE Size and Alignment

```
PE Size = granularity of allocation in the VG (default 4 MiB)
PE Size × Max PE count (65534) = Max VG size
  4 MiB × 65534 = ~256 GiB
  16 MiB × 65534 = ~1 TiB
  128 MiB × 65534 = ~8 TiB

Rule of thumb: PE size = VG size / 65534, rounded up to power of 2
```

```bash
# Check alignment (should be 1 MiB boundary)
pvs -o +pv_pe_start

# Create aligned partition
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary 1MiB 100%
```

### LVM Metadata

Every PV stores metadata replicated across all PVs in a VG:

```
Metadata locations:
  └─ PV header: first 4 KiB (LABEL + PV descriptor)
  └─ VG metadata: text format, stored in PV metadata area
      └─ PV list, VG name, LV definitions, PE/LE mappings
  └─ Backup: /etc/lvm/backup/
  └─ Archive: /etc/lvm/archive/ (every change creates a versioned copy)
```

---

## 🔍 Section 2: Physical Volumes

### pvcreate

```bash
sudo pvcreate /dev/sdb
sudo pvcreate /dev/sdc1
sudo pvcreate --dataalignment 2048K /dev/sdd   # Custom alignment
sudo pvcreate --metadatasize 2m /dev/sde       # Metadata size
```

### pvs / pvdisplay

```bash
pvs                                    # Quick summary
pvs -o pv_name,pv_size,pv_free,pv_used,pe_size,pe_count,pv_uuid
pvs -o +pv_pe_start,vg_name
pvdisplay /dev/sdb                     # Full details
pvs --reportformat json                # Machine readable
```

### pvremove

```bash
sudo pvremove /dev/sdb                 # Remove LVM label
sudo pvremove -ff /dev/sdb             # Force removal
sudo wipefs -a /dev/sdb                # Complete wipe
```

### pvresize

```bash
# After growing the underlying block device (VM disk resize, etc.)
echo 1 | sudo tee /sys/block/sdb/device/rescan
sudo pvresize /dev/sdb
pvs
```

### pvchange

```bash
sudo pvchange -x n /dev/sdb    # Prohibit allocation on this PV
sudo pvchange -x y /dev/sdb    # Allow allocation again
```

---

## 🔍 Section 3: Volume Groups

### vgcreate

```bash
sudo vgcreate vg_data /dev/sdb                          # Single PV
sudo vgcreate vg_data /dev/sdb /dev/sdc /dev/sdd        # Multiple PVs
sudo vgcreate --physicalextentsize 16M vg_data /dev/sdb # Custom PE size
```

### vgs / vgdisplay

```bash
vgs
vgs -o vg_name,vg_size,vg_free,vg_extent_size,pv_count,lv_count
vgdisplay vg_data
```

### vgextend / vgreduce

```bash
sudo vgextend vg_data /dev/sdd                   # Add PV
sudo vgreduce vg_data /dev/sdb                   # Remove empty PV
sudo pvmove /dev/sdb /dev/sdd                    # Move data off PV first
sudo vgreduce --removemissing vg_data            # Remove dead PVs
```

### vgremove / vgchange

```bash
sudo vgremove vg_data
sudo vgchange -ay vg_data                        # Activate
sudo vgchange -an vg_data                        # Deactivate
sudo vgchange --alloc cling vg_data              # Change allocation
```

### VG Splitting and Merging

```bash
sudo vgsplit vg_data vg_split /dev/sdd           # Split
sudo vgmerge vg_data vg_split                    # Merge (same PE size)
```

---

## 🔍 Section 4: Logical Volumes — Creation and Growth

### lvcreate

```bash
sudo lvcreate -L 10G -n lv_home vg_data          # 10 GiB LV
sudo lvcreate -l 100%FREE -n lv_data vg_data     # All free space
sudo lvcreate -l 50%VG -n lv_data vg_data        # 50% of VG
sudo lvcreate -l 50%FREE -n lv_data vg_data      # 50% of remaining
```

### lvs / lvdisplay

```bash
lvs
lvs -o lv_name,lv_size,lv_attr,seg_type,data_percent,metadata_percent
lvs -a                                           # Include internal LVs (thin, cache)
lvdisplay vg_data/lv_home
```

### lvextend

```bash
sudo lvextend -L +5G vg_data/lv_home             # Add 5G
sudo lvextend -L 50G vg_data/lv_home             # Set to 50G
sudo lvextend -l +50%FREE vg_data/lv_home        # Add half of remaining
sudo lvextend -r -L +5G vg_data/lv_home          # Extend + resize fs
```

---

## 🔍 Section 5: Filesystem on LVM — Setup and Growth

### mkfs and Mount

```bash
sudo mkfs.ext4 /dev/vg_data/lv_home
sudo mkfs.xfs /dev/vg_data/lv_data
sudo mount /dev/vg_data/lv_home /home

# Persistent mount in /etc/fstab
echo "/dev/mapper/vg_data-lv_home  /home  ext4  defaults  0  2" | sudo tee -a /etc/fstab
```

### Growing the Filesystem

```bash
# ext4 — online grow
sudo lvextend -L +5G /dev/vg_data/lv_home
sudo resize2fs /dev/vg_data/lv_home

# XFS — must be mounted
sudo lvextend -L +5G /dev/vg_data/lv_data
sudo xfs_growfs /mount/point

# One-liner (ext4)
sudo lvextend -r -L +5G /dev/vg_data/lv_home
```

---

## ⭐ Level 2: Intermediary — LVM in Daily Administration

![LVM snapshot COW mechanism — copy-on-write preserves original data on first modification](https://upload.wikimedia.org/wikipedia/commons/6/6f/Lvm_snapshot.svg)

> **Level 2 Goal:** Shrink logical volumes safely, configure COW snapshots for backup/rollback, implement thin provisioning, set up LVM cache with SSD acceleration, encrypt LVs with LUKS, and perform common troubleshooting.

---

## 🔍 Section 4: Logical Volumes — Shrinking, Resizing, and Striping

### lvreduce

**Always shrink the filesystem BEFORE the LV.**

```bash
# ext4 shrink procedure:
sudo umount /dev/vg_data/lv_home
sudo e2fsck -f /dev/vg_data/lv_home
sudo resize2fs /dev/vg_data/lv_home 20G          # Shrink fs to 20G
sudo lvreduce -L 20G /dev/vg_data/lv_home        # Shrink LV to match
sudo mount /dev/vg_data/lv_home /home

# XFS CANNOT BE SHRUNK — must backup, destroy, recreate, restore
```

### lvresize / lvremove

```bash
sudo lvresize -L 30G vg_data/lv_home             # Set exact size
sudo lvresize -r -L +10G vg_data/lv_home         # Grow + fs
sudo lvremove vg_data/lv_home                    # Delete
```

### Linear vs Striped

```bash
# Linear — fills PVs sequentially
sudo lvcreate -L 10G -n lv_linear vg_data

# Striped — stripes across PVs for performance
sudo lvcreate --type striped -i 2 -I 64 -L 20G -n lv_stripe vg_data
# -i 2: 2 stripes (2+ PVs required)
# -I 64: stripe size 64 KiB
```

### LV Attributes Decoding

```
lvs -o lv_attr: 9-character string
Pos 1: Type (l=linear, s=striped, r=raid, m=mirror, t=thin, c=cache)
Pos 2: Permissions (w=write, r=read-only)
Pos 3: Allocation (a=anywhere, c=contiguous, i=inherit, n=normal)
Pos 4: Fixed minor (m=set, -=no)
Pos 5: State (a=active, s=suspended)
Pos 6: Device (o=open, -=closed)
Pos 7: Target (t=thin, C=cache, m=mirror, s=striped, r=raid)
Pos 8: Zero (z=zero, -=non-zero)
Pos 9: Health (p=partial, X=inconsistent, m=MISSING, R=refresh)
```

---

## 🔍 Section 5: Filesystem Alignment for Striped LVs

```bash
# If LV is striped across 4 PVs with 64K stripe:
sudo mkfs.ext4 -E stride=16,stripe_width=64 /dev/vg_data/lv_stripe
# stride = 64K / 4K block = 16; stripe_width = 16 × 4 = 64

sudo mkfs.xfs -d su=64k,sw=4 /dev/vg_data/lv_stripe
```

---

## 🔍 Section 6: LVM Snapshots

### COW Snapshots

Snapshots use copy-on-write: when a block on the origin is modified, the old data is copied to the snapshot store first.

```
Initial: [A][B][C][D][E]  →  Snapshot: (empty COW map)
Write D→D': [A][B][C][D'][E]  →  Snapshot store: [D] (old data preserved)
Read snapshot: D comes from store, A/B/C/E come from origin
```

### Creating Snapshots

```bash
sudo lvcreate -s -L 5G -n lv_data_snap /dev/vg_data/lv_data
# -s = snapshot, -L = COW store size (15-20% of origin recommended)

# Mount snapshot (read-only)
sudo mkdir /mnt/snapshot
sudo mount -o ro /dev/vg_data/lv_data_snap /mnt/snapshot
```

### Backup with Snapshots

```bash
sudo lvcreate -s -L 10G -n db_snap /dev/vg_data/lv_db
sudo mount -o ro /dev/vg_data/db_snap /mnt/db_snap
sudo tar -czf /backup/db_$(date +%Y%m%d).tar.gz -C /mnt/db_snap/ .
sudo umount /mnt/db_snap
sudo lvremove -f vg_data/db_snap
```

### Rollback

```bash
sudo umount /dev/vg_data/lv_data
sudo lvconvert --merge /dev/vg_data/lv_data_snap
sudo mount /dev/vg_data/lv_data /mount/point
```

### Monitoring Snapshots

```bash
lvs -a -o lv_name,snap_percent,data_percent,lv_size,origin,origin_size
# snap_percent > 80%: extend or risk losing the snapshot
# At 100%: snapshot becomes INACTIVE and is dropped

# Extend a snapshot
sudo lvextend -L +5G /dev/vg_data/lv_data_snap
```

---

## 🔍 Section 7: Thin Provisioning

Thin provisioning lets you create LVs with virtual sizes larger than available physical space. Space is allocated on-demand from a thin pool.

### Thin Pool Architecture

```
┌──────────────────────────────────────────────┐
│ Thin Pool                                     │
│  ┌──────────────────┐  ┌──────────────────┐   │
│  │ data LV (actual)  │  │ metadata LV      │   │
│  └────────┬─────────┘  └────────┬─────────┘   │
│           └──────────┬──────────┘              │
│                      │                          │
│  ┌───────────────────┼───────────────────┐     │
│  │                   │                   │      │
│ thin_lv_1 (2T virt)  thin_lv_2 (500G)    snap  │
│  50G actual          30G actual           1G    │
└────────────────────────────────────────────────┘
```

### Creating Thin Pool and Thin LVs

```bash
# Create thin pool
sudo lvcreate --type thin-pool -L 100G -n thin_pool vg_data

# Create thin LVs
sudo lvcreate --type thin -V 2T -n thin_lv_1 vg_data/thin_pool
sudo lvcreate --type thin -V 500G -n thin_lv_2 vg_data/thin_pool

# Monitor pool usage
lvs -a -o lv_name,lv_size,data_percent,metadata_percent,pool_lv
```

### Extending Thin Pool

```bash
sudo lvextend -L +50G vg_data/thin_pool                 # Data
sudo lvextend --poolmetadatasize +1G vg_data/thin_pool  # Metadata
```

### dmeventd Auto-Extend

Edit `/etc/lvm/lvm.conf`:
```
thin_pool_autoextend_threshold = 80
thin_pool_autoextend_percent = 20
```

```bash
sudo lvchange --monitor y vg_data/thin_pool
```

### Overcommit Warning

If data_percent reaches 100%, ALL thin LVs go read-only. Monitor daily and never run > 80% without auto-extend configured.

---

## 🔍 Section 8: LVM Cache

LVM cache accelerates a slow device (HDD) with a fast device (SSD).

### Creating a Cache LV

```bash
# Method 1: Two-step
sudo lvcreate -L 500G -n lv_origin vg_data /dev/sdb       # Slow
sudo lvcreate -L 50G -n lv_cache vg_data /dev/sdc         # Fast
sudo lvconvert --type cache --cachepool vg_data/lv_cache vg_data/lv_origin

# Check status
lvs -a -o lv_name,lv_attr,size,pool_lv,cache_mode,cache_policy,cache_read_hits,cache_read_misses
```

### Cache Modes

```bash
# writethrough (default) — writes to both cache+origin. Safe, slower writes.
sudo lvchange --cachemode writethrough vg_data/lv_origin

# writeback — writes to cache only, flushed later. Fast writes, risk on cache failure.
sudo lvchange --cachemode writeback vg_data/lv_origin

# passthrough — reads from origin, writes bypass cache. Maintenance mode.
```

### Removing Cache

```bash
sudo lvconvert --splitcache vg_data/lv_origin              # Detach
sudo lvremove vg_data/lv_cache                            # Remove pool
```

---

## 🔍 Section 11: LVM and Encryption

### LUKS on LVM

Encrypt specific LVs (e.g., /home) while leaving others unencrypted:

```
┌──────────────────┐
│ Filesystem       │
├──────────────────┤
│ LUKS (dm-crypt) │
├──────────────────┤
│ LV               │
├──────────────────┤
│ VG / PV          │
└──────────────────┘
```

```bash
sudo lvcreate -L 20G -n lv_secure vg_data
sudo cryptsetup luksFormat /dev/vg_data/lv_secure
sudo cryptsetup open /dev/vg_data/lv_secure secure
sudo mkfs.ext4 /dev/mapper/secure
sudo mount /dev/mapper/secure /mnt/secure
```

### LVM on LUKS

Full-disk encryption — LVM on top of encrypted devices:

```
┌──────────────────┐
│ Filesystem       │
├──────────────────┤
│ LV               │
├──────────────────┤
│ VG               │
├──────────────────┤
│ PV               │
├──────────────────┤
│ LUKS (dm-crypt) │
├──────────────────┤
│ Block device     │
└──────────────────┘
```

```bash
sudo cryptsetup luksFormat /dev/sdb
sudo cryptsetup open /dev/sdb crypt_disk
sudo pvcreate /dev/mapper/crypt_disk
sudo vgcreate vg_encrypted /dev/mapper/crypt_disk
sudo lvcreate -L 50G -n lv_data vg_encrypted
sudo mkfs.ext4 /dev/vg_encrypted/lv_data
```

---

## 🔍 Section 12: Troubleshooting — Basic

### lvmdiskscan

```bash
sudo lvmdiskscan                          # All block devices
sudo lvmdiskscan -l                       # PVs only
```

### Activating LVs with Missing PVs

```bash
sudo vgchange -ay --partial vg_data       # Activate with missing PVs
# Data on the missing PV will be inaccessible; partial I/O errors may occur
```

### Recovering from PV Failure

```bash
# Scenario: /dev/sdb is dead
pvs                                     # Shows "unknown device" or missing
vgs -o +partial                         # Shows "missing"

# Option 1: Remove missing PV (if data is on remaining PVs)
sudo vgreduce --removemissing --force vg_data

# Option 2: Replace with new disk (for RAID LVs)
sudo pvcreate /dev/sdd
sudo vgextend vg_data /dev/sdd
sudo lvconvert --replace /dev/sdb vg_data/lv_raid1 /dev/sdd

# Option 3: Restore metadata from backup
sudo vgcfgrestore -f /etc/lvm/backup/vg_data vg_data
```

---

## ⭐ Level 3: Advanced — LVM Internals and Performance Tuning

![Device Mapper kernel stack — LVM2 is built on the Linux device-mapper framework](https://upload.wikimedia.org/wikipedia/commons/6/6f/Lvm_snapshot.svg)

> **Level 3 Goal:** Configure striped LVs with optimal alignment, deploy LVM RAID (raid1/5/6/10), recover from PV failures using low-level tools (`dmsetup`, `pvck`, `vgcfgrestore`), understand the Device Mapper kernel layer, and tune LVM for performance.

---

## 🔍 Section 9: LVM Striping

Striping spreads data across multiple PVs, improving sequential I/O throughput.

### Creating Striped LVs

```bash
# 2-way stripe
sudo lvcreate --type striped -i 2 -I 64 -L 100G -n lv_stripe vg_data

# 4-way stripe on specific PVs
sudo lvcreate --type striped -i 4 -I 128 -L 200G -n lv_stripe4 vg_data /dev/sd{b,c,d,e}

# Check stripe layout
lvs -a -o lv_name,seg_type,stripes,stripe_size,devices
```

| Workload | Stripe Size |
|----------|-------------|
| OLTP (random, small) | 16-64 KiB |
| File server (mixed) | 64-128 KiB |
| Data warehouse (sequential) | 256-512 KiB |
| Video streaming | 1 MiB |

Converting a linear LV to striped requires creating a new LV and copying data:

```bash
sudo lvcreate --type striped -i 4 -I 64 -L 200G -n lv_stripe_new vg_data
sudo dd if=/dev/vg_data/lv_linear of=/dev/vg_data/lv_stripe_new bs=4M status=progress
sudo lvremove vg_data/lv_linear
sudo lvrename vg_data/lv_stripe_new lv_linear
```

---

## 🔍 Section 10: LVM RAID

LVM RAID integrates MD RAID into LVM. Uses `md` kernel layer underneath, managed by LVM metadata.

### RAID Types

| Type | Min PVs | Usable Capacity |
|------|---------|-----------------|
| raid1 | 2 | 1/N |
| raid4 | 3 | (N-1)/N |
| raid5 | 3 | (N-1)/N |
| raid6 | 4 | (N-2)/N |
| raid10 | 4 | N/2 |

### Creating RAID LVs

```bash
# RAID 1 (mirror)
sudo lvcreate --type raid1 -m 1 -L 50G -n lv_raid1 vg_data

# RAID 5 (striped+parity)
sudo lvcreate --type raid5 -i 3 -L 100G -n lv_raid5 vg_data

# RAID 6 (double parity)
sudo lvcreate --type raid6 -i 4 -L 200G -n lv_raid6 vg_data

# RAID 10 (striped mirrors)
sudo lvcreate --type raid10 -i 2 -m 1 -L 100G -n lv_raid10 vg_data
```

### Converting to RAID

```bash
# Linear → RAID 1
sudo lvconvert --type raid1 -m 1 vg_data/lv_linear

# Add another mirror copy
sudo lvconvert -m 2 vg_data/lv_mirror

# Reduce mirrors
sudo lvconvert -m 1 vg_data/lv_mirror

# RAID → linear
sudo lvconvert --type linear vg_data/lv_mirror
```

### Handling RAID Failures

```bash
# Check health
lvs -a -o +raid_mismatch_count,raid_sync_action,sync_percent

# Force check
sudo lvchange --syncaction check vg_data/lv_raid1
sudo lvchange --syncaction repair vg_data/lv_raid1

# Replace failed PV
sudo vgextend vg_data /dev/sdd
sudo lvconvert --replace /dev/sdb vg_data/lv_raid1 /dev/sdd
sudo vgreduce vg_data /dev/sdb
```

---

## 🔍 Section 12: Troubleshooting — Advanced

### dmsetup

```bash
sudo dmsetup ls                           # All DM devices
sudo dmsetup table                        # Mapping tables
sudo dmsetup table vg_data-lv_home        # Specific LV mapping
sudo dmsetup deps vg_data-lv_home         # Dependencies
sudo dmsetup info vg_data-lv_home         # Info
```

### pvck — Check PV Metadata

```bash
sudo pvck /dev/sdb                       # Check integrity
sudo pvck --dump /dev/sdb                # Dump metadata
sudo pvck --repair /dev/sdb              # Repair label
```

### vgcfgrestore — Restore VG Metadata

```bash
ls -la /etc/lvm/archive/vg_data_*       # List archive versions
sudo vgcfgrestore -l vg_data            # Show versions
sudo vgcfgrestore -f /etc/lvm/archive/vg_data_00005.vg vg_data  # Restore
```

### lvm.conf Filters

```bash
# /etc/lvm/lvm.conf — devices { filter = [...] }
# "a|pattern|" = accept, "r|pattern|" = reject, first match wins
# Example: accept sd* and nvme*, reject everything else
# filter = [ "a|/dev/sd.*|", "a|/dev/nvme.*|", "r|.*|" ]

# Test filter without modifying config:
sudo pvs --config 'devices { filter = [ "r|loop.*|", "a|.*|" ] }'
```

---

## 🧠 Deep Understanding — How LVM Really Works

### The Device Mapper Layer

LVM2 is built entirely on the Linux **Device Mapper** (dm) framework — a kernel subsystem for creating virtual block devices.

```
Kernel DM stack:
  Userspace (lvm2 tools → libdevmapper → ioctl)
    ↓
  Device Mapper Core (drivers/md/dm.c)
    ├── dm-linear    — linear mapping
    ├── dm-stripe    — striping
    ├── dm-mirror    — mirror/RAID1
    ├── dm-snapshot  — COW snapshots
    ├── dm-thin      — thin provisioning
    ├── dm-cache     — caching (SSD/HDD)
    ├── dm-raid      — RAID 4/5/6/10
    └── dm-crypt     — LUKS encryption
    ↓
  Block devices (sdX, nvmeXnY)
```

### How dmsetup Creates a Mapping

A linear LV's kernel table:

```
sudo dmsetup table vg_data-lv_home
0 20971520 linear 8:16 2048
│         │        │     └── Start sector on /dev/sdb (after PV header)
│         │        └── Device major:minor (8:16 = /dev/sdb)
│         └── Size in sectors (20971520 = 10 GiB)
└── Start sector of virtual device
```

LVM translates its metadata ("LV uses PE 0-2559 on PV /dev/sdb") into this table. Each PE = 8192 sectors (4 MiB). PEs start at sector 2048 (1 MiB alignment).

### dm-stripe Table

```
sudo dmsetup table vg_data-lv_stripe
0 41943040 striped 2 128 8:16 2048 8:32 2048
                    │   │   └─stripe1 └─stripe2
                    │   └── Stripe size in sectors (128×512=64K)
                    └── Number of stripes (=2)
```

### dm-snapshot — COW in Detail

```
Table: 0 20971520 snapshot 253:0 253:1 P 16
                           │      │     │ └── Chunk size (16 sectors = 8K)
                           │      │     └── P=persistent
                           │      └── COW device (dm-1)
                           └── Origin device (dm-0)

On first write to origin sector X:
1. Read origin data at sector X
2. Write old data to COW store
3. Update exception table: "sector X → COW chunk Y"
4. Write new data to origin
Read from snapshot: if sector in exception table → read from COW; else → read origin
```

### dm-thin — Thin Provisioning

Thin pool table:
```
0 209715200 thin-pool 253:3 253:4 128 1024
                       │      │    │    └── Low water mark
                       │      │    └── Block size (sectors)
                       │      └── Metadata device
                       └── Data device
```

**Thin write flow:**
1. Write to sector X of thin LV (ID 42)
2. dm-thin checks: "is sector X mapped for device 42?"
3. If no: allocate block from data device, update metadata
4. Write data to allocated block

### dm-cache Table

```
0 419430400 cache 253:0 253:1 253:2 512 1 writethrough smq
                   │      │      │    │           │        └── Policy
                   │      │      │    │           └── Cache mode
                   │      │      │    └── Block size (256K)
                   │      │      └── Cache metadata (SSD)
                   │      └── Cache data (SSD)
                   └── Origin (HDD)
```

### udev Integration

When LVM creates a DM device:
1. dmsetup ioctl creates the device -> kernel sends uevent
2. udev matches rules: `10-dm.rules`, `13-dm-disk.rules`, `56-lvm.rules`
3. udev creates `/dev/dm-N`, `/dev/vg_data/lv_home`, `/dev/mapper/vg_data-lv_home`

### VG Metadata Format

```lvm
# /etc/lvm/archive/vg_data_00001.vg (human-readable text)
vg_data {
    id = "abcdefg-hijklmn-opqrstu-..."
    seqno = 5
    format = "lvm2"
    extent_size = 8192           # 8192 sectors = 4 MiB PE
    physical_volumes {
        pv0 { id = "..."; device = "/dev/sdb"; pe_start = 2048; pe_count = 25599; }
    }
    logical_volumes {
        lv_home {
            segment1 {
                start_extent = 0
                extent_count = 2560    # 10 GiB
                type = "striped"
                stripe_count = 1
                stripes = [ "pv0", 0 ] # PV pv0, PE start 0
            }
        }
    }
}
```

### LVM Activation (Boot Sequence)

```
1. initramfs: load dm-mod → pvscan → vgscan → vgchange -ay
2. udev creates /dev/mapper/ and /dev/vg_name/ symlinks
3. Root filesystem mounted from LV
4. pivot_root → full system boot
5. lvm2-monitor.service starts dmeventd for auto-extend
```

### Key lvm.conf Sections

```
devices {
    filter = [ "a|sd.*|", "r|loop.*|", "r|.*|" ]
    global_filter = [ "r|/dev/dm-.*|", "a|.*|" ]
}
activation {
    snapshot_autoextend_threshold = 80
    snapshot_autoextend_percent = 20
    thin_pool_autoextend_threshold = 80
    thin_pool_autoextend_percent = 20
}

# Check current config:
sudo lvmconfig --type diff
sudo lvmconfig --type current
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### Level 1 Practices: LVM Fundamentals

---

### ✅ Practice 1: Create PVs, VG, and LV

```bash
mkdir -p ~/linux-course/part31 && cd ~/linux-course/part31

# Create 3 virtual disks
for i in 1 2 3; do dd if=/dev/zero of=disk$i.img bs=1M count=500; done
LOOP1=$(sudo losetup --show -fP disk1.img)
LOOP2=$(sudo losetup --show -fP disk2.img)
LOOP3=$(sudo losetup --show -fP disk3.img)

# PVs
sudo pvcreate $LOOP1 $LOOP2 $LOOP3
sudo pvs

# VG
sudo vgcreate vg_lab $LOOP1 $LOOP2
sudo vgs

# LV
sudo lvcreate -L 400M -n lv_first vg_lab
sudo lvs
ls -la /dev/vg_lab/lv_first
```

---

### ✅ Practice 2: Extend an LV

```bash
cd ~/linux-course/part31
sudo mkfs.ext4 /dev/vg_lab/lv_first
sudo mkdir -p /mnt/lv_first
sudo mount /dev/vg_lab/lv_first /mnt/lv_first
df -h /mnt/lv_first

sudo lvextend -L +200M /dev/vg_lab/lv_first
sudo resize2fs /dev/vg_lab/lv_first
df -h /mnt/lv_first

sudo umount /mnt/lv_first
```

---

### ✅ Practice 3: Reduce an LV

```bash
cd ~/linux-course/part31
sudo lvcreate -L 300M -n lv_shrink vg_lab
sudo mkfs.ext4 /dev/vg_lab/lv_shrink
sudo mount /dev/vg_lab/lv_shrink /mnt/lv_shrink
dd if=/dev/urandom of=/mnt/lv_shrink/fill.dat bs=1M count=50 2>/dev/null

# Shrink
sudo umount /mnt/lv_shrink
sudo e2fsck -f /dev/vg_lab/lv_shrink
sudo resize2fs /dev/vg_lab/lv_shrink 200M
sudo lvreduce -L 200M /dev/vg_lab/lv_shrink
sudo mount /dev/vg_lab/lv_shrink /mnt/lv_shrink
df -h /mnt/lv_shrink

sudo umount /mnt/lv_shrink
sudo lvremove -f vg_lab/lv_shrink
```

---

### Level 2 Practices: Snapshots, Thin Provisioning, Cache

---

### ✅ Practice 4: Snapshot and Rollback

```bash
cd ~/linux-course/part31
sudo lvcreate -L 200M -n lv_origin vg_lab
sudo mkfs.ext4 /dev/vg_lab/lv_origin
sudo mount /dev/vg_lab/lv_origin /mnt/lv_origin
echo "ORIGINAL DATA - version 1" > /mnt/lv_origin/important.txt

# Snapshot
sudo lvcreate -s -L 50M -n lv_snap /dev/vg_lab/lv_origin

# Modify origin
echo "MODIFIED DATA - version 2" > /mnt/lv_origin/important.txt

# Mount snapshot
sudo mkdir -p /mnt/lv_snap
sudo mount -o ro /dev/vg_lab/lv_snap /mnt/lv_snap
cat /mnt/lv_snap/important.txt  # Shows version 1

# Rollback
sudo umount /mnt/lv_origin /mnt/lv_snap
sudo lvconvert --merge /dev/vg_lab/lv_snap
sudo mount /dev/vg_lab/lv_origin /mnt/lv_origin
cat /mnt/lv_origin/important.txt  # Back to version 1

sudo umount /mnt/lv_origin
sudo lvremove -f vg_lab/lv_origin
```

---

### ✅ Practice 5: Thin Pool and Thin LV

```bash
cd ~/linux-course/part31
sudo lvcreate --type thin-pool -L 300M -n thin_pool vg_lab
lvs -a vg_lab -o lv_name,seg_type,lv_size

sudo lvcreate --type thin -V 1G -n thin_lv_1 vg_lab/thin_pool
sudo lvcreate --type thin -V 2G -n thin_lv_2 vg_lab/thin_pool
lvs vg_lab -o lv_name,lv_size,data_percent,pool_lv

sudo mkfs.ext4 /dev/vg_lab/thin_lv_1
sudo mkfs.ext4 /dev/vg_lab/thin_lv_2
sudo mount /dev/vg_lab/thin_lv_1 /mnt/thin1
sudo mount /dev/vg_lab/thin_lv_2 /mnt/thin2

lvs vg_lab/thin_pool -o +data_percent,metadata_percent

sudo umount /mnt/thin1 /mnt/thin2
sudo lvremove -f vg_lab/thin_lv_1 vg_lab/thin_lv_2 vg_lab/thin_pool
```

---

### ✅ Practice 6: Thin Snapshots

```bash
cd ~/linux-course/part31
sudo lvcreate --type thin-pool -L 500M -n pool vg_lab
sudo lvcreate --type thin -V 500M -n thin_orig vg_lab/pool
sudo mkfs.ext4 /dev/vg_lab/thin_orig
sudo mount /dev/vg_lab/thin_orig /mnt/thin_orig
echo "Original content" > /mnt/thin_orig/data.txt

# Thin snapshots are instant — no separate COW store sizing needed
sudo lvcreate -s -n thin_snap vg_lab/thin_orig
sudo mount -o ro /dev/vg_lab/thin_snap /mnt/thin_snap
cat /mnt/thin_snap/data.txt

echo "Modified!" > /mnt/thin_orig/data.txt
cat /mnt/thin_snap/data.txt  # Still "Original content"

sudo umount /mnt/thin_orig /mnt/thin_snap
sudo lvremove -f vg_lab/thin_orig vg_lab/thin_snap vg_lab/pool
```

---

### ✅ Practice 7: LVM Cache

```bash
cd ~/linux-course/part31
dd if=/dev/zero of=slow.img bs=1M count=400
dd if=/dev/zero of=fast.img bs=1M count=100
SLOW=$(sudo losetup --show -fP slow.img)
FAST=$(sudo losetup --show -fP fast.img)
sudo pvcreate $SLOW $FAST
sudo vgcreate vg_cache $SLOW $FAST

# Create origin + cache
sudo lvcreate -L 300M -n lv_slow vg_cache $SLOW
sudo lvcreate -L 50M -n lv_fast vg_cache $FAST
sudo lvconvert --type cache --cachepool vg_cache/lv_fast vg_cache/lv_slow

lvs -a vg_cache -o lv_name,size,pool_lv,cache_mode,cache_read_hits,cache_read_misses

# Test performance
sudo mkfs.ext4 /dev/vg_cache/lv_slow
sudo mount /dev/vg_cache/lv_slow /mnt/cache_test
time dd if=/dev/zero of=/mnt/cache_test/test bs=4K count=2000

# Switch to writeback
sudo lvchange --cachemode writeback vg_cache/lv_slow

sudo umount /mnt/cache_test
sudo lvconvert --splitcache vg_cache/lv_slow
sudo lvremove -f vg_cache/lv_slow vg_cache/lv_fast
sudo vgremove -f vg_cache && sudo pvremove $SLOW $FAST
sudo losetup -d $SLOW $FAST && rm -f slow.img fast.img
```

---

### ✅ Practice 8: Striped LV

```bash
cd ~/linux-course/part31
dd if=/dev/zero of=disk4.img bs=1M count=500
LOOP4=$(sudo losetup --show -fP disk4.img)
sudo pvcreate $LOOP4
sudo vgextend vg_lab $LOOP4

# 4-way stripe
sudo lvcreate --type striped -i 4 -I 64 -L 800M -n lv_stripe vg_lab
lvs -a -o lv_name,seg_type,stripes,stripe_size,devices

sudo mkfs.ext4 -E stride=16,stripe_width=64 /dev/vg_lab/lv_stripe
sudo mount /dev/vg_lab/lv_stripe /mnt/stripe
time dd if=/dev/zero of=/mnt/stripe/test bs=1M count=200 2>&1

sudo umount /mnt/stripe
sudo lvremove -f vg_lab/lv_stripe
```

---

### Level 3 Practices: RAID, Recovery, and Integration

---

### ✅ Practice 9: LVM RAID 1

```bash
cd ~/linux-course/part31
sudo lvcreate --type raid1 -m 1 -L 200M -n lv_mirror vg_lab
lvs -a vg_lab -o lv_name,seg_type,devices,raid_sync_action,sync_percent
lvs -a vg_lab  # Shows rimage_0, rmage_1, rmeta_0, rmeta_1

sudo mkfs.ext4 /dev/vg_lab/lv_mirror
sudo mount /dev/vg_lab/lv_mirror /mnt/mirror
echo "Mirror test" > /mnt/mirror/data.txt

sudo umount /mnt/mirror
sudo lvremove -f vg_lab/lv_mirror
```

---

### ✅ Practice 10: LVM RAID 5

```bash
cd ~/linux-course/part31
sudo lvcreate --type raid5 -i 3 -L 600M -n lv_raid5 vg_lab
lvs -a -o lv_name,seg_type,stripes,devices,sync_percent

sudo mkfs.ext4 /dev/vg_lab/lv_raid5
sudo mount /dev/vg_lab/lv_raid5 /mnt/raid5
df -h /mnt/raid5

sudo umount /mnt/raid5
sudo lvremove -f vg_lab/lv_raid5
```

---

### ✅ Practice 11: Missing PV Recovery

```bash
cd ~/linux-course/part31
sudo lvcreate -L 100M -n lv_recover vg_lab

# Simulate PV failure
DETACH="$LOOP3"
sudo vgchange -an vg_lab
sudo losetup -d $DETACH

# Attempt activation (fails without --partial)
sudo vgchange -ay vg_lab 2>&1 || echo "Expected failure — PV missing"
sudo vgchange -ay --partial vg_lab 2>&1 || true

# Re-attach
sudo losetup $DETACH disk3.img
sudo pvscan && sudo vgchange -ay vg_lab

sudo mount /dev/vg_lab/lv_recover /mnt/recover
echo "Recovered!" | sudo tee /mnt/recover/recovered.txt
sudo umount /mnt/recover
sudo lvremove -f vg_lab/lv_recover
```

---

### ✅ Practice 12: Metadata Backup and Restore

```bash
cd ~/linux-course/part31
ls -la /etc/lvm/backup/vg_lab
ls -la /etc/lvm/archive/
sudo head -50 /etc/lvm/backup/vg_lab

sudo lvcreate -L 50M -n lv_meta vg_lab
sudo lvcreate -L 50M -n lv_meta2 vg_lab
sudo vgcfgrestore -l vg_lab  # List versions

# Simulate checking a restore (dry-run)
sudo vgcfgrestore -t -f /etc/lvm/archive/vg_lab_00001.vg vg_lab 2>&1 || true

sudo lvremove -f vg_lab/lv_meta vg_lab/lv_meta2
```

---

### ✅ Practice 13: lvm.conf Filters

```bash
cd ~/linux-course/part31
sudo grep -A5 '^devices {' /etc/lvm/lvm.conf | grep -E 'filter|global_filter'

# Test filter that excludes loop devices (without modifying config)
sudo pvs --config 'devices { filter = [ "r|loop.*|", "a|.*|" ] }'
echo "Loop devices should be hidden above"
sudo pvs  # All devices visible
```

---

### ✅ Practice 14: pvck and dmsetup

```bash
cd ~/linux-course/part31
sudo pvck $LOOP1 $LOOP2 $LOOP3
sudo pvck --dump $LOOP1 | head -30

sudo dmsetup ls --tree
sudo dmsetup table
sudo dmsetup table vg_lab-lv_first
sudo dmsetup deps vg_lab-lv_first
sudo dmsetup info -c | head -5
```

---

### ✅ Practice 15: Real-World Integration — Multi-Disk Thin Pool + Snapshot + RAID

```bash
cd ~/linux-course/part31

# 6 virtual disks
for i in $(seq 1 6); do dd if=/dev/zero of=int_disk$i.img bs=1M count=500; done
LOOPS=""
for i in $(seq 1 6); do LOOPS="$LOOPS $(sudo losetup --show -fP int_disk$i.img)"; done

# PVs + VG
sudo pvcreate $LOOPS && sudo vgcreate vg_prod $LOOPS

# RAID 5 on 4 disks as storage pool
sudo lvcreate --type raid5 -i 4 -L 1600M -n lv_pool vg_prod

# Convert to thin pool
sudo lvconvert --type thin-pool vg_prod/lv_pool

# Thin LVs
sudo lvcreate --type thin -V 500M -n thin_app vg_prod/lv_pool
sudo lvcreate --type thin -V 500M -n thin_data vg_prod/lv_pool
sudo lvcreate --type thin -V 500M -n thin_logs vg_prod/lv_pool

# Format and mount
sudo mkfs.ext4 /dev/vg_prod/thin_app
sudo mkfs.ext4 /dev/vg_prod/thin_data
sudo mkfs.ext4 /dev/vg_prod/thin_logs
sudo mkdir -p /mnt/integration/{app,data,logs}
sudo mount /dev/vg_prod/thin_app /mnt/integration/app
sudo mount /dev/vg_prod/thin_data /mnt/integration/data
sudo mount /dev/vg_prod/thin_logs /mnt/integration/logs

echo "Config v1" > /mnt/integration/app/config.txt
dd if=/dev/urandom of=/mnt/integration/data/userdata.dat bs=1K count=1024

# Snapshots
sudo lvcreate -s -n snap_app vg_prod/thin_app
sudo lvcreate -s -n snap_data vg_prod/thin_data

# Modify originals
echo "Config v2" > /mnt/integration/app/config.txt
echo "more data" >> /mnt/integration/data/userdata.dat

# Mount snapshots to verify
sudo mkdir -p /mnt/int_snap/{app,data}
sudo mount -o ro /dev/vg_prod/snap_app /mnt/int_snap/app
sudo mount -o ro /dev/vg_prod/snap_data /mnt/int_snap/data

echo "=== CURRENT vs SNAPSHOT ==="
cat /mnt/integration/app/config.txt
cat /mnt/int_snap/app/config.txt

# Status overview
echo "" && echo "=== PVs ===" && pvs
echo "=== VGs ===" && vgs vg_prod
echo "=== LVs ===" && lvs -a vg_prod -o lv_name,lv_size,data_percent,origin,pool_lv
echo "=== RAID ===" && lvs -a vg_prod -o +raid_sync_action,sync_percent
echo "=== DM TREE ===" && sudo dmsetup ls | grep vg_prod

# Cleanup
sudo umount /mnt/int_snap/app /mnt/int_snap/data
sudo umount /mnt/integration/app /mnt/integration/data /mnt/integration/logs
sudo lvremove -f vg_prod/snap_app vg_prod/snap_data vg_prod/thin_app vg_prod/thin_data vg_prod/thin_logs
sudo lvremove -f vg_prod/lv_pool
sudo vgremove -f vg_prod && sudo pvremove $LOOPS
sudo losetup -d $LOOPS
rm -f int_disk*.img

echo "Integration practice complete!"
```

---

## 📋 Summary — Complete Command Reference for Part 31

### Level 1 Commands: Basic LVM

| Command | Action |
|---------|--------|
| `pvcreate /dev/sdb` | Initialize a PV |
| `pvs` | List PVs |
| `pvdisplay /dev/sdb` | Show PV details |
| `pvremove /dev/sdb` | Remove PV label |
| `pvresize /dev/sdb` | Rescan PV size |
| `pvchange -x n /dev/sdb` | Disallow allocation |
| `pvscan` | Scan all devices for PVs |
| `vgcreate vg_name /dev/sdb` | Create a VG |
| `vgs` | List VGs |
| `vgdisplay vg_name` | Show VG details |
| `vgextend vg_name /dev/sdc` | Add PV to VG |
| `vgreduce vg_name /dev/sdb` | Remove PV from VG |
| `vgremove vg_name` | Delete a VG |
| `vgchange -ay vg_name` | Activate VG |
| `vgchange -an vg_name` | Deactivate VG |
| `lvcreate -L 10G -n lv_name vg_name` | Create LV |
| `lvs` | List LVs |
| `lvdisplay vg_name/lv_name` | Show LV details |
| `lvextend -L +5G vg_name/lv_name` | Extend LV |
| `lvextend -r -L +5G vg_name/lv_name` | Extend LV + fs |
| `lvrename vg_name/lv_old lv_new` | Rename LV |
| `lvchange -p r vg_name/lv_name` | Set read-only |
| `lvchange -ay vg_name/lv_name` | Activate LV |
| `mkfs.ext4 /dev/vg_name/lv_name` | Format with ext4 |
| `mkfs.xfs /dev/vg_name/lv_name` | Format with XFS |
| `resize2fs /dev/vg_name/lv_name` | Grow ext4 |
| `xfs_growfs /mount/point` | Grow XFS |

### Level 2 Commands: Snapshots, Thin, Cache, Encryption

| Command | Action |
|---------|--------|
| `lvcreate -s -L 5G -n snap vg_name/lv` | Create snapshot |
| `lvconvert --merge vg/snapshot` | Merge snapshot |
| `lvreduce -L 20G vg_name/lv_name` | Shrink LV |
| `lvresize -L 50G vg_name/lv_name` | Unified resize |
| `lvremove vg_name/lv_name` | Delete LV |
| `lvcreate --type thin-pool -L 100G -n pool vg` | Thin pool |
| `lvcreate --type thin -V 1T vg/pool` | Thin LV |
| `lvconvert --type cache --cachepool vg/pool vg/origin` | Cache |
| `lvconvert --splitcache vg/lv` | Detach cache |
| `e2fsck -f /dev/vg_name/lv_name` | Force check ext4 |
| `pvmove /dev/sdb /dev/sdc` | Move data between PVs |
| `vgsplit vg_a vg_b /dev/sdb` | Split VG |
| `vgmerge vg_a vg_b` | Merge VGs |
| `vgreduce --removemissing vg_name` | Remove missing PVs |

### Level 3 Commands: Striped, RAID, Metadata Recovery, DM

| Command | Action |
|---------|--------|
| `lvcreate --type striped -i 4 -I 64 -L 100G vg` | Striped |
| `lvcreate --type raid1 -m 1 -L 50G vg` | RAID 1 |
| `lvcreate --type raid5 -i 4 -L 200G vg` | RAID 5 |
| `lvcreate --type raid6 -i 4 -L 200G vg` | RAID 6 |
| `lvcreate --type raid10 -i 2 -m 1 -L 100G vg` | RAID 10 |
| `lvconvert --type raid1 -m 1 vg/lv` | Convert to RAID |
| `lvchange --syncaction check vg/lv` | Check RAID sync |
| `pvck /dev/sdb` | Check PV metadata |
| `pvs -o +pv_pe_start` | Show PE alignment |
| `vgcfgbackup vg_name` | Backup VG metadata |
| `vgcfgrestore -f file vg_name` | Restore VG metadata |
| `dmsetup ls` | List DM devices |
| `dmsetup table` | Show mapping tables |
| `dmsetup deps /dev/dm-N` | Show dependencies |
| `dmsetup info` | Show DM info |
| `dmsetup remove /dev/dm-N` | Force remove |
| `lvmdiskscan` | List all block devices |
| `lvmconfig` | Show LVM configuration |
| `cat /proc/mdstat` | Check md RAID status |
| `lsblk` | Show block device tree |
| `blkid /dev/vg_name/lv_name` | Show LV UUID |

---

## 🚀 What's Coming in Part 32

**Part 32: Backup Strategies**

You will learn:
- The 3-2-1 backup rule and how to implement it
- Full, incremental, and differential backup strategies
- Backup tools: rsync, tar, dd, duplicity, BorgBackup, restic
- Database backup (MySQL/MariaDB, PostgreSQL) — logical and physical
- Backup to local storage, remote server, cloud (S3, Backblaze B2)
- Backup automation with cron, systemd timers
- Verification and restore testing
- Disaster recovery planning and documentation
- 15 hands-on practices covering all major backup tools

---

## 📝 Self-Test — Can You Answer These?

1. What are the three layers of LVM abstraction, and what problem does each solve?
2. What is the difference between a PE (Physical Extent) and an LE (Logical Extent)?
3. How does PE size affect maximum VG size and metadata overhead?
4. What command initializes a block device as a Physical Volume, and how do you verify it?
5. How do you extend a Volume Group to include a new disk?
6. What is the correct order of operations when shrinking an ext4 filesystem on a Logical Volume?
7. How does a COW (Copy-on-Write) snapshot work at the block level? What happens when the snapshot store fills up?
8. What is the difference between thin provisioning and thick (default) LVs? What are the risks of thin overcommit?
9. How does LVM cache work? What is writethrough vs writeback mode, and what are the tradeoffs?
10. When creating a striped LV, what does the `-i` and `-I` flag control, and what is the minimum number of PVs required?
11. How does LVM RAID 1 differ from a regular linear LV? What internal device names (rimage, rmeta) appear in `lvs -a`?
12. What is the difference between LUKS on LVM and LVM on LUKS? When would you choose each approach?
13. A PV in your VG has failed. What steps would you take to recover the VG and its LVs?
14. What does `dmsetup table` show, and how does a linear mapping table translate LV blocks to physical disk sectors?
15. What is the purpose of `dmeventd`, and what auto-extend capabilities does it provide?

**Score:** 12/15 correct = ready for Part 32.

---

*Linux SysAdmin Course | Part 31 of ∞ | Reverse Engineering Approach*
*Previous → Part 30: RAID*
*Next → Part 32: Backup Strategies*

[← Previous](part30.md) | [Next →](part32.md)
