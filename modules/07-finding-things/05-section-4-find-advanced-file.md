## 🔍 Section 4: find — Advanced File Searching

`find` searches for files by **any attribute** — name, type, size, time, owner, permissions. It is more powerful than any GUI search tool.

### Basic Syntax

```bash
find [where_to_start] [conditions] [what_to_do]
```

### Find by Name

```bash
# Find by exact name
find /etc -name "hosts"

# Wildcard — all .conf files
find /etc -name "*.conf"

# Case-insensitive
find /etc -iname "*.CONF"

# Match multiple patterns
find /etc -name "*.conf" -o -name "*.cfg"
```

### Find by Type

```bash
find / -type f        # Regular files only
find / -type d        # Directories only
find / -type l        # Symbolic links
find / -type s        # Sockets
find / -type b        # Block devices (disks)
find / -type c        # Character devices (terminals)
find / -type p        # Named pipes (FIFOs)
```

### Find by Size

```bash
find / -size +100M    # Larger than 100 MB
find / -size -1k      # Smaller than 1 KB
find / -size 1024k    # Exactly 1024 KB (1 MB)
find / -size +500M -size -1G   # Between 500 MB and 1 GB
find / -empty         # Empty files and directories
```

### Find by Time

```bash
# Modification time
find /etc -mtime -7   # Modified in last 7 days
find /etc -mtime +30  # Modified more than 30 days ago
find /etc -mmin -60   # Modified in last 60 minutes

# Access time (last read)
find /home -atime -1   # Accessed in last 24 hours

# Change time (permission/ownership changed)
find /etc -ctime -1    # Changed in last 24 hours

# Newer than another file
find . -newer /etc/hosts   # Files newer than /etc/hosts
```

### Find by Owner and Permissions

```bash
# By user
find /home -user alice

# By group
find / -group developers

# By permission
find / -perm 644               # Exact permissions
find / -perm -4000             # SUID set (any of these bits)
find / -perm /4000             # ANY of these bits set
find / ! -perm 755             # NOT 755

# World-writable files (security risk)
find / -type f -perm -o+w

# No permissions for anyone
find / -perm 000
```

### Actions — What to Do With Results

```bash
# Default: print (same as -print)
find . -name "*.txt"

# Print with details (like ls -l)
find . -name "*.txt" -ls

# Delete
find /tmp -mtime +7 -delete

# Run a command on each result
find /var/log -name "*.log" -exec gzip {} \;
# {} = placeholder for each file
# \; = end of exec command

# Run a command with + (batch, more efficient)
find /var/log -name "*.log" -exec chmod 640 {} +
# + = put all files at the end of one command

# Run with custom command
find . -name "*.jpg" -exec convert {} -resize 800x600 {} \;
```

### find vs ls — Why find Is Necessary

```bash
# What if you want files modified in the last 7 days?
# ls cannot do this with a single command.
# ls -lt shows sorted by time, but not time range.

# find does it easily:
find /etc -mtime -7

# What if you want files larger than 100MB?
# ls -laS shows sorted by size, but not size threshold.

# find:
find / -size +100M
```

### Combining find With Other Commands

```bash
# Find and count
find /etc -type f | wc -l

# Find and copy
find /var/log -name "*.log" -mtime -1 -exec cp {} /backup/ \;

# Find and tar
find /home -name "*.doc" -type f | tar -czf docs_backup.tar.gz -T -

# Find and show disk usage
find /var/log -name "*.log" -size +10M -exec du -h {} \;
```

### Safety With find -exec

```bash
# DANGEROUS — always test first!
find / -name "important*" -delete
# ^ This could delete everything named "important*"

# SAFE approach:
find / -name "important*"          # Step 1: Preview results
find / -name "important*" -ls      # Step 2: See details
find / -name "important*" -delete  # Step 3: Only if step 1-2 look right
```

### find and xargs

`xargs` reads items from stdin and executes a command with them. It is more efficient than `-exec` for large result sets.

```bash
# Find and delete (xargs is faster than -exec for many files)
find /tmp -mtime +30 -type f -print | xargs rm

# Find and chmod
find . -type f -name "*.sh" -print | xargs chmod +x

# Find and grep contents
find /etc -name "*.conf" -print | xargs grep "Port" 2>/dev/null

# With null separator (handles spaces in filenames)
find . -name "*.txt" -print0 | xargs -0 rm
```





[← Previous](04-section-3-grep-in-practice.md) | [↑ Index](index.md) | [Next →](06-section-5-locate-instant-filename.md)
