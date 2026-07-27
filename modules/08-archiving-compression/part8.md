# 🐧 Linux System Administrator — Complete Course
## Part 8 of ∞: Archiving and Compression — tar, gzip, zip

---

> **Reverse Engineering Approach:** Every sysadmin backs up files, transfers data, and archives logs. The tools we cover in this part are the difference between a clean backup strategy and data loss. We start from the question: *Why compress? Why archive? Why not just copy?* Then we build the complete picture of how Linux handles packed data.

---

## 🎯 What You Will Achieve in Part 8

By the end of this part, you will:

- Understand the difference between archiving and compression
- Create and extract tar archives of any type
- Use gzip, bzip2, and xz — and know which to choose
- Combine tar with compression in a single command
- Create and extract zip files (cross-platform)
- Backup directories with proper tar options
- View and inspect archive contents without extracting
- Automate backups with compression in scripts
- Complete **15 hands-on practices**

---

## 🔍 Section 1: Archiving vs Compression — Two Different Jobs

Most beginners think "zipping" is one operation. It is actually two:

| Operation | What It Does | Tool |
|-----------|-------------|------|
| **Archiving** | Packs many files into ONE file (no size reduction) | `tar`, `cpio` |
| **Compression** | Makes a file smaller using algorithms | `gzip`, `bzip2`, `xz` |

```
Individual files (each is its own thing):
  file1.txt  file2.txt  file3.txt  file4.txt

After ARCHIVE (tar):
  archive.tar  (all files merged, same total size)

After COMPRESSION (gzip):
  archive.tar.gz  (smaller, but you need to decompress first)
```

> 💡 `tar` does both in one step. When you run `tar -czf archive.tar.gz files/`, tar is archiving and gzip is compressing. Tar just orchestrates the pipe internally.

### Visual Comparison

```bash
# Create some test files
dd if=/dev/urandom of=file1.bin bs=1M count=1 2>/dev/null
dd if=/dev/urandom of=file2.bin bs=1M count=1 2>/dev/null

# Archive only (no compression) — size stays ~2MB
tar -cf archive.tar file1.bin file2.bin
ls -lh archive.tar     # ~2.0 MB

# Archive with gzip — smaller
tar -czf archive.tar.gz file1.bin file2.bin
ls -lh archive.tar.gz  # ~2.0 MB (random data doesn't compress well)

# With text files (which compress well):
echo "AAAAABBBBBCCCCCDDDDD" > text1.txt
echo "EEEEEFFFFFGGGGGHHHHH" > text2.txt
tar -cf text.tar text1.txt text2.txt
tar -czf text.tar.gz text1.txt text2.txt
ls -lh text.tar text.tar.gz
# text.tar: ~200 bytes
# text.tar.gz: ~100 bytes (much smaller!)
```

---

## 🔍 Section 2: tar — The Tape Archiver

`tar` stands for **T**ape **AR**chiver. It was created in 1979 for magnetic tape drives, and it is still the standard for Linux archiving.

### Basic Syntax

```bash
tar [options] [archive_name] [files_to_archive]
```

### The Three Essential Operations

```bash
# Create an archive (c = create)
tar -cf archive.tar file1 file2 directory/

# Extract an archive (x = extract)
tar -xf archive.tar

# List contents (t = list)
tar -tf archive.tar
```

### Common Options

```bash
-c    Create an archive
-x    Extract an archive
-t    List contents (table of contents)
-f    Archive filename (ALWAYS the last option before the filename)
-v    Verbose (show files as they're processed)
-z    Filter through gzip (compression)
-j    Filter through bzip2
-J    Filter through xz
--exclude    Skip files matching pattern
-C    Change to directory before operating
```

### Create Archives

