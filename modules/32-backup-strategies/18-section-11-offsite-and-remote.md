## 🔍 Section 11: Offsite and Remote Backups

### SSH Tunnels

```bash
# rsync over SSH (already encrypted)
rsync -avz -e "ssh -p 2222" /data/ user@backup-server:/backups/

# Borg over SSH
borg create user@backup-server:/backups/repo::archive /data/

# Restic over SSH
restic init --repo sftp:user@backup-server:/backups/restic-repo/

# Encrypted file transfer
tar czf - /data/ | openssl enc -aes-256-cbc -salt -pass file:/etc/backup-key | \
    ssh user@backup-server "cat > /backups/data.tar.gz.enc"
# Decrypt
ssh user@backup-server "cat /backups/data.tar.gz.enc" | \
    openssl enc -d -aes-256-cbc -salt -pass file:/etc/backup-key | \
    tar xzf - -C /restore/
```

### Pull vs Push

| Strategy | Source | Backup Server | Use Case |
|----------|--------|---------------|----------|
| Push | Initiates backup, sends data | Listens | Many clients to one server |
| Pull | Provides data | Fetches from sources | Server controls schedule |

### Air-Gapped Backups

```bash
# Physical: backup to external drive, disconnect
sudo mount /dev/sdb1 /mnt/backup
rsync -av /data/ /mnt/backup/
sudo umount /mnt/backup
# Physically disconnect the drive

# Logical: append-only Borg repos
borg serve --append-only /backups/repo

# S3 Object Lock — objects can't be deleted before retention expires
aws s3api put-object-legal-hold --bucket my-bucket \
    --key backups/data.tar.gz --legal-hold Status=ON
```

---



---

[← Previous](17-section-8-backup-to-cloud.md) | [↑ Index](index.md) | [Next →](19-section-12-restore-testing.md)
