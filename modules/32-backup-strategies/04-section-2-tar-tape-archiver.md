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



---

[← Previous](03-section-1-backup-philosophy.md) | [↑ Index](index.md) | [Next →](05-section-3-rsync-remote-sync.md)