```bash
# Create uncompressed archive
tar -cf backup.tar /home/alice/documents

# Create gzip-compressed archive (most common)
tar -czf backup.tar.gz /home/alice/documents

# Create bzip2-compressed (better compression, slower)
tar -cjf backup.tar.bz2 /home/alice/documents

# Create xz-compressed (best compression, slowest)
tar -cJf backup.tar.xz /home/alice/documents

# Verbose mode (watch it work)
tar -czvf backup.tar.gz /home/alice/documents

# Exclude files
tar -czf backup.tar.gz /home/alice/documents --exclude="*.tmp" --exclude="*.log"

# Exclude a directory
tar -czf backup.tar.gz /home/alice --exclude="home/alice/.cache"

# Save relative paths (not full absolute paths)
tar -czf backup.tar.gz -C /home/alice documents
# Result: archive contains "documents/..." not "home/alice/documents/..."
```

### Extract Archives

```bash
# Extract in current directory
tar -xf backup.tar.gz

# Extract to a specific directory
tar -xf backup.tar.gz -C /tmp/restore/

# Extract a single file from archive
tar -xf backup.tar.gz documents/report.pdf

# Extract multiple files by pattern
tar -xf backup.tar.gz --wildcards '*.txt'

# Extract with verbose
tar -xvf backup.tar.gz

# Extract and strip leading directory (remove top-level folder)
tar -xf backup.tar.gz --strip-components=1
```

### List Archive Contents

```bash
# List all files in archive
tar -tf backup.tar.gz

# List with details (like ls -l)
tar -tvf backup.tar.gz

# Check if a specific file is in the archive
tar -tf backup.tar.gz | grep "report.pdf"

# Quick file count in archive
tar -tf backup.tar.gz | wc -l
```

---

## 🔍 Section 3: Compression Tools Compared

| Tool | Extension | Speed | Compression Ratio | Use Case |
|------|-----------|-------|-------------------|----------|
| `gzip` | `.gz` | Fast | Medium | Daily use, log rotation |
| `bzip2` | `.bz2` | Medium | Better than gzip | Distribution packages |
| `xz` | `.xz` | Slow | Best | Long-term archiving |

### Standalone Compression Commands

```bash
# gzip
gzip file.txt              # Creates file.txt.gz, removes original
gzip -k file.txt           # Keep original file (gzip 1.6+)
gzip -d file.txt.gz        # Decompress (same as gunzip)
gunzip file.txt.gz         # Same as gzip -d
gzip -l file.txt.gz        # List compression info

# bzip2
bzip2 file.txt             # Creates file.txt.bz2
bzip2 -d file.txt.bz2      # Decompress
bunzip2 file.txt.bz2       # Same as bzip2 -d

# xz
xz file.txt                # Creates file.txt.xz
xz -d file.txt.xz          # Decompress
unxz file.txt.xz           # Same as xz -d
xz -l file.txt.xz          # List compression info
```

### Compression Levels

```bash
# All three tools support levels 1-9
# 1 = fastest, least compression
# 6 = default (good balance)
# 9 = slowest, best compression

gzip -1 file.txt    # Fast, less compression
gzip -9 file.txt    # Slow, best compression
xz -9 file.txt      # Very slow, very small
```

### Benchmark (Approximate)

| Tool | Compress Time | Size | Decompress Time |
|------|--------------|------|-----------------|
| None | 0s | 100 MB | 0s |
| gzip -1 | 2s | 35 MB | 0.5s |
| gzip -6 | 5s | 33 MB | 0.5s |
| gzip -9 | 10s | 32 MB | 0.5s |
| bzip2 -9 | 30s | 28 MB | 5s |
| xz -6 | 60s | 25 MB | 8s |
| xz -9 | 180s | 24 MB | 10s |

> 💡 **Default choice:** Use `gzip` (via `tar -czf`) for 99% of your work. It is fast enough and compresses well. Only use `xz` for long-term archives where size matters more than time.

---

## 🔍 Section 4: Viewing and Manipulating Archives Without Extracting

```bash
# List contents (already covered)
tar -tf archive.tar.gz

# View a text file inside archive without extracting
tar -xf archive.tar.gz -O file.txt | less
# -O = extract to stdout (not to disk)

# Compare a file inside archive with the live version
tar -xf archive.tar.gz -O etc/hosts | diff - /etc/hosts

# Search inside archive files
tar -xf archive.tar.gz -O var/log/syslog | grep "ERROR"

# Add files to an existing archive
tar -rf archive.tar newfile.txt
# Note: -r only works with uncompressed tar, not tar.gz

# Delete files from an archive
tar -f archive.tar --delete file.txt
# Note: only works with uncompressed tar

# Update files in archive (only if newer)
tar -uf archive.tar file.txt
```

