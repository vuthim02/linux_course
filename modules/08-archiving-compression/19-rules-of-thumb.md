## 📏 Rules of Thumb

### The Compression Selection Rules

| Priority | Use | Why |
|----------|-----|-----|
| Speed | `gzip` | Fastest compression/decompression |
| Ratio | `xz` | Best compression ratio |
| Compatibility | `gzip` | Available everywhere |
| Parallel | `pigz` | Multi-core compression |
| Streaming | `gzip` | Can pipe through |

### The tar Safety Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Test before deleting** | `tar tzf archive.tar.gz` | Verify contents |
| **Use -v for visibility** | `tar czvf archive.tar.gz` | See what's being archived |
| **Preserve permissions** | `tar --preserve-permissions` | Maintain ownership |
| **Exclude junk** | `--exclude="*.log"` | Don't archive unnecessary files |
| **Use absolute paths** | `tar czf archive.tar.gz /path/` | Clear restore location |

### The "Archive Too Large" Checklist

```bash
# 1. Check what's being included:
tar tzf archive.tar.gz | head -20

# 2. Exclude unnecessary files:
tar czf archive.tar.gz --exclude="*.tmp" --exclude="*.log" dir/

# 3. Use better compression:
tar cJf archive.tar.xz dir/    # xz has better ratio

# 4. Split into pieces:
tar czf - dir/ | split -b 1G - archive.tar.gz.

# 5. Use pigz for parallel compression:
tar cf - dir/ | pigz -p 4 > archive.tar.gz
```

### The "Can't Extract" Checklist

```bash
# 1. Check archive integrity:
tar tzf archive.tar.gz > /dev/null

# 2. Check disk space:
df -h

# 3. Check permissions:
ls -la archive.tar.gz

# 4. Try with -v to see errors:
tar xzvf archive.tar.gz

# 5. Check if archive is complete:
file archive.tar.gz
```

### The Backup Pattern

```bash
# Create timestamped backup:
tar czf "backup_$(date +%Y%m%d_%H%M%S).tar.gz" /important/dir

# Verify backup:
tar tzf "backup_$(date +%Y%m%d_%H%M%S).tar.gz" | wc -l

# Test restore (to temp dir):
mkdir /tmp/restore && tar xzf backup.tar.gz -C /tmp/restore
```

---

**Why these rules matter:** Following these rules prevents common archiving mistakes and ensures your backups are actually restorable.

[← Previous](14-self-test-can-you-answer-these.md) | [↑ Index](index.md)
