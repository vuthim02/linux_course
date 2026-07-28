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





[← Previous](10-section-5-filesystem-alignment-for.md) | [↑ Index](index.md) | [Next →](12-section-7-thin-provisioning.md)
