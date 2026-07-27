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



---

[← Previous](17-section-9-lvm-striping.md) | [↑ Index](index.md) | [Next →](19-section-12-troubleshooting-advanced.md)
