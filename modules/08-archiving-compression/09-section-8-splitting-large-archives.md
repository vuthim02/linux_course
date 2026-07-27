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



---

[← Previous](08-section-7-real-backup-patterns.md) | [↑ Index](index.md) | [Next →](10-practice-section-15-hands-on-exercises.md)
