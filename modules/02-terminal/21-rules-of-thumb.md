## 📏 Rules of Thumb

### Navigation Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use absolute paths in scripts** | Scripts run from anywhere | Avoids "file not found" errors |
| **Use relative paths when exploring** | Less typing | Faster navigation |
| **Tab twice before typing** | Check for unique completion | Saves time, catches typos |
| **ls before rm** | Always verify before deleting | Prevents accidents |
| **pwd when unsure** | Know where you are | Prevents wrong-directory operations |

### The ls Command Rules

| Situation | Command | Why |
|-----------|---------|-----|
| Find recent files | `ls -lhtr` | Newest at bottom |
| Find large files | `ls -lhS` | Largest at top |
| See hidden files | `ls -la` | Includes dotfiles |
| See directory only | `ls -ld dir` | Don't list contents |
| Recursive listing | `ls -R` | All subdirectories |

### The "Can't Find It" Checklist

```bash
# 1. Check if file exists:
ls -la /path/to/file

# 2. Check if it's a link:
ls -la /path/to/file | grep "\->"

# 3. Check file type:
file /path/to/file

# 4. Search for it:
find / -name "filename" 2>/dev/null

# 5. Check if you're looking in the right place:
pwd
ls -la
```

### The "Permission Denied" Checklist

```bash
# 1. Check permissions:
ls -la /path/to/file

# 2. Check ownership:
ls -la /path/to/file

# 3. Check if you're in the right group:
groups

# 4. Try with sudo (if appropriate):
sudo ls -la /path/to/file

# 5. Check SELinux:
ls -Z /path/to/file
```

---

**Why these rules matter:** Following these rules prevents 90% of common terminal mistakes. They're the "seatbelts" of Linux navigation.

[← Previous](19-self-test-can-you-answer-these.md) | [↑ Index](index.md)
