## 6. Diagnosing df vs du Discrepancies

### Common Causes

```bash
# Scenario: df says full, du says plenty of space
df -h /
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda2        50G   50G     0 100% /

du -sh /
# 30G     /

# Missing 20GB! Where is it?
```

### Cause 1: Deleted Files with Open File Handles

```bash
# Find processes holding deleted files
sudo lsof +L1

# Example output:
# COMMAND    PID   USER   FD   TYPE DEVICE SIZE/OFF NLINK NODE NAME
# nginx    1234   root    5w   REG  253,2  15728640     0 131073 /var/log/nginx/access.log (deleted)

# Solution: restart the process to release the file
sudo systemctl restart nginx
```

### Cause 2: Reserved Blocks

```bash
# ext4 reserves 5% of blocks for root
sudo tune2fs -l /dev/sda1 | grep "Reserved block count"

# Check reserved space
echo "Reserved: $(($(sudo tune2fs -l /dev/sda1 | grep 'Reserved block count' | awk '{print $NF}') * 4096 / 1024 / 1024))MB"

# Reduce reserved space (only for non-root partitions!)
sudo tune2fs -m 1 /dev/sda1    # Reduce to 1%
```

### Cause 3: Metadata Overhead

```bash
# Inodes, journal, superblock copies consume space
sudo dumpe2fs /dev/sda1 | grep -E "(Inode count|Block count|Reserved)"

# Btrfs metadata can grow unbounded
sudo btrfs filesystem usage /mnt
```

### Diagnostic Script

```bash
#!/bin/bash
# df_du_diagnose.sh — Find space discrepancy
echo "=== df vs du Diagnosis ==="
echo "df output:"
df -h "$1"
echo ""
echo "Top directories by space:"
sudo du -sh "$1"/* 2>/dev/null | sort -rh | head -10
echo ""
echo "Deleted files with open handles:"
sudo lsof +L1 2>/dev/null | head -10
echo ""
echo "Inode usage:"
df -i "$1"
```





[← Previous](06-5-filesystem-repair-when-things.md) | [↑ Index](index.md) | [Next →](08-7-filesystem-performance-tuning.md)
