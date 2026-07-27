## 🔍 Section 9: Finding Files — `find` Command

The `find` command searches for files. It is extremely powerful.

### Basic Syntax

```bash
find [where to search] [what to look for] [what to do with results]
```

### Find by Name

```bash
find /etc -name "hosts"              # Find file named "hosts" in /etc
find /home -name "*.txt"            # Find all .txt files in /home
find / -name "passwd"               # Find "passwd" anywhere on system
find . -name "config*"              # Find files starting with "config" here
find /etc -iname "*.conf"           # Case-insensitive search
```

### Find by Type

```bash
find /etc -type f                    # Only files (not directories)
find /etc -type d                    # Only directories
find /dev -type b                    # Block devices (hard drives)
find /dev -type c                    # Character devices (terminals)
find /tmp -type l                    # Symbolic links only
```

### Find by Size

```bash
find / -size +100M                   # Files larger than 100 megabytes
find / -size +1G                     # Files larger than 1 gigabyte
find /var/log -size +50M             # Large log files
find /tmp -size -1k                  # Files smaller than 1 kilobyte
```

### Find by Time

```bash
find /etc -mtime -7                  # Modified within last 7 days
find /tmp -mtime +30                 # Modified more than 30 days ago
find /home -atime -1                 # Accessed within last 24 hours
find / -newer /etc/passwd            # Files newer than /etc/passwd
```

### Find and Do Something (Very Powerful)

```bash
# Find and delete all .tmp files
find /tmp -name "*.tmp" -delete

# Find and delete files older than 30 days
find /tmp -mtime +30 -type f -delete

# Find and print details (like ls -l for each result)
find /etc -name "*.conf" -ls

# Find and run a command on each result
find /var/log -name "*.log" -exec wc -l {} \;
# {} = the found file, \; = end of command
```

> 💡 **`find -exec` explained:** The `{}` is a placeholder for each file found. The `\;` ends the exec command. So `find /etc -name "*.conf" -exec cat {} \;` would print every config file.

---



---

[← Previous](11-section-8-wildcards-work-on.md) | [↑ Index](index.md) | [Next →](13-section-10-links-hard-links.md)
