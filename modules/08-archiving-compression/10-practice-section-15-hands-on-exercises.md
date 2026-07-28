## 💻 PRACTICE SECTION — 15 Hands-On Exercises


### ✅ Practice 1: Create Test Files

```bash
mkdir -p ~/linux-course/part8
cd ~/linux-course/part8

# Create a test project structure
mkdir -p myproject/{src,docs,logs,backup}

# Create some files
echo "print('Hello')" > myproject/src/main.py
echo "print('Helper')" > myproject/src/utils.py
echo "# Documentation" > myproject/docs/README.md
echo "2024-01-15 INFO Started" > myproject/logs/app.log
echo "2024-01-15 WARNING Memory high" >> myproject/logs/app.log

# Create a text file for compression tests
for i in $(seq 1 1000); do
    echo "This is line $i of the test file for compression testing."
done > test_large.txt

# Show the structure
find myproject -type f | sort
```


### ✅ Practice 2: Create tar Archives

```bash
cd ~/linux-course/part8

# Create uncompressed tar
tar -cf myproject.tar myproject
ls -lh myproject.tar

# Create gzip compressed tar
tar -czf myproject.tar.gz myproject
ls -lh myproject.tar.gz

# Create bzip2 compressed tar
tar -cjf myproject.tar.bz2 myproject
ls -lh myproject.tar.bz2

# Create xz compressed tar
tar -cJf myproject.tar.xz myproject
ls -lh myproject.tar.xz

# Compare sizes
ls -lh myproject.tar*
```


### ✅ Practice 3: List Archive Contents

```bash
cd ~/linux-course/part8

# List files in tar
tar -tf myproject.tar

# List with details
tar -tvf myproject.tar.gz

# Count files in archive
tar -tf myproject.tar.gz | wc -l

# Check for a specific file
tar -tf myproject.tar.gz | grep "main.py"
```


### ✅ Practice 4: Extract Archives

```bash
cd ~/linux-course/part8

# Extract tar.gz to a new directory
mkdir extract_test
tar -xf myproject.tar.gz -C extract_test
find extract_test -type f

# Extract single file
mkdir extract_single
tar -xf myproject.tar.gz -C extract_single myproject/src/main.py
find extract_single -type f

# Extract with verbose
mkdir extract_verbose
tar -xvf myproject.tar.gz -C extract_verbose
```


### ✅ Practice 5: Exclude Files When Creating

```bash
cd ~/linux-course/part8

# Create archive excluding logs
tar -czf myproject_no_logs.tar.gz --exclude="*.log" myproject
tar -tf myproject_no_logs.tar.gz

# Create archive excluding directory
tar -czf myproject_no_src.tar.gz --exclude="myproject/src" myproject
tar -tf myproject_no_src.tar.gz
```


### ✅ Practice 6: Use -C for Relative Paths

```bash
cd ~/linux-course/part8

# Without -C (absolute path stored in archive)
tar -czf absolute.tar.gz ~/linux-course/part8/myproject
tar -tvf absolute.tar.gz | head -3
# Shows: home/user/linux-course/part8/myproject/...

# With -C (relative path)
tar -czf relative.tar.gz -C ~/linux-course/part8 myproject
tar -tvf relative.tar.gz | head -3
# Shows: myproject/...
```


### ✅ Practice 7: Compression Benchmarks

```bash
cd ~/linux-course/part8

# Compare compression levels
gzip -1 -k test_large.txt -c > test_level1.gz
gzip -6 -k test_large.txt -c > test_level6.gz
gzip -9 -k test_large.txt -c > test_level9.gz
bzip2 -k test_large.txt
xz -k test_large.txt

# Compare sizes
ls -lh test_large.txt test_level*.gz test_large.txt.bz2 test_large.txt.xz

# Clean up
rm -f test_level*.gz test_large.txt.bz2 test_large.txt.xz
```


### ✅ Practice 8: Standalone gzip

```bash
cd ~/linux-course/part8

# Compress
cp test_large.txt compress_me.txt
gzip compress_me.txt
ls -lh compress_me.txt.gz
# Original is gone!

# Decompress
gunzip compress_me.txt.gz
ls -lh compress_me.txt

# Compress and keep original (gzip 1.6+)
gzip -k compress_me.txt
ls -lh compress_me.txt compress_me.txt.gz

# Compression info
gzip -l compress_me.txt.gz
```


### ✅ Practice 9: zgrep and zcat

```bash
cd ~/linux-course/part8

# Create a compressed log
gzip -k myproject/logs/app.log

# Use zcat to view
zcat myproject/logs/app.log.gz

# Use zgrep to search
zgrep "WARNING" myproject/logs/app.log.gz

# Count lines in compressed file
zcat myproject/logs/app.log.gz | wc -l
```


### ✅ Practice 10: zip

```bash
cd ~/linux-course/part8

# Create zip archive
zip -r myproject.zip myproject
ls -lh myproject.zip

# List contents
unzip -l myproject.zip

# Extract to directory
mkdir zip_extract
unzip myproject.zip -d zip_extract
find zip_extract -type f

# Create password-protected zip
zip -e -r secret.zip myproject/docs
# Type a password when prompted

# Test integrity
unzip -t myproject.zip
```


### ✅ Practice 11: Split Archives

