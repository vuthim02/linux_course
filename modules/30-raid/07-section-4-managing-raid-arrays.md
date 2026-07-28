## 🔍 Section 4: Managing RAID Arrays

### /proc/mdstat — Your First Health Check

The file `/proc/mdstat` is the single most important tool for RAID monitoring. It is a virtual file created by the kernel md driver in real time:

```bash
cat /proc/mdstat
```

```
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
md0 : active raid5 sdd[3] sdc[2] sdb[1] sda[0]
      5860545024 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/4] [UUUU]
      
md1 : active raid1 sde[0] sdf[1]
      976762584 blocks super 1.2 [2/2] [UU]

unused devices: <none>
```

Reading this output:
- `[4/4]` = 4 devices out of 4 are active
- `[UUUU]` = all devices are Up (U = up, _ = failed/removed)
- `raid5` = level 5
- `512k chunk` = stripe size

### mdadm --detail

For comprehensive status of an array:

```bash
mdadm --detail /dev/md0
```

```
/dev/md0:
           Version : 1.2
     Creation Time : Tue Jun 16 14:23:45 2026
        Raid Level : raid5
        Array Size : 5860545024 (5589.34 GiB 6001.89 GB)
     Used Dev Size : 1953515008 (1863.11 GiB 2000.41 GB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Tue Jun 23 16:30:12 2026
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : server:0
              UUID : 3f0d6e7a:8b1c2d3e:4f5a6b7c:8d9e0f1a
            Events : 2478

    Number   Major   Minor   RaidDevice State
       0       8        0        0      active sync   /dev/sda
       1       8       16        1      active sync   /dev/sdb
       2       8       32        2      active sync   /dev/sdc
       3       8       48        3      active sync   /dev/sdd
```

### mdadm --query

Quick check on any block device:

```bash
mdadm --query /dev/sda
/dev/sda: is an md component device, part of /dev/md0

mdadm --query /dev/md0
/dev/md0: is an md array
```

### Adding and Removing Drives

```bash
# Add a drive to an existing array (expands capacity for RAID 1/5/6 if supported)
mdadm --add /dev/md0 /dev/sde

# Remove a drive from an array (must be failed or spare)
mdadm --remove /dev/md0 /dev/sde

# Mark a drive as failed
mdadm --fail /dev/md0 /dev/sdb
```

### Stopping and Starting Arrays

```bash
# Stop an array
mdadm --stop /dev/md0

# Start/assemble an array
mdadm --assemble /dev/md0 /dev/sda /dev/sdb /dev/sdc /dev/sdd
# Or scan for all arrays
mdadm --assemble --scan
```

### Resync Speed Control

The kernel resync can be throttled. These files control the speed:

```bash
# Check current limits
cat /proc/sys/dev/raid/speed_limit_min
cat /proc/sys/dev/raid/speed_limit_max

# Set minimum resync speed (KB/sec)
echo 10000 > /proc/sys/dev/raid/speed_limit_min

# Set maximum resync speed (KB/sec)
echo 200000 > /proc/sys/dev/raid/speed_limit_max
```

Typical values: min=1000 (1 MB/s), max=200000 (200 MB/s). Lower max during production hours to minimize performance impact; raise it during maintenance windows.





[← Previous](06-level-2-intermediary-daily-raid.md) | [↑ Index](index.md) | [Next →](08-section-5-spare-disks-hot.md)
