## 🔍 Section 5: locate — Instant Filename Search

`locate` searches a pre-built database of filenames. It is **instant** but does not search file contents.

```bash
# Find any file named "hosts"
locate hosts

# Case-insensitive
locate -i "Hosts"

# Count matches
locate -c "*.conf"

# Show only existing files (database may be outdated)
locate -e "hosts"

# Limit results
locate "*.conf" | head -20
```

### Updating the locate Database

```bash
# The database is updated daily by cron
# But you can force an update:
sudo updatedb

# Check when the database was last updated
ls -l /var/lib/mlocate/mlocate.db
```

### locate vs find

| Aspect | find | locate |
|--------|------|--------|
| Speed | Slow (scans disk live) | Instant (database lookup) |
| Accuracy | Always current | May be outdated |
| Content search | No (only filenames) | No (only filenames) |
| Search criteria | Name, size, time, type, perms | Name only |
| Disk I/O | Heavy | None |

> 💡 Use `locate` for quick "where is that file?" questions. Use `find` when you need current data, complex criteria, or actions.





[← Previous](05-section-4-find-advanced-file.md) | [↑ Index](index.md) | [Next →](07-section-6-modern-alternatives-rg.md)
