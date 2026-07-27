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



---

[← Previous](05-section-3-volume-groups.md) | [↑ Index](index.md) | [Next →](07-section-5-filesystem-on-lvm.md)
