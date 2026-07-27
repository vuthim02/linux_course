## 🔍 Section 2: tar — Advanced

### Exclude Patterns

```bash
tar czf backup.tar.gz \
    --exclude='*.log' \
    --exclude='*.tmp' \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='cache' \
    /home/user/
# Exclude from file
tar czf backup.tar.gz -X exclude-list.txt /home/user/
```

### Incremental with --listed-incremental

```bash
# Level 0 (full) — Monday
tar czf monday-full.tar.gz \
    --listed-incremental=/var/log/backup.snar \
    /home/user/data/

# Level 1 (incremental) — Tuesday
tar czf tuesday-inc1.tar.gz \
    --listed-incremental=/var/log/backup.snar \
    /home/user/data/

# Restore: both archives in sequence
tar xzf monday-full.tar.gz -C /restore/
tar xzf tuesday-inc1.tar.gz -C /restore/
```

The `.snar` file tracks metadata (mtime, inode) to determine what changed.

### Archive Across SSH

```bash
# Push (local → remote)
tar czf - /home/user/data/ | ssh user@backup-server "cat > /backups/data-$(date +%F).tar.gz"

# Pull (remote → local)
ssh user@server "tar czf - /home/user/data/" > backup.tar.gz
```

---



---

[← Previous](07-level-2-intermediary-incremental-backups.md) | [↑ Index](index.md) | [Next →](09-section-3-rsync-advanced.md)
