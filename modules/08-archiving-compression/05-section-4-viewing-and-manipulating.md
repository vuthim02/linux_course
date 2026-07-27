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



---

[← Previous](04-section-3-compression-tools-compared.md) | [↑ Index](index.md) | [Next →](06-section-5-zip-cross-platform-archiving.md)
