## 🔍 Section 8: RAID Failure Simulation and Recovery

### Simulating a Disk Failure

```bash
# 1. Check current state
mdadm --detail /dev/md0

# 2. Mark a drive as failed
mdadm --fail /dev/md0 /dev/loop2

# 3. Confirm the failure
cat /proc/mdstat
mdadm --detail /dev/md0
```

Output after failure:
```
md0 : active raid5 loop3[3] loop2[1](F) loop1[0]
      313344 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/2] [U_U]
      
Number Major Minor RaidDevice State
   0     7      0        0      active sync   /dev/loop1
   1     7      0        1      faulty   /dev/loop2
   3     7      0        2      active sync   /dev/loop3
```

The `(F)` marks the failed device. The `[U_U]` shows device 1 is down.

### Removing the Failed Drive

```bash
mdadm --remove /dev/md0 /dev/loop2
```

After removal, the array runs in degraded mode. If this is RAID 5, you have NO redundancy. If RAID 6, you have one remaining parity. If RAID 1, you are running on one drive. If RAID 10, the mirror pair is down to one drive.

### Replacing and Rebuilding

```bash
# Add a replacement drive
mdadm --add /dev/md0 /dev/loop4

# Watch the rebuild
watch -n 1 cat /proc/mdstat
```

The kernel automatically starts rebuilding. During rebuild, performance is degraded — the resync process reads all remaining drives to reconstruct the missing data.

### Full Recovery Scenario

```bash
# Initial setup
for i in {1..4}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
    losetup /dev/loop$i /tmp/disk$i.img
done

# Create RAID 5
mdadm --create /dev/md0 --level=5 --raid-devices=3 --spare-devices=1 \
    /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4

# Create filesystem and test data
mkfs.ext4 /dev/md0
mount /dev/md0 /mnt/raidtest
dd if=/dev/urandom of=/mnt/raidtest/testfile bs=1M count=5

# Record checksum
sha256sum /mnt/raidtest/testfile > /root/testfile.sha256

# FAILURE! Kill loop2
mdadm --fail /dev/md0 /dev/loop2
mdadm --remove /dev/md0 /dev/loop2

# Hot spare (loop4) should automatically rebuild
# Wait for rebuild to complete
while grep -q "resync" /proc/mdstat; do sleep 5; done

# Verify data integrity
sha256sum -c /root/testfile.sha256

# The array is healthy and data survived
```

### Don't Remove the Wrong Drive

One of the most dangerous RAID mistakes: removing the WRONG drive during a rebuild or after a failure. Always triple-check serial numbers:

```bash
# Before failing a drive, confirm its identity
smartctl -i /dev/sdb | grep -i "serial"
mdadm --detail /dev/md0 | grep -B5 /dev/sdb
```

In a real data center, drives are labeled with physical location (bay number). The kernel also reports physical location:

```bash
ls -la /dev/disk/by-path/
# Shows drives by physical connector (e.g., pci-0000:00:1f.2-ata-3)
```





[← Previous](10-section-7-raid-10-stripe.md) | [↑ Index](index.md) | [Next →](12-section-9-monitoring-raid-health.md)
