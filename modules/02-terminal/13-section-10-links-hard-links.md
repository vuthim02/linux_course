## 🔍 Section 10: Links — Hard Links and Symbolic Links

Linux has two types of "shortcuts" to files.

### Symbolic Link (Symlink) — Like a Windows Shortcut

```bash
ln -s /path/to/original /path/to/link
```

```bash
# Create a symlink
ln -s /var/www/html /home/john/website

# Now /home/john/website points to /var/www/html
ls -la /home/john/website      # Shows: website -> /var/www/html
```

Symlinks show with `l` type and `->` in `ls -la`:
```
lrwxrwxrwx 1 john john 13 Jan 15 10:30 website -> /var/www/html
```

If the original is deleted, the symlink **breaks** (it becomes a "dangling link").

### Hard Link — Two Names for the Same Data

```bash
ln /path/to/original /path/to/hardlink
```

```bash
ln /etc/hosts /tmp/hosts_backup
```

Hard links:
- Both names point to the **exact same data on disk**
- If you delete one, the other still works perfectly
- Both files stay in sync — editing one edits both
- Cannot cross filesystem boundaries
- Cannot link directories

> 🔍 **Reverse Engineering Insight:** When you "delete" a file with `rm`, Linux doesn't actually erase the data. It removes the **name** (the link). The data is only truly deleted when there are zero names pointing to it. This is why the link count in `ls -l` matters — it shows how many names point to this data.





[← Previous](12-section-9-finding-files-find.md) | [↑ Index](index.md) | [Next →](14-practice-section-15-hands-on-exercises.md)
