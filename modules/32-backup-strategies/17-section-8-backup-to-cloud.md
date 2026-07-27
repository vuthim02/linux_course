## 🔍 Section 8: Backup to Cloud Storage

### rclone — Universal Cloud Sync

40+ providers. Sync, copy, crypt.

```bash
sudo apt install rclone
rclone config  # interactive setup

# Copy/sync to cloud
rclone copy /home/user/data/ remote:backups/data/
rclone sync /home/user/data/ remote:backups/data/

# With encryption (crypt remote)
rclone sync /home/user/data/ crypt-remote:/data/

# S3 example
rclone sync /data/ my-s3:my-bucket/backups/ \
    --progress --exclude='*.log' --bwlimit "08:00,2M 18:00,10M"
```

### s3cmd & awscli

```bash
# s3cmd
s3cmd --configure
s3cmd sync /home/user/data/ s3://my-bucket/backups/
s3cmd ls s3://my-bucket/backups/

# awscli
aws s3 sync /home/user/data/ s3://my-bucket/backups/
aws s3 sync /home/user/data/ s3://my-bucket/backups/ --sse aws:kms
```

### Object Lock (WORM) for Ransomware Protection

```bash
# Enable on bucket creation
aws s3api create-bucket --bucket my-backup-bucket \
    --object-lock-enabled-for-bucket
aws s3api put-object-lock-configuration \
    --bucket my-backup-bucket \
    --object-lock-configuration '{"ObjectLockEnabled": "Enabled",
        "Rule": {"DefaultRetention": {"Mode": "COMPLIANCE", "Days": 7}}}'

# Upload with retention
aws s3 cp backup.tar.gz s3://my-backup-bucket/ --object-lock-mode COMPLIANCE
```

---



---

[← Previous](16-section-7-restic.md) | [↑ Index](index.md) | [Next →](18-section-11-offsite-and-remote.md)
