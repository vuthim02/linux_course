## 📏 Rules of Thumb

### The Search Tool Selection Rules

| Situation | Use | Why |
|-----------|-----|-----|
| Quick file search | `locate` | Instant results |
| Current data needed | `find` | Always accurate |
| Content search | `grep` | Text patterns |
| Complex criteria | `find` | Multiple conditions |
| Actions on results | `find -exec` or `xargs` | Process matches |

### The grep Safety Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Always quote patterns** | `grep "pattern"` | Prevents shell expansion |
| **Use -r for recursive** | `grep -r` | Searches all files |
| **Use -i for case-insensitive** | `grep -i` | Catches variations |
| **Use -v to exclude** | `grep -v` | Filters out noise |
| **Use -c to count** | `grep -c` | When you need numbers |

### The find Safety Rules

```bash
# 1. Always preview before acting:
find . -name "*.log" | head -20    # Check results first

# 2. Use -print0 for filenames with spaces:
find . -name "*.log" -print0 | xargs -0 rm

# 3. Use -ok instead of -exec for dangerous actions:
find . -name "*.tmp" -ok rm {} \;    # Prompts for each

# 4. Test with echo first:
find . -name "*.log" -exec echo {} \;    # Show what would be deleted

# 5. Use -maxdepth to limit scope:
find . -maxdepth 2 -name "*.log"    # Only search 2 levels deep
```

### The "I Can't Find It" Checklist

```bash
# 1. Try locate first (fast):
locate filename

# 2. If not found, update database:
sudo updatedb && locate filename

# 3. If still not found, use find (current):
find / -name "filename" 2>/dev/null

# 4. Search by content:
grep -r "pattern" /path/to/search

# 5. Search by type:
find / -type f -name "*.conf"

# 6. Search by size:
find / -size +100M -name "*.log"
```

### The "Too Many Results" Checklist

```bash
# 1. Limit depth:
find . -maxdepth 3 -name "*.log"

# 2. Filter by type:
find . -type f -name "*.log"

# 3. Filter by time:
find . -mtime -7 -name "*.log"

# 4. Filter by size:
find . -size +1M -name "*.log"

# 5. Use grep to filter:
find . -name "*.log" | grep "error"
```

---

**Why these rules matter:** These rules prevent common search mistakes and help you find files faster. The safety patterns alone prevent accidental data loss.

[← Previous](13-self-test-can-you-answer-these.md) | [↑ Index](index.md)
