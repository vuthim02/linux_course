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





[← Previous](06-section-4-logical-volumes-creation.md) | [↑ Index](index.md) | [Next →](08-level-2-intermediary-lvm-in.md)
