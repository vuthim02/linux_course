## 🔍 Section 3: Filesystem Repair (fsck)

### When to Use fsck

```bash
# Symptoms of filesystem corruption:
# - System won't boot (dropped to emergency mode)
# - "I/O error" or "Structure needs cleaning" in logs
# - Sudden power loss or improper shutdown
# - Filesystem mounts as read-only automatically
```

### Checking and Repairing Filesystems

```bash
# Check filesystem for errors (DO NOT run on mounted fs)
sudo fsck /dev/sda1

# Force check even if filesystem seems clean
sudo fsck -f /dev/sda1

# Automatically repair without asking
sudo fsck -y /dev/sda1

# Show what would be repaired without doing it
sudo fsck -n /dev/sda1

# Check all filesystems in /etc/fstab
sudo fsck -A

# Skip check on mounted filesystems (use for non-root)
sudo fsck -M /dev/sda1
```

### fsck on the Root Filesystem

```bash
# Root fs cannot be fsck'd while running
# Method 1: Force on next boot
sudo touch /forcefsck
sudo reboot

# Method 2: Add fsck.mode=force to kernel command line in GRUB:
# linux ... fsck.mode=force

# Method 3: Boot from Live USB and check from there
sudo fsck -y /dev/sda1
```

### Understanding fsck Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No errors |
| 1 | Errors corrected |
| 2 | System should be rebooted |
| 4 | Errors left uncorrected |
| 8 | Operational error |
| 16 | Usage/syntax error |
| 32 | fsck interrupted |
| 128 | Shared library error |

### Checking Disk Health (SMART)

```bash
# Check if SMART is available
sudo smartctl -i /dev/sda

# Run a short test
sudo smartctl -t short /dev/sda

# Run a long test (takes hours)
sudo smartctl -t long /dev/sda

# Check test results
sudo smartctl -l selftest /dev/sda

# Overall health
sudo smartctl -H /dev/sda
```





[← Previous](05-section-2-resetting-a-lost.md) | [↑ Index](index.md) | [Next →](07-section-4-grub-recovery.md)