```bash
cd ~/linux-course/part8

# Create an archive and split into 1MB chunks
tar -czf - myproject | split -b 1M - myarchive_part_
ls -lh myarchive_part_*

# Reassemble
cat myarchive_part_* > reassembled.tar.gz
tar -tf reassembled.tar.gz | head -5

# Clean up
rm -f myarchive_part_* reassembled.tar.gz
```


### ✅ Practice 12: Add and Update Files in tar

```bash
cd ~/linux-course/part8

# Create an uncompressed tar (compressed tar doesn't support -r)
tar -cf editable.tar myproject/src

# Add more files
echo "New file content" > newfile.txt
tar -rf editable.tar newfile.txt

# List contents (now has newfile.txt)
tar -tf editable.tar

# Update files (only if newer)
tar -uf editable.tar newfile.txt

# Delete from archive
tar -f editable.tar --delete newfile.txt
tar -tf editable.tar
```


### ✅ Practice 13: Real Backup Script

```bash
cd ~/linux-course/part8

# Create a practical backup script
cat > backup_tool.sh << 'EOF'
#!/bin/bash
set -euo pipefail

SOURCE="${1:-}"
DEST="${2:-/tmp/backups}"
DATE=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)

usage() {
    echo "Usage: $0 <source_directory> [backup_destination]"
    exit 1
}

[ -z "$SOURCE" ] && usage
[ ! -d "$SOURCE" ] && echo "Error: $SOURCE not found" && exit 1

mkdir -p "$DEST"

BASENAME=$(basename "$SOURCE")
ARCHIVE="${DEST}/${HOSTNAME}_${BASENAME}_${DATE}.tar.gz"

echo "Creating backup of $SOURCE..."
echo "Destination: $ARCHIVE"

tar -czf "$ARCHIVE" \
    --exclude="*.tmp" \
    --exclude="*.swp" \
    --exclude=".cache" \
    -C "$(dirname "$SOURCE")" "$BASENAME"

echo "Backup created: $(du -h "$ARCHIVE" | cut -f1)"
echo "Contents:"
tar -tf "$ARCHIVE" | head -10
echo "... ($(tar -tf "$ARCHIVE" | wc -l) total files)"
EOF

chmod +x backup_tool.sh

# Test it
./backup_tool.sh myproject /tmp/backup_test
ls -lh /tmp/backup_test/
```


### ✅ Practice 14: Extract Specific File Patterns

```bash
cd ~/linux-course/part8

# Create archive with various file types
mkdir multifile_test
echo "log1" > multifile_test/app.log
echo "log2" > multifile_test/access.log
echo "text" > multifile_test/readme.txt
echo "data" > multifile_test/data.csv
echo "config" > multifile_test/config.ini

tar -czf multifile.tar.gz multifile_test

# Extract only .log files
mkdir extract_logs
tar -xf multifile.tar.gz -C extract_logs --wildcards '*.log'
find extract_logs -type f

# Extract only .txt files
mkdir extract_txt
tar -xf multifile.tar.gz -C extract_txt --wildcards '*.txt'
find extract_txt -type f
```


### ✅ Practice 15: Real SysAdmin Scenario — Log Archival

```bash
cd ~/linux-course/part8

# Create sample archived logs scenario
mkdir -p /tmp/log_archive_practice/var/log
for i in $(seq 1 5); do
    echo "Log entry $i for $(date -d "-$i days" +%Y-%m-%d)" > \
        "/tmp/log_archive_practice/var/log/app_$(date -d "-$i days" +%Y%m%d).log"
done

# Simulate log rotation: archive logs older than 3 days
cat > rotate_and_archive.sh << 'EOF'
#!/bin/bash
set -euo pipefail

LOG_DIR="${1:-/tmp/log_archive_practice/var/log}"
ARCHIVE_DIR="${2:-/tmp/log_archive_practice/archive}"
DAYS_OLD="${3:-3}"
DATE=$(date +%Y%m%d)

mkdir -p "$ARCHIVE_DIR"

echo "=== Log Archival ==="
echo "Source: $LOG_DIR"
echo "Archive: $ARCHIVE_DIR"
echo "Archiving logs older than $DAYS_OLD days"
echo ""

# Find old logs
OLD_LOGS=$(find "$LOG_DIR" -name "*.log" -type f -mtime "+$DAYS_OLD")

if [ -z "$OLD_LOGS" ]; then
    echo "No logs older than $DAYS_OLD days found."
    exit 0
fi

# Create compressed archive of old logs
echo "$OLD_LOGS" | tar -czf "$ARCHIVE_DIR/logs_${DATE}.tar.gz" -T -

echo "Archived $(echo "$OLD_LOGS" | wc -l) log files to $ARCHIVE_DIR/logs_${DATE}.tar.gz"

# Remove original logs (uncomment to actually remove)
# echo "$OLD_LOGS" | while read -r log; do
#     rm "$log"
#     echo "Removed: $log"
# done

echo "Done."
EOF

chmod +x rotate_and_archive.sh
./rotate_and_archive.sh

# Verify the archive
tar -tvf /tmp/log_archive_practice/archive/logs_*.tar.gz
```





[← Previous](09-section-8-splitting-large-archives.md) | [↑ Index](index.md) | [Next →](11-deep-understanding-how-compression-works.md)
