## 📋 Command Reference by Level

### Level 1 Commands — Create & Inspect
| Command | Purpose |
|---------|---------|
| `cat /proc/mdstat` | Show live status of all arrays |
| `mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sda /dev/sdb /dev/sdc` | Create a RAID 5 array |
| `mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sda /dev/sdb /dev/sdc /dev/sdd` | Create a RAID 10 array |
| `mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb` | Create a RAID 1 mirror |
| `mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sda /dev/sdb` | Create a RAID 0 stripe |
| `mdadm --detail /dev/md0` | Show detailed array info |
| `mdadm --detail --scan` | Generate config lines for mdadm.conf |
| `mdadm --query /dev/sda` | Check if device is part of an array |
| `mdadm --examine /dev/sda` | Read raw superblock data |

### Level 2 Commands — Manage & Recover
| Command | Purpose |
|---------|---------|
| `mdadm --assemble /dev/md0 /dev/sda /dev/sdb /dev/sdc` | Assemble an array |
| `mdadm --assemble --scan` | Auto-discover and assemble all arrays |
| `mdadm --stop /dev/md0` | Stop an array |
| `mdadm --fail /dev/md0 /dev/sdb` | Mark a drive as failed |
| `mdadm --remove /dev/md0 /dev/sdb` | Remove a drive from an array |
| `mdadm --add /dev/md0 /dev/sdd` | Add a drive (as spare or replacement) |

### Level 3 Commands — Grow, Tune & Monitor
| Command | Purpose |
|---------|---------|
| `mdadm --grow /dev/md0 --raid-devices=4` | Grow array to more drives |
| `mdadm --grow /dev/md0 --level=6` | Migrate to different RAID level |
| `mdadm --grow /dev/md0 --bitmap=internal` | Add write-intent bitmap |
| `mdadm --grow /dev/md0 --chunk=128` | Change chunk size |
| `mdadm --monitor --scan --mail=admin@example.com` | Start monitoring with email |
| `mdadm --zero-superblock /dev/sda` | Wipe md superblock (destructive!) |

### Key Files

| File | Purpose |
|------|---------|
| `/proc/mdstat` | Live RAID status from kernel |
| `/etc/mdadm/mdadm.conf` | mdadm configuration |
| `/dev/md/*` | Device-mapper RAID device nodes |
| `/dev/disk/by-id/` | Persistent disk identifiers |
| `/dev/disk/by-path/` | Physical location identifiers |
| `/sys/block/md0/md/` | sysfs interface for md driver |
| `/proc/sys/dev/raid/speed_limit_min` | Minimum resync speed (KB/sec) |
| `/proc/sys/dev/raid/speed_limit_max` | Maximum resync speed (KB/sec) |

### sysfs md Interface

The sysfs directory `/sys/block/md0/md/` exposes fine-grained control:

```bash
# List attributes
ls /sys/block/md0/md/

# Check array state
cat /sys/block/md0/md/array_state

# Check sync status
cat /sys/block/md0/md/sync_action

# Trigger a check
echo check > /sys/block/md0/md/sync_action

# Trigger a repair (fixes mismatches found by check)
echo repair > /sys/block/md0/md/sync_action

# Set sync speed (same as /proc/sys/proc interface)
echo 50000 > /sys/block/md0/md/sync_speed_max
```

### Hardware RAID Management Commands

| Command | Purpose |
|---------|---------|
| `storcli64 show` | List Broadcom/LSI RAID controllers |
| `storcli64 /c0 /vall show` | List virtual drives on controller 0 |
| `storcli64 /c0 /eall /sall show` | List physical drives |
| `storcli64 /c0 add vd type=raid5 drives=0:0,0:1,0:2` | Create RAID 5 virtual drive |
| `storcli64 /c0 /fall import` | Import foreign configuration |
| `storcli64 /c0 /bbu show` | Check BBU status |
| `perccli64 /c0 /vall show` | Dell PERC: list virtual drives |
| `hpssacli ctrl slot=0 ld all show` | HP Smart Array: list logical drives |
| `hpssacli ctrl slot=0 pd all show` | HP Smart Array: list physical drives |

---



---

[← Previous](18-level-3-deep-understanding-how.md) | [↑ Index](index.md) | [Next →](20-whats-coming-in-part-31.md)
