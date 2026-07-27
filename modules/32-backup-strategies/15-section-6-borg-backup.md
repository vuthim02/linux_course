## 🔍 Section 6: Borg Backup

Deduplicating backup with compression, encryption, append-only repos.

### Setup

```bash
sudo apt install borgbackup

# Initialize repo (local)
borg init --encryption=repokey /backups/borg-repo

# Initialize repo (remote via SSH)
borg init --encryption=repokey user@backup-server:/backups/borg-repo

# Encryption modes:
#   repokey:   Key in repo, encrypted with passphrase
#   keyfile:   Key in separate file (more secure)
#   none:      No encryption (not recommended)
```

### Create Backups

```bash
export BORG_PASSPHRASE="your-passphrase"

# Basic backup
borg create --compression zstd,9 --stats \
    /backups/borg-repo::home-$(date +%F) \
    /home/user/data/

# With exclusions
borg create \
    --compression zstd,9 \
    --exclude='*.log' \
    --exclude='.cache' \
    --progress \
    /backups/borg-repo::home-$(date +%F) \
    /home/user/data/

unset BORG_PASSPHRASE
```

### List, Extract, Mount

```bash
export BORG_PASSPHRASE="your-passphrase"
borg list /backups/borg-repo
borg list /backups/borg-repo::home-2025-01-12
borg extract /backups/borg-repo::home-2025-01-12
borg mount /backups/borg-repo::home-2025-01-12 /mnt
borg umount /mnt
unset BORG_PASSPHRASE
```

### Pruning

```bash
borg prune \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --keep-yearly 2 \
    --stats \
    --list \
    /backups/borg-repo
```

### Integrity Checking

```bash
borg check /backups/borg-repo              # repo structure + archives
borg check --verify-data /backups/borg-repo  # verify all chunk checksums
borg check --repair /backups/borg-repo        # repair (if corrupted)
```

### Deduplication Stats

```bash
borg info /backups/borg-repo
# Output:
#                     Original   Compressed   Deduplicated
# This archive:        4.20 GB      1.74 GB        1.74 GB
# All archives:       42.00 GB     17.40 GB        2.10 GB
#                      Unique chunks    Total chunks
# Chunk index:              2,104          42,080
```

### Append-Only Mode (Ransomware Protection)

```bash
borg init --encryption=repokey --append-only /backups/borg-repo
# Or in SSH authorized_keys:
command="borg serve --append-only /backups/borg-repo" ssh-ed25519 AAA...
```

---



---

[← Previous](14-level-3-advanced-deduplication-cloud.md) | [↑ Index](index.md) | [Next →](16-section-7-restic.md)
