## 🔍 Section 7: Restic

Modern backup tool supporting many backends (local, S3, B2, GCS, Azure, SFTP).

### Setup

```bash
sudo apt install restic

# Local repo
restic init --repo /backups/restic-repo

# S3
export AWS_ACCESS_KEY_ID="accesskey"
export AWS_SECRET_ACCESS_KEY="secretkey"
restic init --repo s3:s3.us-east-1.amazonaws.com/bucket/restic-repo

# B2
export B2_ACCOUNT_ID="b2-id"
export B2_ACCOUNT_KEY="b2-key"
restic init --repo b2:bucket:/restic-repo

# SFTP
restic init --repo sftp:user@backup-server:/backups/restic-repo

# Set env var instead of password prompt
export RESTIC_PASSWORD="your-password"
```

### Backup & Snapshots

```bash
# Backup
restic --repo /backups/restic-repo backup \
    --exclude='*.log' \
    --exclude='.cache' \
    --tag production \
    /home/user/data/ \
    /etc/

# List snapshots
restic --repo /backups/restic-repo snapshots
restic --repo /backups/restic-repo snapshots --tag production
restic --repo /backups/restic-repo stats latest
```

### Restore & Mount

```bash
restic --repo /backups/restic-repo restore latest --target /restore/
restic --repo /backups/restic-repo restore a1b2c3d4 --target /restore/
restic --repo /backups/restic-repo restore latest \
    --target /restore/ --include /important.doc

# Mount as FUSE filesystem
restic --repo /backups/restic-repo mount /mnt/restic
ls /mnt/restic/hosts/myhost/
fusermount -u /mnt/restic
```

### Forget — Retention

```bash
restic --repo /backups/restic-repo forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --prune

# Dry run
restic --repo /backups/restic-repo forget --keep-daily 7 --dry-run
```

### Check & Unlock

```bash
restic --repo /backups/restic-repo check
restic --repo /backups/restic-repo check --read-data
restic --repo /backups/restic-repo unlock  # stale locks after crash
```

---



---

[← Previous](15-section-6-borg-backup.md) | [↑ Index](index.md) | [Next →](17-section-8-backup-to-cloud.md)
