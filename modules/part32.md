# 🐧 Linux System Administrator — Complete Course
## Part 32 of ∞: Backup Strategies — rsync, tar, dd, dump/restore, Borg, restic

---

> **Reverse Engineering Approach:** Backup is the one thing every sysadmin knows they should do, tests only after losing production data, and implements properly only after at least one catastrophic restore failure. The principles aren't complicated — 3-2-1, RPO, RTO — but the tools and their edge cases will burn you. `tar` silently skips files you didn't know were open. `rsync --delete` removes the wrong directory because you forgot a trailing slash. `dd` of a failing disk completes without error but the data is garbage. Borg deduplicates but can't mount a broken repo. Restic encrypts but you lost the key file. Every tool has failure modes that only reveal themselves during restore. This part dissects each tool, then makes you prove you can actually get your data back.

---

## 🎯 What You Will Achieve in Part 32

| Level | Focus | Skills |
|-------|-------|--------|
| **Level 1 — Basic** | Backup Philosophy & Classic Tools | 3-2-1 rule, RPO/RTO, `tar` create/extract, `rsync` local/remote, `dd` cloning |
| **Level 2 — Intermediary** | Incremental Backups & Databases | `tar --listed-incremental`, `rsync --link-dest`, `ddrescue`, `dump/restore`, `mysqldump`, `pg_dump`, cron automation |
| **Level 3 — Advanced** | Deduplication, Cloud & DR | Borg, Restic, cloud storage (S3/B2/rclone), restore testing, disaster recovery planning, `fsync`/sparse/COW deep topics |

---

## ⭐ Level 1: Basic — Backup Philosophy and Classic Tools

