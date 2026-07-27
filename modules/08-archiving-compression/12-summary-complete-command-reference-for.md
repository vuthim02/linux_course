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



---

[← Previous](11-deep-understanding-how-compression-works.md) | [↑ Index](index.md) | [Next →](13-whats-coming-in-part-9.md)
