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





[← Previous](02-level-1-basic-lvm-fundamentals.md) | [↑ Index](index.md) | [Next →](04-section-2-physical-volumes.md)