![3-2-1 backup rule diagram — three copies, two media, one offsite](https://upload.wikimedia.org/wikipedia/commons/8/84/Backup_3-2-1_Rule_Diagram.svg)

> **Level 1 Goal:** Understand the 3-2-1 backup philosophy, master `tar` for archiving, use `rsync` for local/remote sync, and clone disks with `dd`.

---

## 🔍 Section 1: Backup Philosophy

### The 3-2-1 Rule

```
3 copies of your data
2 different storage media
1 copy offsite
```

**3 copies:** Live data + 2 backups. If any one copy is lost, you still have another.
**2 different media:** Different failure modes — a disk controller failure won't wipe your tape.
**1 copy offsite:** Building burns, offsite survives — cloud, colo, friend's Raspberry Pi.

### RPO and RTO

| Term | Definition | Example |
|------|------------|---------|
| RPO | Recovery Point Objective — max acceptable data loss | 1 hour → can lose ≤ 1 hour |
| RTO | Recovery Time Objective — max acceptable downtime | 4 hours — must be back in 4 hours |

```
RPO ← determines backup frequency
RTO ← determines restore speed requirements
```

### Full, Incremental, Differential

```
Full:       [████████████████████████████████]
Incremental: [██][██][██] each captures changes since PRIOR backup (any type)
Differential: [██][████][██████] each captures changes since LAST FULL only

Restore: full + inc1 + inc2 + inc3 (replay all)
Restore: full + latest diff only (simpler chain)
```

| Type | Backup Speed | Restore Speed | Storage | Complexity |
|------|-------------|---------------|---------|------------|
| Full | Slowest | Fastest | Most | Simplest |
| Incremental | Fastest | Slowest (all must be intact) | Least | Most chain-dependent |
| Differential | Medium | Medium (full + 1) | Medium | Simpler than inc |

### Hot vs Cold

| Type | Description | Example |
|------|-------------|---------|
| Hot | Running, data changing | `mysqldump` while MySQL live (with locks) |
| Warm | Quiesced, not stopped | LVM snapshot, XFS freeze |
| Cold | Fully stopped | Shut down VM, copy disk image |

### What to Back Up

| Priority | What | Why |
|----------|------|-----|
| Critical | Databases, app data, user homes | The actual business data |
| Important | `/etc`, `/usr/local/etc` | Rebuild without configs is slow |
| Helpful | Package lists | `dpkg --get-selections` or `rpm -qa` |
| Exclude | `/proc`, `/sys`, `/dev`, `/run`, `/tmp` | Pseudo-filesystems, regenerated at boot |

### Key Insight

A backup that cannot be restored is not a backup. The most important metric is RTO measured during actual restore testing — not estimates.

---

## 🔍 Section 2: tar — Tape Archiver (Basic)

### Basic Operations

```bash
# Create
tar cf backup.tar /home/user/data/
# Compressed
tar czf backup.tar.gz /home/user/data/
tar cjf backup.tar.bz2 /home/user/data/
tar cJf backup.tar.xz /home/user/data/
# Modern: zstd
tar --zstd -cf backup.tar.zst /home/user/data/

# Extract
tar xf backup.tar
tar xzf backup.tar.gz
tar xzf backup.tar.gz -C /restore/path/

# List
tar tf backup.tar
```

### Compression Levels

```bash
GZIP=-9 tar czf archive.tar.gz /data/
XZ_OPT=-9 tar cJf archive.tar.xz /data/
ZSTD_CLEVEL=19 tar --zstd -cf archive.tar.zst /data/
```

### Preserving Metadata

```bash
tar cpf backup.tar --xattrs --acls --selinux /home/user/data/
tar xpf backup.tar
```

### Sparse Files

```bash
tar cSf backup.tar /home/user/data/   # S = preserve sparseness
tar df backup.tar                     # diff against filesystem
tar tzf backup.tar.gz > /dev/null     # test structural integrity
```

---

## 🔍 Section 3: rsync — Remote Sync (Basic)

### Basic Syntax

```bash
rsync [options] SOURCE DESTINATION
rsync [options] SOURCE user@host:DESTINATION    # Push
rsync [options] user@host:SOURCE DESTINATION    # Pull
```

### Key Options

| Option | Description |
|--------|-------------|
| `-a` | Archive: recursive + preserve all metadata (-rlptgoD) |
| `-v` | Verbose |
| `-z` | Compress during transfer |
| `-n` | Dry run |
| `--delete` | Delete files in dest not in source |
| `--bwlimit` | Bandwidth limit in KB/s |
| `--exclude` | Exclude pattern |
| `-H` | Preserve hard links |

### Local & Remote

```bash
# Local
rsync -av /source/directory/ /destination/directory/
# Trailing slash: copies CONTENTS of dir; no slash: copies dir itself

# Remote over SSH
rsync -avz /home/user/data/ user@backup-server:/backups/data/
rsync -avz -e 'ssh -p 2222' /data/ user@host:/backups/

# Remote daemon
rsync -av rsync://backup@backup-server/backups/ /local/restore/
```

### Bandwidth Limiting

```bash
rsync -avz --bwlimit=1024 /data/ user@host:/backups/   # 1 MB/s max
```

---

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

---

## ⭐ Level 2: Intermediary — Incremental Backups and Databases

![Incremental backup strategy with rsync --link-dest](https://upload.wikimedia.org/wikipedia/commons/6/6a/Incremental_backup.svg)

> **Level 2 Goal:** Implement incremental backups with `tar --listed-incremental` and `rsync --link-dest`, recover failing drives with `ddrescue`, use `dump/restore` for ext4, perform database backups with `mysqldump` and `pg_dump`, and automate the entire workflow with cron.

---

## 🔍 Section 2: tar — Advanced

### Exclude Patterns

```bash
tar czf backup.tar.gz \
    --exclude='*.log' \
    --exclude='*.tmp' \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='cache' \
    /home/user/
# Exclude from file
tar czf backup.tar.gz -X exclude-list.txt /home/user/
```

### Incremental with --listed-incremental

```bash
# Level 0 (full) — Monday
tar czf monday-full.tar.gz \
    --listed-incremental=/var/log/backup.snar \
    /home/user/data/

# Level 1 (incremental) — Tuesday
tar czf tuesday-inc1.tar.gz \
    --listed-incremental=/var/log/backup.snar \
    /home/user/data/

# Restore: both archives in sequence
tar xzf monday-full.tar.gz -C /restore/
tar xzf tuesday-inc1.tar.gz -C /restore/
```

The `.snar` file tracks metadata (mtime, inode) to determine what changed.

### Archive Across SSH

```bash
# Push (local → remote)
tar czf - /home/user/data/ | ssh user@backup-server "cat > /backups/data-$(date +%F).tar.gz"

# Pull (remote → local)
ssh user@server "tar czf - /home/user/data/" > backup.tar.gz
```

---

## 🔍 Section 3: rsync — Advanced

### Incremental with --link-dest

The most important rsync pattern:

```bash
#!/bin/bash
BACKUP_DIR="/backups"
SOURCE="/home/user/data"
DATE=$(date +%Y-%m-%d)
LATEST=$(ls -1 "$BACKUP_DIR" | tail -1)

rsync -av --delete \
    --link-dest="$BACKUP_DIR/$LATEST" \
    "$SOURCE/" \
    "$BACKUP_DIR/$DATE/"
```

```
After 3 days:
/backups/
├── 2025-01-06/   # Monday — full copy
├── 2025-01-07/   # Tuesday — hard links to Monday's unchanged files
├── 2025-01-08/   # Wednesday — hard links to Tuesday's unchanged files

Unchanged files share inodes (zero extra space).
ls -i /backups/2025-01-06/file.txt /backups/2025-01-07/file.txt  # same inode
```

### Deletion Safety

```bash
rsync -av --delete --dry-run /source/ /backup/          # dry-run first!
rsync -av --delete /source/ /backup/
```

### Filter Rules

```bash
rsync -av --exclude='*.log' --exclude='.cache/' /data/ /backup/
rsync -av --include='*.pdf' --exclude='*' /data/documents/ /backup/
rsync -av --exclude-from=/etc/backup-excludes.txt /data/ /backup/
```

### rsync Daemon

```bash
# /etc/rsyncd.conf
[backups]
    path = /srv/backups
    read only = yes
    auth users = backup
    secrets file = /etc/rsyncd.secrets
    hosts allow = 192.168.1.0/24

# Start daemon
sudo systemctl enable --now rsync
```

---

## 🔍 Section 4: ddrescue — Failing Drive Recovery

ddrescue reads good sectors first, then retries bad ones. The mapfile tracks progress.

```bash
# Install
sudo apt install ddrescue

# Basic recovery
sudo ddrescue -d /dev/sda /backups/recovery.dd /backups/mapfile.log

# Resume failed recovery, retry bad sectors 3 times
sudo ddrescue -d -r3 /dev/sda /backups/recovery.dd /backups/mapfile.log

# Reverse direction (read from end backward)
sudo ddrescue -d -r3 -R /dev/sda /backups/recovery.dd /backups/mapfile.log

# List bad sectors
ddrescuelog --list-bad /backups/mapfile.log
```

---

## 🔍 Section 5: dump/restore

Filesystem-level backup for ext2/3/4. Understands inodes and block groups.

### Basic Usage

```bash
# Full dump (level 0)
sudo dump -0uf /backups/sda1.dump /dev/sda1

# Restore
sudo restore -rf /backups/sda1.dump

# List
sudo restore -tf /backups/sda1.dump
```

### Dump Levels

Dump levels (0-9) are true incremental:

| Level | Captures |
|-------|----------|
| 0 | Everything |
| 1 | Changes since level 0 |
| 2 | Changes since level 1 |
| etc. | |

```bash
# Sunday: level 0 (full)
sudo dump -0uf /backups/sda1-l0.dump /dev/sda1

# Monday: level 1 (changes since Sunday)
sudo dump -1uf /backups/sda1-l1.dump /dev/sda1

# Tuesday: level 2 (changes since Monday)
sudo dump -2uf /backups/sda1-l2.dump /dev/sda1

# Thursday: level 1 again (resets: captures changes since level 0)
sudo dump -1uf /backups/sda1-l1-thu.dump /dev/sda1

# Restore requires all levels
sudo restore -rf /backups/sda1-l0.dump
sudo restore -rf /backups/sda1-l1.dump
sudo restore -rf /backups/sda1-l2.dump
```

### Interactive Restore (Individual Files)

```bash
sudo restore -if /backups/sda1-l0.dump
# In interactive shell:
#   ls            list files
#   cd            change directory
#   add file      mark for extraction
#   extract       extract marked files
#   quit          exit
```

### Limitations

- ext2/3/4 only
- XFS uses `xfsdump`/`xfsrestore`
- Btrfs uses `btrfs send`/`receive`

---

## 🔍 Section 9: Database Backup

### MySQL/MariaDB — mysqldump

```bash
# All databases
mysqldump --all-databases --single-transaction --routines --events > backup.sql

# Single database
mysqldump --single-transaction mydatabase > mydatabase.sql

# Compressed
mysqldump --all-databases --single-transaction | gzip > backup-$(date +%F).sql.gz

# Restore
mysql < backup.sql
zcat backup-2025-01-12.sql.gz | mysql
```

`--single-transaction` gives a consistent snapshot without locking tables (InnoDB).

### PostgreSQL — pg_dump / pg_dumpall

```bash
# Single database
pg_dump mydatabase > mydatabase.sql

# All databases
pg_dumpall > all-databases.sql

# Custom format (compressed, selective restore, parallel)
pg_dump -Fc mydatabase > mydatabase.dump
pg_restore -d mydatabase -t mytable mydatabase.dump   # restore single table

# Directory format (parallel dump/restore)
pg_dump -Fd -j 4 mydatabase -f /backups/pg-mydatabase/
pg_restore -d mydatabase -j 4 /backups/pg-mydatabase/

# Restore
psql mydatabase < mydatabase.sql
pg_restore -d mydatabase mydatabase.dump
```

### PostgreSQL — WAL Archiving (Point-in-Time Recovery)

```bash
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backups/pg-wal/%f'

# Base backup
psql -c "SELECT pg_start_backup('base_$(date +%F)');"
tar czf /backups/pg-base-$(date +%F).tar.gz /var/lib/postgresql/16/main/
psql -c "SELECT pg_stop_backup();"

# Restore to specific time:
# 1. Extract base backup
# 2. Set restore_command and recovery_target_time in postgresql.conf
# 3. Start PostgreSQL
```

### SQLite

```bash
sqlite3 /var/lib/mydatabase.db ".backup /backups/mydatabase-$(date +%F).db"
sqlite3 /var/lib/mydatabase.db ".dump" | gzip > /backups/mydatabase.sql.gz
```

---

## 🔍 Section 10: Automation

### Rotation Script (Full + Incremental)

```bash
#!/bin/bash
# rotation-backup.sh
BACKUP_DIR="/backups"
SOURCE="/home/user/data"
DATE=$(date +%Y-%m-%d)
DOW=$(date +%u)  # 1=Monday, 7=Sunday

mkdir -p "$BACKUP_DIR"

if [ "$DOW" -eq 7 ]; then
    # Sunday: full backup
    rsync -av --delete "$SOURCE/" "$BACKUP_DIR/full-$DATE/"
    rm -f "$BACKUP_DIR/latest"
    ln -s "full-$DATE" "$BACKUP_DIR/latest"
else
    # Monday-Saturday: incremental with --link-dest
    PREV=$(readlink "$BACKUP_DIR/latest" 2>/dev/null || ls -1 "$BACKUP_DIR" | tail -1)
    rsync -av --delete --link-dest="$BACKUP_DIR/$PREV" \
        "$SOURCE/" "$BACKUP_DIR/inc-$DATE/"
    rm -f "$BACKUP_DIR/latest"
    ln -s "inc-$DATE" "$BACKUP_DIR/latest"
fi

# Retention: remove daily backups older than 30 days
find "$BACKUP_DIR" -name "full-*" -o -name "inc-*" -type d -mtime +30 -exec rm -rf {} \;
```

### cron Schedule

```bash
# /etc/crontab
0 2 * * * root /usr/local/bin/rotation-backup.sh     # daily file backup
0 3 * * * root /usr/local/bin/db-backup.sh            # daily DB backup
0 6 1 * * root /usr/local/bin/verify-backups.sh        # monthly integrity
0 7 * * 0 root /usr/local/bin/test-restore.sh          # weekly restore test
```

### Integrity Verification

```bash
#!/bin/bash
# verify-backup.sh
# For tar
tar tf /backups/data.tar.gz > /dev/null && echo "Archive OK" || echo "CORRUPT"

# File count match
diff <(find /data/ -type f | wc -l) <(find /backups/latest/ -type f | wc -l)

# Checksum verification
find /data/ -type f -exec md5sum {} \; | sort > /tmp/source.md5
find /backups/latest/ -type f -exec md5sum {} \; | sort > /tmp/backup.md5
diff /tmp/source.md5 /tmp/backup.md5 && echo "All checksums match"
```

---

## ⭐ Level 3: Advanced — Deduplication, Cloud, and Disaster Recovery

![BorgBackup deduplication architecture — chunk-based storage with encryption](https://upload.wikimedia.org/wikipedia/commons/9/9b/Borg_backup_diagram.svg)

> **Level 3 Goal:** Set up Borg Backup with deduplication and encryption, deploy Restic with cloud backends, configure S3 Object Lock for ransomware protection, build a disaster recovery plan with tested restore procedures, and understand deep topics like `fsync`, COW filesystem implications, and sparse file handling.

---

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

## 🔍 Section 12: Restore Testing

### Why You MUST Test Restores

Common failures found ONLY during restore testing:
- Corrupted archive (tar header error, truncated)
- Missing dependency (restore tool not on new machine)
- Permission mismatch (UIDs differ between machines)
- Encryption key lost or password forgotten
- Incomplete incremental chain
- Software version incompatibility

### Manual Restore Test

```bash
# 1. Create test environment
mkdir -p /tmp/restore-test/

# 2. Extract
cd /tmp/restore-test
tar xzf /backups/data-2025-01-12.tar.gz

# 3. Verify counts
echo "Expected: $(find /data/ -type f | wc -l)"
echo "Restored: $(find /tmp/restore-test/ -type f | wc -l)"

# 4. Spot-check critical files
diff /data/important.doc /tmp/restore-test/data/important.doc

# 5. Verify database restore
pg_restore -d test_restore /backups/mydatabase.dump
psql -d test_restore -c "SELECT count(*) FROM users;"
```

### Automated Restore Test

```bash
#!/bin/bash
# test-restore.sh
set -e
TEST_DIR="/tmp/restore-test-$$"
BACKUP_FILE="/backups/latest/data.tar.gz"
LOG="/var/log/restore-test-$(date +%F).log"

echo "=== Restore Test $(date) ===" > "$LOG"
mkdir -p "$TEST_DIR"

# Test 1: Extract
tar xzf "$BACKUP_FILE" -C "$TEST_DIR" 2>> "$LOG" \
    && echo "PASS: Extract" || echo "FAIL: Extract"

# Test 2: File count
S=$(find /data/ -type f | wc -l)
R=$(find "$TEST_DIR" -type f | wc -l)
[ "$S" -eq "$R" ] && echo "PASS: $S files" || echo "FAIL: $S vs $R"

# Test 3: Checksum critical files
for f in important.doc config.json; do
    [ "$(md5sum /data/$f | cut -d' ' -f1)" = \
      "$(md5sum $TEST_DIR/data/$f 2>/dev/null | cut -d' ' -f1)" ] \
      && echo "PASS: $f" || echo "FAIL: $f"
done

rm -rf "$TEST_DIR"
echo "=== Test Complete ===" >> "$LOG"
```

### Frequency

| Backup Type | Test Frequency |
|-------------|----------------|
| Daily incremental | Weekly spot check |
| Weekly full | Monthly full restore |
| Monthly archive | Quarterly |
| DR plan | Annually (bare-metal) |

---

## 🔍 Section 13: Disaster Recovery Planning

### DR Checklist

```
System Configuration:
☐ /etc/              (system config)
☐ /usr/local/etc/    (local software config)
☐ SSH host keys      (/etc/ssh/ssh_host_*)
☐ SSL certificates   (/etc/ssl/, /etc/letsencrypt/)
☐ Package list       (dpkg --get-selections / rpm -qa)

Databases:
☐ MySQL/MariaDB      (mysqldump --all-databases)
☐ PostgreSQL         (pg_dumpall)
☐ SQLite             (.backup)
☐ MongoDB            (mongodump)

Application Data:
☐ /var/www/          (web content)
☐ /home/             (user data)
☐ Container volumes  (Docker/Podman)
```

### Backup Policy Template

```markdown
## Schedule
- Databases: Daily 03:00
- Files: Daily 02:00 (incremental), Sunday 01:00 (full)
- System config: After any config change

## Retention
- Daily: 30 days
- Weekly: 12 weeks
- Monthly: 12 months
- Yearly: 7 years (if regulated)

## Storage
- Primary: Local NAS (RAID 6) — 30 days
- Secondary: Offsite cloud (S3+Glacier) — 12 months

## Restore Testing
- Daily: Checksum verification after backup
- Weekly: Full restore to test environment
- Quarterly: Full DR drill (bare-metal)
```

### DR Response Flow

```
1. DETECT disaster (crash, corruption, ransomware, fire)
2. ASSESS damage (scope, can primary be recovered? RTO clock starts)
3. DECIDE strategy (same hardware, spare, cloud DR site)
4. RECOVER (OS → config → data → databases → test service)
5. VALIDATE (data correct? service responding? users connected?)
6. POST-MORTEM (actual RPO/RTO? root cause? update plan)
```

### Ransomware-Specific Strategy

```bash
# Immutable backups:
#   - S3 Object Lock
#   - Append-only Borg repos
#   - WORM tapes

# Air-gapped:
#   - Physically disconnected drives
#   - Separate backup VLAN with no inbound connections

# Versioned:
#   - Never overwrite old backups
#   - Borg/Restic naturally version everything

# Test ransomware recovery quarterly:
#   - Simulate: "all files encrypted, restore from backup"
```

---

## 🔬 Deep Understanding

### fsync and Disk Barriers

When a backup tool reports "success," writes may still be in the kernel's page cache, not on physical media.

```c
write(fd, buffer, count);   // returns immediately (cached)
fsync(fd);                  // blocks until data is on physical media
```

Without `fsync`, a crash after the backup "succeeds" loses data.
- `rsync` does NOT fsync by default (use `--fsync`)
- `borg` calls fsync on repo data
- `restic` calls fsync on saved files
- `mysqldump`/`pg_dump` call fsync on output

Disk write caches lie. Consumer drives report "written" while data sits in volatile RAM:

```bash
# Check and disable volatile write cache
sudo hdparm -W /dev/sda   # 1=enabled (risky), 0=safe
sudo hdparm -W 0 /dev/sda
```

### COW Filesystem Implications

Btrfs and ZFS (Copy-on-Write) don't overwrite in place. This is excellent for instant snapshots, but bad for random-write workloads.

```bash
# Btrfs snapshot
sudo btrfs subvolume snapshot -r /mnt/data /mnt/data/.snapshots/backup-$(date +%F)
sudo btrfs send /mnt/data/.snapshots/backup-2025-01-12 | \
    sudo btrfs receive /backup-server/data/

# ZFS snapshot
zfs snapshot tank/data@backup-$(date +%F)
zfs send tank/data@backup | ssh server zfs receive tank/backups

# Disable COW for VM images on Btrfs (avoid double-COW)
chattr +C /var/lib/libvirt/images/
```

### Sparse Files

Sparse files have "holes" — zeros not stored on disk. A 1 TB database with 100 GB real data uses 100 GB.

```bash
dd if=/dev/zero of=sparse.img bs=1M seek=1000 count=0
ls -lh sparse.img   # 1000 MB (apparent)
du -h sparse.img    # 0 bytes (actual)

# tar preserves sparseness only with -S
tar cSf backup.tar sparse.img    # preserves holes
tar cf backup.tar sparse.img     # fills holes → huge

# rsync preserves with -S
rsync -aS sparse.img /backup/

# Borg/Restic handle sparse files automatically
```

### Hard Link Detection

Hard links: multiple directory entries → same inode. Backups must preserve this.

```bash
ln original.txt link1.txt link2.txt
ls -li *.txt  # same inode

# rsync: needs -H flag
rsync -aH /source/ /backup/
# tar: preserves by default
# Borg/Restic: detect and preserve
```

### Checksumming for Integrity

| Tool | Checksum Strategy |
|------|-------------------|
| rsync | Block-level MD5 (with `--checksum`) |
| tar | None (archive structure only) |
| Borg | BLAKE2b per chunk, verified on extract |
| Restic | SHA256 per pack file, verified on `check` |
| dd | None — block-level, no error detection |

```bash
# Simulate bit rot
echo "data" > test.txt
printf '\xff' | dd of=test.txt bs=1 seek=5 conv=notrunc
# Borg/Restic detect this on next check; tar does not
```

### Incremental vs Deduplication

| Aspect | Incremental (rsync --link-dest) | Deduplication (Borg, Restic) |
|--------|-------------------------------|------------------------------|
| Granularity | File-level | Sub-file chunk-level |
| 1-byte change in 100 MB file | Copies entire 100 MB file | Stores ~4-64 KB new chunks |
| Restore chain | Full + all incrementals | Single snapshot (self-contained) |
| Complexity | Low | Medium |

Incremental = file-level tracking. Deduplication = chunk-level, detects changes WITHIN files.

### Application-Consistent Backups

File-level backup of a running database gives garbage (mixed pre/post-transaction state):

```bash
# Solution 1: LVM snapshot
lvcreate -L 10G -s -n data-snap /dev/vg/data
mount -o ro /dev/vg/data-snap /mnt/snap
tar czf backup.tar.gz /mnt/snap/
umount /mnt/snap && lvremove /dev/vg/data-snap

# Solution 2: Filesystem freeze
fsfreeze -f /var/lib/mysql   # flush + freeze
# backup here
fsfreeze -u /var/lib/mysql

# Solution 3: MySQL LOCK TABLES
mysql -e "FLUSH TABLES WITH READ LOCK;"
# snapshot here
mysql -e "UNLOCK TABLES;"
```

---

## 🛠️ 15 Hands-On Practices

### Level 1 Practices: tar, rsync, dd Basics

---

### Practice 1: tar Archive with Compression

```bash
mkdir -p ~/backup-lab/data
for i in {1..10}; do
    dd if=/dev/urandom of=~/backup-lab/data/file-$i.dat bs=1M count=1 2>/dev/null
done

tar czf ~/backup-lab/data.tar.gz -C ~/backup-lab data/
tar cjf ~/backup-lab/data.tar.bz2 -C ~/backup-lab data/
tar cJf ~/backup-lab/data.tar.xz -C ~/backup-lab data/
ls -lh ~/backup-lab/data.tar.*

tar tzf ~/backup-lab/data.tar.gz
mkdir -p ~/backup-lab/restore
tar xzf ~/backup-lab/data.tar.gz -C ~/backup-lab/restore/
ls -la ~/backup-lab/restore/data/
tar df ~/backup-lab/data.tar.gz -C ~/backup-lab/data/
```

### Practice 2: tar Incremental Backup

```bash
mkdir -p ~/backup-lab/incdata
echo "v1" > ~/backup-lab/incdata/file.txt

# Level 0 (full)
tar czf ~/backup-lab/inc-l0.tar.gz \
    --listed-incremental=~/backup-lab/inc.snar \
    -C ~/backup-lab incdata/

echo "v2" >> ~/backup-lab/incdata/file.txt
echo "new" > ~/backup-lab/incdata/new.txt

# Level 1 (incremental)
tar czf ~/backup-lab/inc-l1.tar.gz \
    --listed-incremental=~/backup-lab/inc.snar \
    -C ~/backup-lab incdata/

rm -rf ~/backup-lab/incdata
mkdir -p ~/backup-lab/restore2
tar xzf ~/backup-lab/inc-l0.tar.gz -C ~/backup-lab/restore2/
tar xzf ~/backup-lab/inc-l1.tar.gz -C ~/backup-lab/restore2/
cat ~/backup-lab/restore2/incdata/file.txt  # Should show v1 and v2
```

### Practice 3: rsync Incremental Backup Script

```bash
cat > ~/backup-lab/rsync-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=~/backup-lab/snapshots
SOURCE=~/backup-lab/srcdir
LATEST=$(ls -1 "$BACKUP_DIR" 2>/dev/null | tail -1)
mkdir -p "$BACKUP_DIR" "$SOURCE"
echo "data at $(date)" > "$SOURCE/data.txt"
DATE=$(date +%Y-%m-%d_%H%M)
LINK_DEST=""
[ -n "$LATEST" ] && LINK_DEST="--link-dest=$BACKUP_DIR/$LATEST"
rsync -av --delete $LINK_DEST "$SOURCE/" "$BACKUP_DIR/$DATE/"
EOF
chmod +x ~/backup-lab/rsync-backup.sh
for i in {1..5}; do bash ~/backup-lab/rsync-backup.sh; sleep 1; done
ls -la ~/backup-lab/snapshots/
ls -i ~/backup-lab/snapshots/*/data.txt  # same inode = hard link
du -sh ~/backup-lab/snapshots/
```

### Practice 4: dd Clone a Disk

```bash
dd if=/dev/zero of=~/backup-lab/test-disk.img bs=1M count=100 2>/dev/null
LOOP=$(sudo losetup --find --show ~/backup-lab/test-disk.img)
sudo parted "$LOOP" mklabel gpt
sudo parted "$LOOP" mkpart primary ext4 0% 50%
sudo mkfs.ext4 "${LOOP}p1"
sudo mount "${LOOP}p1" /mnt
echo "test data" | sudo tee /mnt/hello.txt
sudo umount /mnt

sudo dd if="$LOOP" of=~/backup-lab/clone.img bs=4M status=progress conv=sync

LOOP2=$(sudo losetup --find --show ~/backup-lab/clone.img)
sudo partprobe "$LOOP2"
sudo mount "${LOOP2}p1" /mnt
cat /mnt/hello.txt
sudo umount /mnt
sudo losetup -d "$LOOP" "$LOOP2"
```

---

### Level 2 Practices: ddrescue, Databases, Automation

---

### Practice 5: ddrescue Recovery

```bash
dd if=/dev/urandom of=~/backup-lab/good-disk.img bs=1M count=50 2>/dev/null
cp ~/backup-lab/good-disk.img ~/backup-lab/failing-disk.img
dd if=/dev/zero of=~/backup-lab/failing-disk.img bs=4096 seek=1000 count=5 conv=notrunc

ddrescue \
    ~/backup-lab/failing-disk.img \
    ~/backup-lab/recovered.img \
    ~/backup-lab/mapfile.log -v

ddrescuelog --list-bad ~/backup-lab/mapfile.log
cmp ~/backup-lab/good-disk.img ~/backup-lab/recovered.img || true
```

### Practice 8: mysqldump + Restore

```bash
sudo mysql -e "CREATE DATABASE backup_test;"
sudo mysql -e "CREATE TABLE backup_test.users (id INT, name VARCHAR(100));"
sudo mysql -e "INSERT INTO backup_test.users VALUES (1, 'Alice'), (2, 'Bob');"

mysqldump backup_test > ~/backup-lab/backup_test.sql
echo "Dumped: $(wc -l < ~/backup-lab/backup_test.sql) lines"

sudo mysql -e "DROP TABLE backup_test.users;"  # simulate data loss
sudo mysql -e "CREATE DATABASE restore_test;"
sudo mysql restore_test < ~/backup-lab/backup_test.sql
sudo mysql -e "SELECT * FROM restore_test.users;"
sudo mysql -e "DROP DATABASE backup_test; DROP DATABASE restore_test;"
```

### Practice 9: PostgreSQL pg_dump + Restore

```bash
sudo -u postgres createdb pg_backup_test
sudo -u postgres psql -d pg_backup_test -c "
CREATE TABLE employees (id SERIAL PRIMARY KEY, name VARCHAR(100), salary NUMERIC);
INSERT INTO employees (name, salary) VALUES ('Alice', 75000), ('Bob', 82000);
"
pg_dump -Fc pg_backup_test > ~/backup-lab/pg_backup_test.dump
pg_restore --list ~/backup-lab/pg_backup_test.dump | head -10

sudo -u postgres psql -d pg_backup_test -c "DROP TABLE employees;"
sudo -u postgres createdb pg_restore_test
pg_restore -d pg_restore_test ~/backup-lab/pg_backup_test.dump
sudo -u postgres psql -d pg_restore_test -c "SELECT * FROM employees;"
sudo -u postgres dropdb pg_backup_test
sudo -u postgres dropdb pg_restore_test
```

### Practice 10: Cloud Backup with rclone

```bash
mkdir -p ~/backup-lab/cloud-data ~/backup-lab/cloud-backup
echo "doc1" > ~/backup-lab/cloud-data/doc1.txt
echo "finance" > ~/backup-lab/cloud-data/finance.xlsx

rclone copy ~/backup-lab/cloud-data/ ~/backup-lab/cloud-backup/
ls ~/backup-lab/cloud-backup/

echo "new doc" > ~/backup-lab/cloud-data/newdoc.txt
rclone sync ~/backup-lab/cloud-data/ ~/backup-lab/cloud-backup/
rclone ls ~/backup-lab/cloud-backup/

rm -rf ~/backup-lab/cloud-data/
rclone copy ~/backup-lab/cloud-backup/ ~/backup-lab/cloud-restored/
ls ~/backup-lab/cloud-restored/
```

### Practice 11: Automate with cron

```bash
cat > ~/backup-lab/automated-backup.sh << 'SCRIPT'
#!/bin/bash
BACKUP_DIR=~/backup-lab/cron-backups
SOURCE_DIR=~/backup-lab/cron-source
TIMESTAMP=$(date +%Y%m%d-%H%M)
LOG=~/backup-lab/backup.log
mkdir -p "$BACKUP_DIR" "$SOURCE_DIR"
echo "log at $(date)" >> "$SOURCE_DIR/app.log"
tar czf "$BACKUP_DIR/data-$TIMESTAMP.tar.gz" -C "$SOURCE_DIR" .
echo "[$(date)] Backup done" >> "$LOG"
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
SCRIPT
chmod +x ~/backup-lab/automated-backup.sh

# Run and check
bash ~/backup-lab/automated-backup.sh
ls ~/backup-lab/cron-backups/
cat ~/backup-lab/backup.log
```

### Practice 12: Test a Restore

```bash
mkdir -p ~/backup-lab/production/{web,db,config}
echo "index" > ~/backup-lab/production/web/index.html
echo "db.conf" > ~/backup-lab/production/config/db.conf

export BORG_PASSPHRASE="disaster-test"
borg init --encryption=repokey ~/backup-lab/disaster-repo
borg create ~/backup-lab/disaster-repo::pre-disaster ~/backup-lab/production/

# Simulate disaster
rm -rf ~/backup-lab/production/
borg list ~/backup-lab/disaster-repo
cd ~/backup-lab && borg extract ~/backup-lab/disaster-repo::pre-disaster
cat ~/backup-lab/production/web/index.html         # restored?
cat ~/backup-lab/production/config/db.conf          # restored?
echo "✅ Restore test complete"
unset BORG_PASSPHRASE
```

### Practice 13: Backup Integrity Verification

```bash
mkdir -p ~/backup-lab/int-source
for i in {1..5}; do echo "content $i" > ~/backup-lab/int-source/file$i.txt; done
# Generate checksum manifest
find ~/backup-lab/int-source -type f -exec md5sum {} \; | \
    sed 's|.*/int-source/||' > ~/backup-lab/int-source/checksums.md5
# Backup
tar czf ~/backup-lab/int-backup.tar.gz -C ~/backup-lab int-source/
# Simulate source corruption
echo "corrupted" >> ~/backup-lab/int-source/file1.txt
# Verify backup against its own checksums
mkdir -p ~/backup-lab/int-restore && cd ~/backup-lab/int-restore
tar xzf ~/backup-lab/int-backup.tar.gz && cd
md5sum -c ~/backup-lab/int-restore/int-source/checksums.md5 2>&1 || true
```

### Practice 14: Differential Backup Strategy

```bash
mkdir -p ~/backup-lab/diff-source
echo "Day 1" > ~/backup-lab/diff-source/data.txt

# Sunday: full
tar czf ~/backup-lab/diff-sun.tar.gz \
    --listed-incremental=~/backup-lab/diff.snar -C ~/backup-lab diff-source/
echo "Mon update" >> ~/backup-lab/diff-source/data.txt
echo "report" > ~/backup-lab/diff-source/report.txt
# Monday: differential (everything since full)
tar czf ~/backup-lab/diff-mon.tar.gz \
    --listed-incremental=~/backup-lab/diff.snar -C ~/backup-lab diff-source/
echo "Tue update" >> ~/backup-lab/diff-source/data.txt
echo "report2" > ~/backup-lab/diff-source/report2.txt
# Tuesday: differential
tar czf ~/backup-lab/diff-tue.tar.gz \
    --listed-incremental=~/backup-lab/diff.snar -C ~/backup-lab diff-source/
# Restore: only full + latest (Tuesday) needed
rm -rf ~/backup-lab/diff-source
mkdir -p ~/backup-lab/diff-restore
tar xzf ~/backup-lab/diff-sun.tar.gz -C ~/backup-lab/diff-restore/
tar xzf ~/backup-lab/diff-tue.tar.gz -C ~/backup-lab/diff-restore/
find ~/backup-lab/diff-restore -type f -exec echo "Restored: {}" \;
```

---

### Level 3 Practices: Borg, Restic, Full Integration

---

### Practice 6: Borg Backup — Init, Backup, Prune

```bash
export BORG_PASSPHRASE="test-passphrase-123"
mkdir -p ~/backup-lab/sourcedata/{docs,media}
echo "plan v1" > ~/backup-lab/sourcedata/docs/plan.txt
echo "photo" > ~/backup-lab/sourcedata/media/photo.dat

borg init --encryption=repokey ~/backup-lab/borg-repo
borg create --compression zstd,9 --stats \
    ~/backup-lab/borg-repo::test-$(date +%Y-%m-%d) ~/backup-lab/sourcedata/

echo "plan v2" >> ~/backup-lab/sourcedata/docs/plan.txt
borg create --compression zstd,9 --stats \
    ~/backup-lab/borg-repo::test-$(date +%Y-%m-%d)-v2 ~/backup-lab/sourcedata/

borg list ~/backup-lab/borg-repo
borg info ~/backup-lab/borg-repo

cd ~/backup-lab && mkdir -p borg-restore && cd borg-restore
borg extract ~/backup-lab/borg-repo::test-*
ls -la

borg prune --keep-daily 2 --list ~/backup-lab/borg-repo
borg check --verify-data ~/backup-lab/borg-repo
unset BORG_PASSPHRASE
```

### Practice 7: Restic Auto-Backup

```bash
export RESTIC_PASSWORD="test-restic-pw"
restic init --repo ~/backup-lab/restic-repo

mkdir -p ~/backup-lab/appdata/{uploads,config}
echo "photo1" > ~/backup-lab/appdata/uploads/photo1.png
echo "db_host=local" > ~/backup-lab/appdata/config/database.yml

restic --repo ~/backup-lab/restic-repo backup --tag webapp ~/backup-lab/appdata/
echo "photo2" > ~/backup-lab/appdata/uploads/photo2.png
restic --repo ~/backup-lab/restic-repo backup --tag webapp ~/backup-lab/appdata/

restic --repo ~/backup-lab/restic-repo snapshots
restic --repo ~/backup-lab/restic-repo forget --keep-daily 2 --prune
restic --repo ~/backup-lab/restic-repo check
unset RESTIC_PASSWORD
```

### Practice 15: Real-World Integration — Full Backup Strategy

```bash
cat > ~/backup-lab/full-backup-strategy.sh << 'MAINSCRIPT'
#!/bin/bash
set -euo pipefail

BACKUP_ROOT="${HOME}/backup-lab/backups"
SOURCE_DIRS="${HOME}/backup-lab/data"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
LOG="${BACKUP_ROOT}/backup-${TIMESTAMP}.log"
mkdir -p "${BACKUP_ROOT}"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "${LOG}"; }

log "=== Full Backup Strategy Starting ==="

# Step 1: rsync incremental
log "Step 1: rsync incremental"
RSYNC_DEST="${BACKUP_ROOT}/rsync/${TIMESTAMP}"
RSYNC_LATEST=$(ls -1 "${BACKUP_ROOT}/rsync/" 2>/dev/null | tail -1)
LINK_DEST=""
[ -n "${RSYNC_LATEST}" ] && LINK_DEST="--link-dest=${BACKUP_ROOT}/rsync/${RSYNC_LATEST}"
rsync -av --delete ${LINK_DEST} "${SOURCE_DIRS}/" "${RSYNC_DEST}/" >> "${LOG}" 2>&1
rm -f "${BACKUP_ROOT}/rsync/latest" && ln -s "${TIMESTAMP}" "${BACKUP_ROOT}/rsync/latest"
log "  rsync done → ${RSYNC_DEST}"

# Step 2: Borg deduplicated
log "Step 2: Borg backup"
export BORG_PASSPHRASE="${BORG_PASSPHRASE:-test-pw}"
if [ ! -d "${BACKUP_ROOT}/borg-repo" ]; then
    borg init --encryption=repokey-blake2 "${BACKUP_ROOT}/borg-repo" >> "${LOG}" 2>&1
fi
borg create --compression zstd,9 --stats \
    "${BACKUP_ROOT}/borg-repo::${HOSTNAME}-${TIMESTAMP}" \
    "${SOURCE_DIRS}" >> "${LOG}" 2>&1
borg prune --keep-daily 7 --list "${BACKUP_ROOT}/borg-repo" >> "${LOG}" 2>&1
borg check --verify-data "${BACKUP_ROOT}/borg-repo" >> "${LOG}" 2>&1 && \
    log "  Borg integrity PASS" || log "  Borg integrity FAIL"
unset BORG_PASSPHRASE

# Step 3: Database (if available)
log "Step 3: Database"
if command -v mysqldump &>/dev/null; then
    mkdir -p "${BACKUP_ROOT}/databases"
    mysqldump --all-databases --single-transaction | \
        gzip > "${BACKUP_ROOT}/databases/mysql-all-${TIMESTAMP}.sql.gz"
    log "  MySQL dump done"
fi

# Step 4: Restore test (Sundays only)
if [ "$(date +%u)" -eq 7 ]; then
    log "Step 4: Restore test (Sunday)"
    TEST_DIR=$(mktemp -d)
    cp -al "${BACKUP_ROOT}/rsync/${TIMESTAMP}/" "${TEST_DIR}/rsync-test/"
    COUNT=$(find "${TEST_DIR}/rsync-test/" -type f | wc -l)
    log "  Verified: ${COUNT} files restored"
    rm -rf "${TEST_DIR}"
fi

log "=== Backup Complete ==="
MAINSCRIPT
chmod +x ~/backup-lab/full-backup-strategy.sh

# Run it
mkdir -p ~/backup-lab/data
echo "web content" > ~/backup-lab/data/index.html
echo "db schema" > ~/backup-lab/data/schema.sql
bash ~/backup-lab/full-backup-strategy.sh
tail -5 ~/backup-lab/backups/backup-*.log
```

---

## 📋 Command Reference

### Level 1 Commands: tar, rsync, dd

**tar**
| Command | Description |
|---------|-------------|
| `tar cf a.tar /p/` | Create archive |
| `tar czf a.tar.gz /p/` | Create gzip archive |
| `tar xf a.tar` | Extract |
| `tar tf a.tar` | List |

**rsync**
| Command | Description |
|---------|-------------|
| `rsync -av /s/ /d/` | Local sync |
| `rsync -avz /s/ u@h:/d/` | Remote push |
| `rsync -avz u@h:/s/ /d/` | Remote pull |
| `rsync -av --delete /s/ /d/` | Mirror |
| `rsync -avn /s/ /d/` | Dry run |

**dd**
| Command | Description |
|---------|-------------|
| `dd if=/dev/sda of=i.img bs=4M status=progress` | Clone disk |
| `dd if=i.img of=/dev/sda bs=4M` | Restore image |
| `dd if=/dev/sda bs=4M conv=sync,noerror` | Skip errors |
| `dd if=/dev/zero of=s.img bs=1M seek=1000 count=0` | Sparse file |

### Level 2 Commands: tar Advanced, rsync Advanced, ddrescue, dump, Database

**tar**
| Command | Description |
|---------|-------------|
| `tar czf - /p/ \| ssh h "cat > b.tgz"` | Archive over SSH |
| `tar czf b.tgz --exclude='*.log' /p/` | Exclude |
| `tar --listed-incremental=s -czf i.tgz /p/` | Incremental |

**rsync**
| Command | Description |
|---------|-------------|
| `rsync -av --link-dest=D /s/ /d/` | Incremental hard-link |
| `rsync -av --bwlimit=1024 /s/ u@h:/d/` | Bandwidth limit |
| `rsync -aH /s/ /d/` | Preserve hard links |

**ddrescue**
| Command | Description |
|---------|-------------|
| `ddrescue -d /dev/sda img.dd map.log` | Recover failing disk |
| `ddrescue -d -r3 /dev/sda img.dd map.log` | Retry bad 3× |
| `ddrescuelog --list-bad map.log` | Show bad sectors |

**dump/restore**
| Command | Description |
|---------|-------------|
| `dump -0uf b.dump /dev/sda1` | Level 0 dump |
| `dump -1uf b.dump /dev/sda1` | Level 1 incremental |
| `restore -rf b.dump` | Full restore |
| `restore -if b.dump` | Interactive restore |

**Database**
| Command | Description |
|---------|-------------|
| `mysqldump --all-databases --single-transaction > b.sql` | MySQL dump |
| `pg_dump -Fc db > db.dump` | PostgreSQL dump |
| `pg_restore -d db db.dump` | PostgreSQL restore |
| `sqlite3 db ".backup b.db"` | SQLite backup |
| `mongodump --out /b/` | MongoDB dump |

### Level 3 Commands: Borg, Restic, Cloud

**Borg**
| Command | Description |
|---------|-------------|
| `borg init --encryption=repokey /r` | Init repo |
| `borg create --compression zstd,9 /r::a /p` | Create backup |
| `borg list /r` | List archives |
| `borg extract /r::a` | Extract |
| `borg mount /r::a /mnt` | Mount |
| `borg prune --keep-daily 7 /r` | Prune |
| `borg check --verify-data /r` | Integrity check |
| `borg info /r` | Dedup stats |

**Restic**
| Command | Description |
|---------|-------------|
| `restic init --repo /r` | Init repo |
| `restic backup /p` | Backup |
| `restic snapshots` | List snapshots |
| `restic restore latest --target /r` | Restore |
| `restic mount /mnt` | Mount FUSE |
| `restic forget --keep-daily 7 --prune` | Retention |
| `restic check --read-data` | Integrity check |
| `restic unlock` | Remove stale locks |

**Cloud**
| Command | Description |
|---------|-------------|
| `rclone sync /src/ remote:/dst/` | Sync to cloud |
| `rclone ls remote:/path/` | List cloud |
| `aws s3 sync /src/ s3://bucket/` | AWS S3 sync |

---

## 📚 What's Coming in Part 33

**Part 33: System Monitoring** — prometheus, node_exporter, grafana, alertmanager, metrics collection, dashboards, alert rules, systemd journal, logwatch, auditd, performance monitoring, capacity planning.

---

## 📝 Self-Test

1. What does the "2" in the 3-2-1 backup rule refer to?
2. What is the difference between RPO and RTO?
3. An incremental backup captures changes since __________. A differential backup captures changes since __________.
4. When using `rsync --link-dest`, what happens to files that haven't changed?
5. What does `conv=sync,noerror` do in `dd`?
6. What is the purpose of the mapfile in `ddrescue`?
7. In Borg, what is the difference between `repokey` and `keyfile` encryption?
8. What does `restic forget --keep-daily 7 --prune` do?
9. Why is a file-level backup of a running MySQL database potentially inconsistent?
10. What does `mysqldump --single-transaction` guarantee?
11. Why must you test restores, not just backups?
12. What is the difference between incremental backup and deduplication?
13. How does `fsync` affect backup reliability?
14. What is a sparse file, and why does its handling matter?
15. In `tar --listed-incremental`, what is stored in the `.snar` file?

**Score:** 12/15 correct = ready for Part 33.

---

*Previous → Part 31: LVM*
*Next → Part 33: System Monitoring*

[← Previous](part31.md) | [Next →](part33.md)
