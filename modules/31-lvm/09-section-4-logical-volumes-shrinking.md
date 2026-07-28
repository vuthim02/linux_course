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





[← Previous](08-level-2-intermediary-lvm-in.md) | [↑ Index](index.md) | [Next →](10-section-5-filesystem-alignment-for.md)
