## 🔍 Section 4: dd and ddrescue (Basic)

### dd — Disk Cloning

```bash
# Clone disk sda → sdb
sudo dd if=/dev/sda of=/dev/sdb bs=4M status=progress

# Backup partition to image
sudo dd if=/dev/sda1 of=/backups/sda1.dd bs=4M status=progress

# Restore
sudo dd if=/backups/sda1.dd of=/dev/sda1 bs=4M status=progress
```

### Critical dd Options

```bash
# Continue on errors (skip bad blocks, pad with zeros)
sudo dd if=/dev/sda of=/backups/sda.dd bs=4M conv=sync,noerror status=progress

# Bypass cache
sudo dd if=/dev/sda of=/backups/sda.dd bs=4M iflag=direct oflag=direct

# Sparse output (GNU dd)
sudo dd if=/dev/sda of=/backups/sda.dd bs=4M conv=sparse

# Compressed image
sudo dd if=/dev/sda bs=4M | gzip > /backups/sda.dd.gz
zcat /backups/sda.dd.gz | sudo dd of=/dev/sda bs=4M
```

### Clone Over Network

```bash
# Destination
sudo nc -l -p 9999 | sudo dd of=/dev/sdb bs=4M status=progress
# Source
sudo dd if=/dev/sda bs=4M status=progress | nc dest-machine 9999
```

### Loop Mount a dd Image

```bash
sudo losetup -P /dev/loop0 /backups/sda-image.dd
sudo mount /dev/loop0p1 /mnt/restore
```





[← Previous](05-section-3-rsync-remote-sync.md) | [↑ Index](index.md) | [Next →](07-level-2-intermediary-incremental-backups.md)
