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



---

[← Previous](06-section-5-zip-cross-platform-archiving.md) | [↑ Index](index.md) | [Next →](08-section-7-real-backup-patterns.md)
