## 🔍 Section 12: file, stat, and Advanced File Metadata

### file — Determine File Type

```bash
# Identify any file's type by content (not extension)
file /etc/hosts               # ASCII text
file /bin/ls                  # ELF 64-bit LSB executable
file /dev/sda                 # block special
file unknown_file             # detects based on magic bytes
```

### stat — Detailed File Metadata

```bash
# Show ALL metadata for a file
stat /etc/hosts

# Custom format
stat -c '%a %s %n' /etc/hosts    # permissions (octal), size, name

# Filesystem info
stat -f /
```

### du — Disk Usage Deep Dive

```bash
du -sh /home/*                 # Total size per user
du -h --max-depth=1 /var       # One level deep
du -a /tmp | sort -rn | head   # Largest files in /tmp
```

### watch — Repeat Commands Periodically

```bash
watch -n 1 'df -h /'           # Watch disk usage every second
watch -d 'ls -la /tmp'         # Highlight differences between runs
watch -n 5 'ss -tlnp'          # Watch listening ports
watch -n 60 'systemctl list-units --failed'
```



[← Previous](19-self-test-can-you-answer-these.md) | [↑ Index](index.md) | [Next →](21-section-13-keyboard-shortcuts-and-rename.md)