### Using zcat, zless, zgrep

These utilities let you work with compressed files as if they were plain text:

```bash
# View compressed file
zcat backup.tar.gz            # Cat a .gz file
zless backup.tar.gz           # Page through .gz file
zgrep "error" backup.tar.gz   # Search inside .gz file

# Same for bzip2
bzcat file.bz2
bzless file.bz2
bzgrep "pattern" file.bz2

# Same for xz
xzcat file.xz
xzless file.xz
xzgrep "pattern" file.xz
```

---

## 🔍 Section 5: zip — Cross-Platform Archiving

`zip` is the most compatible archive format. Every operating system can open it without extra tools.

### Create zip Archives

```bash
# Create a zip archive
zip archive.zip file1.txt file2.txt

# Create zip from directory (recursively)
zip -r archive.zip directory/

# With compression level (0=store, 6=default, 9=maximum)
zip -9 -r archive.zip directory/

# Add password protection
zip -e -r secret.zip documents/
# You'll be prompted for a password

# Encrypt with AES (more secure)
zip -e --encryption-method aes-256 -r secret.zip documents/

# Exclude files
zip -r archive.zip directory/ -x "*.tmp" "*.log"

# Split into multiple volumes (for large archives)
zip -s 100m -r archive.zip directory/
# Creates archive.z01, archive.z02, archive.zip
```

### Extract zip Archives

```bash
# Extract to current directory
unzip archive.zip

# Extract to specific directory
unzip archive.zip -d /tmp/extracted/

# Extract single file
unzip archive.zip path/to/file.txt

# List contents (without extracting)
unzip -l archive.zip

# Test integrity
unzip -t archive.zip
```

### zip vs tar.gz

| Aspect | zip | tar.gz |
|--------|-----|--------|
| Compression | Built into format | Separate layer (gzip) |
| Cross-platform | Excellent (Windows, Mac, Linux) | Linux/Unix primarily |
| Streaming | No (index at end of file) | Yes (can pipe) |
| Metadata (permissions) | Limited | Preserves Unix permissions |
| Random access | Yes | No (must decompress sequentially) |

---

## 🔍 Section 6: Other Archiving Tools

### cpio — The Old Standard

```bash
# Create cpio archive (used in RPM packages)
find /etc -name "*.conf" | cpio -ov > configs.cpio

# Extract
cpio -iv < configs.cpio

# Create compressed cpio
find /etc -name "*.conf" | cpio -ov | gzip > configs.cpio.gz
```

### ar — Static Library Archiver

```bash
# Create static library
ar rcs libexample.a file1.o file2.o

# List contents
ar t libexample.a

# Extract
ar x libexample.a
```

### 7z — 7-Zip (High Compression)

```bash
# Install
sudo apt install p7zip-full   # Debian/Ubuntu
sudo dnf install p7zip         # Fedora

# Create 7z archive
7z a archive.7z directory/

# Extract
7z x archive.7z

# List
7z l archive.7z
```

---

## 🔍 Section 7: Real Backup Patterns

### Pattern 1: Simple Directory Backup

```bash
#!/bin/bash
# backup.sh — Simple daily backup
BACKUP_DIR="/backup"
SOURCE="/home/alice/documents"
DATE=$(date +%Y%m%d)

tar -czf "$BACKUP_DIR/documents_$DATE.tar.gz" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
```

### Pattern 2: Backup With Timestamp and Log

```bash
#!/bin/bash
# backup_with_log.sh
BACKUP_DIR="/var/backups"
SOURCE="/etc"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/backup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log "Starting backup of $SOURCE"
if tar -czf "$BACKUP_DIR/etc_$DATE.tar.gz" -C / etc 2>> "$LOG_FILE"; then
    log "Backup completed: $(du -h "$BACKUP_DIR/etc_$DATE.tar.gz" | cut -f1)"
else
    log "BACKUP FAILED!"
    exit 1
fi
```

