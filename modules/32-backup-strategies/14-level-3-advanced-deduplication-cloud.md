## ⭐ Level 3: Advanced — Deduplication, Cloud, and Disaster Recovery

![BorgBackup deduplication architecture — chunk-based storage with encryption](https://upload.wikimedia.org/wikipedia/commons/9/9b/Borg_backup_diagram.svg)

> **Level 3 Goal:** Set up Borg Backup with deduplication and encryption, deploy Restic with cloud backends, configure S3 Object Lock for ransomware protection, build a disaster recovery plan with tested restore procedures, and understand deep topics like `fsync`, COW filesystem implications, and sparse file handling.

### What You'll Cover
- BorgBackup: deduplication, encryption, compression, and repository management
- Restic: multi-backend support (local, S3, B2, SFTP), snapshots, and pruning
- Cloud storage: S3, Backblaze B2, rclone for offsite backups
- S3 Object Lock and WORM for ransomware-resistant backups
- Disaster recovery planning: RPO/RTO targets, runbooks, testing
- Deep topics: `fsync`, COW filesystems, sparse files, hard links

At the advanced level, backups become infrastructure. Deduplication reduces storage costs, cloud backends provide offsite protection, and disaster recovery runbooks ensure you can actually recover when disaster strikes.

At this level you will master:

- **BorgBackup**: `borg init --encryption=repokey /backup/borg-repo` creates an encrypted repo. `borg create /backup/borg-repo::daily-{now} /data` creates a deduplicated, compressed snapshot. Borg detects duplicate blocks across all snapshots, so monthly full backups of 1TB with 5% daily change cost only ~50GB/month.
- **Restic**: `restic -r s3:s3.amazonaws.com/bucket init` creates a repository on S3. `restic backup /data` deduplicates automatically. `restic forget --keep-daily 7 --keep-weekly 4 --prune` manages retention. Restic supports local, SFTP, S3, B2, and Azure backends.
- **Cloud storage**: AWS S3 with Object Lock prevents deletion (ransomware protection). Backblaze B2 is cheaper for large backups. `rclone sync /data remote:bucket` works with 40+ cloud providers. Use `rclone bisync` for bidirectional sync.
- **S3 Object Lock**: Set `--object-lock-mode COMPLIANCE` to make objects undeletable for a fixed period. This protects against ransomware, insider threats, and accidental deletion. Combined with versioning, you get WORM (Write Once Read Many) compliance.
- **Disaster recovery**: A DR plan documents RPO/RTO targets, recovery procedures, and contact information. Test it quarterly by performing a full restore to isolated infrastructure. Document every step — under pressure, you will not remember the details.
- **Deep topics**: `fsync` forces data to disk (critical for database backups). COW filesystems (Btrfs, ZFS) can snapshot instantly but have implications for `dd` backups. Sparse files waste space in backups — `tar --sparse` handles them correctly.


[← Previous](13-section-10-automation.md) | [↑ Index](index.md) | [Next →](15-section-6-borg-backup.md)
