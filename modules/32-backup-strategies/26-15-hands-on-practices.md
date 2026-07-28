## 🛠️ 15 Hands-On Practices

### Level 1 Practices: tar, rsync, dd Basics


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


### Level 2 Practices: ddrescue, Databases, Automation


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


### Level 3 Practices: Borg, Restic, Full Integration


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





[← Previous](25-deep-understanding.md) | [↑ Index](index.md) | [Next →](27-command-reference.md)
