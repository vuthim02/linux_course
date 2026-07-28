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





[← Previous](03-section-1-what-is-lvm.md) | [↑ Index](index.md) | [Next →](05-section-3-volume-groups.md)
