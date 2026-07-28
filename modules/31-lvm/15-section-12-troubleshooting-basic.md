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





[← Previous](14-section-11-lvm-and-encryption.md) | [↑ Index](index.md) | [Next →](16-level-3-advanced-lvm-internals.md)
