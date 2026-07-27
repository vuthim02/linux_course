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



---

[← Previous](21-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](23-whats-coming-in-part-32.md)
