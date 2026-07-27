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



---

[← Previous](05-section-4-viewing-and-manipulating.md) | [↑ Index](index.md) | [Next →](07-section-6-other-archiving-tools.md)
