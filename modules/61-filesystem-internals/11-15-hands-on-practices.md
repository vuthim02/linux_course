## 15 Hands-On Practices

### Practice 1: Inspect Inode Structure

```bash
# Create test filesystem
dd if=/dev/zero of=/tmp/test.img bs=1M count=100
sudo mkfs.ext4 /tmp/test.img
mkdir /tmp/testmount
sudo mount /tmp/test.img /tmp/testmount

# Create files and inspect inodes
touch /tmp/testmount/file{1..100}
ls -i /tmp/testmount/ | head -20
stat /tmp/testmount/file1

# Check inode table
sudo dumpe2fs /tmp/test.img | grep -A 5 "Inode table"

# Cleanup
sudo umount /tmp/testmount
rm /tmp/test.img
```

✅ **Expected**: Inode numbers, stat output, inode table location

### Practice 2: Run Out of Inodes

```bash
# Create filesystem with minimal inodes
dd if=/dev/zero of=/tmp/small.img bs=1M count=10
sudo mkfs.ext4 -i 4096 /tmp/small.img   # 1 inode per 4KB
mkdir /tmp/smallmount
sudo mount /tmp/small.img /tmp/smallmount

# Fill with tiny files
for i in $(seq 1 10000); do
    echo "x" > /tmp/smallmount/file_$i 2>/dev/null || break
done

# Check inode usage
df -i /tmp/smallmount

# Cleanup
sudo umount /tmp/smallmount
rm /tmp/small.img
```

✅ **Expected**: Filesystem full with free space remaining

### Practice 3: Corrupt and Repair ext4

```bash
# Create test filesystem
dd if=/dev/zero of=/tmp/repair.img bs=1M count=50
sudo mkfs.ext4 /tmp/repair.img
mkdir /tmp/repairmount
sudo mount /tmp/repair.img /tmp/repairmount

# Create some data
echo "Important data" | sudo tee /tmp/repairmount/important.txt
sudo sync

# Corrupt the filesystem (simulated)
sudo dd if=/dev/zero of=/tmp/repair.img bs=512 count=1 seek=2 conv=notrunc

# Unmount and repair
sudo umount /tmp/repairmount
sudo e2fsck -y /tmp/repair.img

# Mount and check data
sudo mount /tmp/repair.img /tmp/repairmount
cat /tmp/repairmount/important.txt

# Cleanup
sudo umount /tmp/repairmount
rm /tmp/repair.img
```

✅ **Expected**: e2fsck repairs corruption, data may be partially recoverable

### Practice 4: Diagnose df vs du

```bash
# Simulate deleted file with open handle
sudo mkdir -p /tmp/testspace
dd if=/dev/zero of=/tmp/testspace/bigfile bs=1M count=500
sudo mount --bind /tmp/testspace /tmp/testmount

# Open file in background
sudo dd if=/tmp/testmount/bigfile of=/dev/null &

# Delete file while open
sudo rm /tmp/testmount/bigfile

# Check discrepancy
df -h /tmp/testmount
du -sh /tmp/testmount

# Find deleted file
sudo lsof +L1 | grep testmount

# Cleanup
kill %1 2>/dev/null
sudo umount /tmp/testmount
rm -rf /tmp/testspace
```

✅ **Expected**: df shows 500MB used, du shows 0, lsof reveals deleted file

### Practice 5: Filesystem Performance Comparison

```bash
# Benchmark different mount options
for opts in "default" "noatime" "data=writeback"; do
    sudo umount /tmp/testmount 2>/dev/null
    sudo mount -o $opts /tmp/test.img /tmp/testmount
    echo "Mount options: $opts"
    dd if=/dev/zero of=/tmp/testmount/benchmark bs=1M count=100 oflag=direct 2>&1 | tail -1
    rm /tmp/testmount/benchmark
done
```

✅ **Expected**: Performance differences between mount options

### Practice 6: XFS Repair

```bash
# Create XFS filesystem
dd if=/dev/zero of=/tmp/xfs.img bs=1M count=50
sudo mkfs.xfs /tmp/xfs.img
mkdir /tmp/xfsmount
sudo mount /tmp/xfs.img /tmp/xfsmount

# Create data
for i in $(seq 1 1000); do echo "data_$i" > /tmp/xfsmount/file_$i; done
sudo sync

# Corrupt log area
sudo dd if=/dev/zero of=/tmp/xfs.img bs=512 count=10 seek=1 conv=notrunc

# Repair
sudo umount /tmp/xfsmount
sudo xfs_repair -L /tmp/xfs.img

# Mount and verify
sudo mount /tmp/xfs.img /tmp/xfsmount
ls /tmp/xfsmount | wc -l

# Cleanup
sudo umount /tmp/xfsmount
rm /tmp/xfs.img
```

✅ **Expected**: xfs_repair fixes log, data recovered

### Practice 7: Recover Deleted Files with extundelete

```bash
# Install extundelete
sudo apt install extundelete

# Create test filesystem
dd if=/dev/zero of=/tmp/recover.img bs=1M count=50
sudo mkfs.ext4 /tmp/recover.img
mkdir /tmp/recovermount
sudo mount /tmp/recover.img /tmp/recovermount

# Create and delete files
echo "recover me" > /tmp/recovermount/deleted.txt
echo "also me" > /tmp/recovermount/also_deleted.txt
sudo sync
sudo rm /tmp/recovermount/deleted.txt /tmp/recovermount/also_deleted.txt

# Recover
sudo umount /tmp/recovermount
sudo extundelete /tmp/recover.img --restore-all
ls RECOVERED_FILES/

# Cleanup
sudo umount /tmp/recovermount 2>/dev/null
rm -rf RECOVERED_FILES /tmp/recover.img
```

