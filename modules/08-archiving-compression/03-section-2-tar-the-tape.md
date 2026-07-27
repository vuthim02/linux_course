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



---

[← Previous](02-section-1-archiving-vs-compression.md) | [↑ Index](index.md) | [Next →](04-section-3-compression-tools-compared.md)
