## ⭐ Level 2: Intermediary — Daily RAID Management

![mdadm RAID monitoring and disk failure recovery workflow](https://thelinuxclub.com/wp-content/uploads/2025/03/RAID-recovery-768x461.png)

*Monitoring disk health, identifying failed drives, and rebuilding arrays with mdadm (The Linux Club)*

> **Level 2 Goal:** Manage RAID arrays in production — add/remove drives, configure hot spares, handle failures, monitor health, and integrate with LVM.

### What You'll Cover
- Adding, removing, and replacing drives in a live array
- Hot spare configuration: automatic rebuild on failure
- Simulating and handling disk failures for practice
- Monitoring array health with `mdadm --detail` and `mdstat`
- Email alerts and `/etc/mdadm.conf` for persistence
- Integrating RAID arrays with LVM for flexible volume management

RAID management does not end at creation. In production, arrays need ongoing monitoring, drive replacements, and integration with higher-level storage tools.

At this level you will practice:

- **Drive management**: `mdadm /dev/md0 --add /dev/sdb` adds a drive. `mdadm /dev/md0 --fail /dev/sdb` marks a drive as failed. `mdadm /dev/md0 --remove /dev/sdb` removes it. Replace the failed drive and add the new one — the array rebuilds automatically.
- **Hot spares**: `mdadm --create /dev/md0 --level=1 --raid-devices=2 --spare-devices=1 /dev/sd[b-c] /dev/sdd` sets up a spare. When a drive fails, the spare is automatically incorporated and rebuild begins.
- **Failure simulation**: `mdadm --fail /dev/md0 /dev/sdb1` simulates a failure. Check `cat /proc/mdstat` to see the rebuild progress. This is safe to do on test arrays and essential for building muscle memory.
- **Monitoring**: `mdadm --detail /dev/md0` shows array state, sync progress, and member status. `/proc/mdstat` shows real-time rebuild progress. Configure email alerts in `/etc/mdadm.conf` with `MAILADDR admin@example.com`.
- **RAID + LVM**: Create RAID arrays first, then use them as PVs for LVM. This gives you both redundancy (RAID) and flexibility (LVM snapshots, resizing). `pvcreate /dev/md0` turns a RAID array into a physical volume.


[← Previous](05-section-3-creating-raid-arrays.md) | [↑ Index](index.md) | [Next →](07-section-4-managing-raid-arrays.md)