✅ **Expected**: Deleted files recovered to RECOVERED_FILES/

### Practice 8: Monitor Inode Usage

```bash
# Find directories with most inodes
sudo find / -xdev -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -rn | head -20

# Watch inode usage in real-time
watch -n 5 'df -i / | tail -1'
```

✅ **Expected**: Top inode-consuming directories identified

### Practice 9: Btrfs Checksum Verification

```bash
# Create Btrfs filesystem
dd if=/dev/zero of=/tmp/btrfs.img bs=1M count=100
sudo mkfs.btrfs /tmp/btrfs.img
mkdir /tmp/btrfsmount
sudo mount /tmp/btrfs.img /tmp/btrfsmount

# Write data
for i in $(seq 1 100); do
    dd if=/dev/urandom of=/tmp/btrfsmount/file_$i bs=1K count=10 2>/dev/null
done

# Verify checksums
sudo btrfs scrub start /tmp/btrfsmount
sudo btrfs scrub status /tmp/btrfsmount

# Cleanup
sudo umount /tmp/btrfsmount
rm /tmp/btrfs.img
```

✅ **Expected**: All checksums verify, scrub reports no errors

### Practice 10: Filesystem Backup and Restore

```bash
# Backup ext4 filesystem
dd if=/dev/sda1 of=/tmp/ext4_backup.img bs=4M status=progress

# Verify backup
sudo e2fsck -n /tmp/ext4_backup.img

# Restore
dd if=/tmp/ext4_backup.img of=/dev/sda1 bs=4M status=progress
```

✅ **Expected**: Backup and restore complete without errors

### Practice 11: Compare Filesystem Performance

```bash
# Create test images
for fs in ext4 xfs; do
    dd if=/dev/zero of=/tmp/${fs}.img bs=1M count=200
    sudo mkfs.$fs /tmp/${fs}.img
done

# Benchmark with fio
for fs in ext4 xfs; do
    mkdir -p /tmp/${fs}_mount
    sudo mount /tmp/${fs}.img /tmp/${fs}_mount
    echo "=== $fs ==="
    sudo fio --name=test --directory=/tmp/${fs}_mount --rw=randwrite --bs=4k --size=100M --numjobs=1 --runtime=10 --group_reporting
    sudo umount /tmp/${fs}_mount
done
```

✅ **Expected**: Performance comparison between ext4 and XFS

### Practice 12: Repair with Backup Superblock

```bash
# Create filesystem
dd if=/dev/zero of=/tmp/sb.img bs=1M count=50
sudo mkfs.ext4 /tmp/sb.img

# Find backup superblock locations
sudo dumpe2fs /tmp/sb.img | grep "Backup superblock"

# Corrupt primary superblock
sudo dd if=/dev/zero of=/tmp/sb.img bs=4096 count=1 conv=notrunc

# Repair using backup
BACKUP_BLOCK=$(sudo dumpe2fs /tmp/sb.img | grep "Backup superblock" | head -1 | awk '{print $NF}')
sudo e2fsck -b $BACKUP_BLOCK /tmp/sb.img

rm /tmp/sb.img
```

✅ **Expected**: Filesystem recovered from backup superblock

### Practice 13: Journal Analysis

```bash
# View ext4 journal
sudo debugfs -R "ls -l <8>" /dev/sda1   # Root inode

# XFS log info
sudo xfs_db -r /dev/sda1 -c "log" -c "print"

# Monitor journal activity
sudo iotop -a -o -d 5
```

✅ **Expected**: Journal structure visible and understood

### Practice 14: Filesystem Health Dashboard

```bash
#!/bin/bash
# fs_health.sh — Complete filesystem health check
echo "=== Filesystem Health Dashboard ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Disk Space:"
df -h | grep -E "^/dev/"
echo ""

echo "2. Inode Usage:"
df -i | grep -E "^/dev/"
echo ""

echo "3. Filesystem Errors:"
sudo dmesg | grep -iE "ext4|xfs|btrfs|error|corrupt" | tail -10
echo ""

echo "4. SMART Status:"
for disk in /dev/sd?; do
    if [ -b "$disk" ]; then
        echo "  $disk: $(sudo smartctl -H $disk 2>/dev/null | grep "overall" | awk -F: '{print $2}' || echo "N/A")"
    fi
done
echo ""

echo "5. Mount Options:"
mount | grep -E "^/dev/"
```

✅ **Expected**: Complete health report with all filesystem metrics

### Practice 15: Real-World Recovery Scenario

```bash
# Simulate production scenario: power loss during write
# 1. Create "production" filesystem
dd if=/dev/zero of=/tmp/prod.img bs=1M count=200
sudo mkfs.ext4 /tmp/prod.img
mkdir /tmp/prodmount
sudo mount /tmp/prod.img /tmp/prodmount

# 2. Simulate workload
for i in $(seq 1 1000); do
    echo "data_$i" > /tmp/prodmount/file_$i
    sync
done

# 3. Simulate crash (corrupt journal)
sudo dd if=/dev/zero of=/tmp/prod.img bs=512 count=10 seek=100 conv=notrunc

# 4. Recovery procedure
sudo umount /tmp/prodmount
sudo e2fsck -y /tmp/prod.img
sudo mount /tmp/prod.img /tmp/prodmount

# 5. Verify data integrity
echo "Files recovered: $(ls /tmp/prodmount/ | wc -l)"
cat /tmp/prodmount/file_1
cat /tmp/prodmount/file_500
cat /tmp/prodmount/file_1000

# Cleanup
sudo umount /tmp/prodmount
rm /tmp/prod.img
```

✅ **Expected**: Filesystem repaired, majority of files recovered

---



---

[← Previous](10-9-practical-recovery-scenarios.md) | [↑ Index](index.md) | [Next →](12-deep-understanding.md)