### Pattern 3: Incremental Backup Using find + tar

```bash
#!/bin/bash
# incremental_backup.sh
BACKUP_DIR="/backup/incremental"
SOURCE="/home/alice"
DATE=$(date +%Y%m%d)
CUTOFF=$(date -d "-1 day" +%Y-%m-%d)

# Find files changed in last 24 hours
CHANGED_FILES=$(find "$SOURCE" -type f -newermt "$CUTOFF" ! -path "*/.cache/*")

if [ -n "$CHANGED_FILES" ]; then
    echo "$CHANGED_FILES" | tar -czf "$BACKUP_DIR/incremental_$DATE.tar.gz" -T -
    echo "Incremental backup created: $BACKUP_DIR/incremental_$DATE.tar.gz"
else
    echo "No files changed since $CUTOFF"
fi
```

### Pattern 4: Full System Backup (Excluding Special Dirs)

```bash
#!/bin/bash
# full_system_backup.sh
BACKUP_DIR="/backup/full"
DATE=$(date +%Y%m%d)

tar -czpf "$BACKUP_DIR/full_system_$DATE.tar.gz" \
    --exclude="/proc" \
    --exclude="/sys" \
    --exclude="/dev" \
    --exclude="/run" \
    --exclude="/mnt" \
    --exclude="/media" \
    --exclude="/lost+found" \
    --exclude="/tmp" \
    --exclude="/backup" \
    --exclude="*.swp" \
    --exclude="*.cache" \
    / 2>> "$BACKUP_DIR/backup_$DATE.log"
```

---

## 🔍 Section 8: Splitting Large Archives

When an archive is too large for a filesystem or transfer medium, split it:

```bash
# Method 1: Create then split
tar -czf large_backup.tar.gz /data/
split -b 100M large_backup.tar.gz backup_part_
# Creates: backup_part_aa, backup_part_ab, backup_part_ac, ...

# Reassemble:
cat backup_part_* > large_backup.tar.gz
tar -xf large_backup.tar.gz

# Method 2: Pipe through split (no intermediate file)
tar -czf - /data/ | split -b 100M - backup_pipe_
```

### split Options

```bash
split -b 100M file part_     # Split by size
split -l 1000 file part_     # Split by number of lines
split -n 5 file part_        # Split into 5 equal parts

# Rejoin:
cat part_* > original_file
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

## 🧠 Deep Understanding — How Compression Works

### The Core Idea

Compression works by finding and eliminating **redundancy**.

```bash
# Original:  AAAAABBBBBCCCCCDDDDD  (25 bytes)
# gzip can represent this as:
# 5A5B5C5D = 8 bytes (run-length encoding + Huffman)

# Real data is more complex, but the principle is the same.
# Text files compress well (high redundancy).
# Already-compressed files (JPEG, MP4, ZIP) compress poorly or grow.
```

### Why Compressing Already-Compressed Files Is Useless

```bash
# This does nothing useful:
tar -czf archive.tar.gz files/
gzip archive.tar.gz    # archive.tar.gz.gz — barely smaller

# Always compress ONCE at the archive level.
```

### gzip Internal Structure

```
A gzip file has:
  - Header: magic bytes (1f 8b), compression method, timestamps
  - Compressed blocks (DEFLATE algorithm)
  - Trailer: CRC32 checksum, original size

The checksum lets you verify data integrity:
  gzip -t file.gz    # Test integrity, exit code 0 if OK
```

### Tar Format

```
A tar file is a sequence of 512-byte blocks:
  [HEADER BLOCK] [DATA BLOCKS...] [HEADER BLOCK] [DATA BLOCKS...] ...
  End marker: two 512-byte blocks of zeros

Each header contains:
  - Filename (100 chars max in old format)
  - Mode (permissions)
  - Owner UID/GID
  - File size
  - Modification time
  - Checksum
  - Type flag (file, dir, link, etc.)
  - Link target (for symlinks)

