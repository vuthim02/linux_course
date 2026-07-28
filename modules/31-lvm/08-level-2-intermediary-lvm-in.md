## ⭐ Level 2: Intermediary — LVM in Daily Administration

![LVM snapshot COW mechanism — copy-on-write preserves original data on first modification](https://upload.wikimedia.org/wikipedia/commons/6/6f/Lvm_snapshot.svg)

> **Level 2 Goal:** Shrink logical volumes safely, configure COW snapshots for backup/rollback, implement thin provisioning, set up LVM cache with SSD acceleration, encrypt LVs with LUKS, and perform common troubleshooting.

### What You'll Cover
- Shrinking LVs safely: unmount → `lvreduce` → remount
- COW snapshots: instant point-in-time copies for backup
- Thin provisioning: over-committing storage with `lvcreate --thin`
- LVM cache: accelerating HDD volumes with SSD cache pools
- LUKS encryption on logical volumes
- Common troubleshooting: missing PVs, broken VGs, filesystem errors

At this level you move beyond basic LV management into the features that make LVM truly powerful: snapshots, thin provisioning, and encryption.

At this level you will practice:

- **Shrinking LVs**: Always shrink the filesystem first, then the LV. For ext4: `umount /dev/vg/lv && resize2fs /dev/vg/lv 20G && lvreduce -L 20G /dev/vg/lv && mount /dev/vg/lv`. XFS cannot be shrunk — you must back up, recreate, and restore.
- **COW snapshots**: `lvcreate -L 5G -s -n snap_root /dev/vg/lv_root` creates a snapshot. The snapshot uses Copy-on-Write — when blocks on the original change, the old data is copied to the snapshot. Use for consistent backups of running systems.
- **Thin provisioning**: Create a thin pool: `lvcreate -L 100G -T vg/thin_pool`. Create thin LVs: `lvcreate -V 200G -T vg/thin_pool -n thin_vol`. You can allocate more virtual space than physical — but monitor usage to avoid running out.
- **LVM cache**: Add an SSD as a cache device: `lvcreate -L 10G -n cache_dev vg /dev/sdd` then `lvconvert --type cache --cachepool cache_dev /dev/vg/lv_data`. Hot data stays on SSD; cold data on HDD.
- **LUKS encryption**: `cryptsetup luksFormat /dev/vg/lv_data`, then `cryptsetup open /dev/vg/lv_data encrypted_vol`, then `mkfs.ext4 /dev/mapper/encrypted_vol`. Add to `/etc/crypttab` and `/etc/fstab` for automatic unlocking at boot.


[← Previous](07-section-5-filesystem-on-lvm.md) | [↑ Index](index.md) | [Next →](09-section-4-logical-volumes-shrinking.md)
