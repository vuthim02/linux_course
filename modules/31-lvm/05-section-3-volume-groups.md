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



---

[← Previous](04-section-2-physical-volumes.md) | [↑ Index](index.md) | [Next →](06-section-4-logical-volumes-creation.md)