Modern tar (GNU tar) supports:
  - Long filenames (via @LongLink extension)
  - Sparse files
  - ACLs and SELinux contexts (with --acls, --selinux)
  - Incremental backups
```

---

## 📋 Summary — Complete Command Reference for Part 8

### tar

| Command | Action |
|---------|--------|
| `tar -cf archive.tar files` | Create archive |
| `tar -czf archive.tar.gz files` | Create gzip-compressed archive |
| `tar -cjf archive.tar.bz2 files` | Create bzip2 archive |
| `tar -cJf archive.tar.xz files` | Create xz archive |
| `tar -xf archive.tar.gz` | Extract archive |
| `tar -xf archive.tar.gz -C /dir` | Extract to specific directory |
| `tar -tf archive.tar.gz` | List contents |
| `tar -tvf archive.tar.gz` | List with details |
| `tar -xf archive.tar.gz file.txt` | Extract single file |
| `tar -czf archive.tar.gz --exclude="*.log" dir` | Exclude files |
| `tar -czf archive.tar.gz -C /path dir` | Use relative paths |
| `tar -rf archive.tar file` | Add file to existing archive |
| `tar -f archive.tar --delete file` | Delete file from archive |

### Compression Tools

| Command | Action |
|---------|--------|
| `gzip file` | Compress (removes original) |
| `gzip -k file` | Compress (keep original) |
| `gunzip file.gz` | Decompress |
| `gzip -l file.gz` | Compression info |
| `gzip -t file.gz` | Test integrity |
| `bzip2 file` | bzip2 compression |
| `bunzip2 file.bz2` | bzip2 decompression |
| `xz file` | xz compression |
| `unxz file.xz` | xz decompression |

### Compressed File Viewers

| Command | Action |
|---------|--------|
| `zcat file.gz` | View compressed file |
| `zless file.gz` | Page through compressed file |
| `zgrep pattern file.gz` | Search compressed file |
| `bzcat file.bz2` | View bz2 file |
| `xzcat file.xz` | View xz file |

### zip

| Command | Action |
|---------|--------|
| `zip archive.zip files` | Create zip archive |
| `zip -r archive.zip dir` | Recursive directory zip |
| `zip -e archive.zip files` | Password-protected zip |
| `unzip archive.zip` | Extract zip |
| `unzip archive.zip -d /dir` | Extract to directory |
| `unzip -l archive.zip` | List contents |
| `unzip -t archive.zip` | Test integrity |

### split

| Command | Action |
|---------|--------|
| `split -b 100M file prefix` | Split by size |
| `split -l 1000 file prefix` | Split by lines |
| `cat prefix_* > original` | Rejoin split files |

---

## 🚀 What's Coming in Part 9

**Part 9: Process Management — ps, top, kill, and Signals**

You will learn:
- What a process is and how Linux tracks it
- Listing processes with ps and top
- Understanding process states (running, sleeping, zombie)
- Sending signals to processes with kill
- Prioritizing processes with nice and renice
- Managing background and foreground jobs
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between archiving and compression?
2. What does `tar -czf archive.tar.gz dir/` do?
3. How do you list the contents of a `.tar.gz` file without extracting?
4. How do you extract a tar.gz to a specific directory?
5. What is the difference between gzip, bzip2, and xz?
6. How do you create a tar archive that excludes `.log` files?
7. What does `tar -xf archive.tar.gz file.txt` do?
8. How do you view a compressed text file without decompressing it?
9. What utility would you use to search for "error" inside a .gz file?
10. How do you create a password-protected zip file?
11. What is the `-C` option in tar used for?
12. What does `zcat` do?
13. How would you split a large tar.gz into 50MB pieces?
14. What is the `--exclude` option in tar used for?
15. Why does re-compressing a compressed file not help?

**Score:** 12/15 correct = ready for Part 9.

---

*Linux SysAdmin Course | Part 8 of ∞ | Reverse Engineering Approach*
*Previous → Part 7: Finding Things — grep, find, locate, and Beyond*
*Next → Part 9: Process Management — ps, top, kill, and Signals*

[← Previous](part7.md) | [Next →](part9.md)
