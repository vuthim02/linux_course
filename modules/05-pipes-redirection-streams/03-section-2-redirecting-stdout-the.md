## 🔍 Section 2: Redirecting stdout — The `>` Operator

Send stdout to a file instead of the screen:

```bash
# Save directory listing to a file
ls -la /etc > etc_listing.txt

# Create a file with content
echo "Hello, Linux" > greeting.txt

# Overwrite vs Append:
>   # Overwrite — destroys existing content
>>  # Append — adds to existing content
```

### The Danger of `>`

```bash
# THIS WILL DESTROY YOUR FILE:
echo "new content" > important_config.txt

# Always think: "Am I sure I want to overwrite?"
# Use >> if you want to add, not replace.

# Safety tip:
set -o noclobber   # Prevents accidental overwrite with >
# Now: > will fail if file exists
# Use >| to force override
```

### Real Examples

```bash
# Save running processes to a file
ps aux > running_processes.txt

# Save disk usage report
df -h > disk_report.txt

# Save kernel messages
dmesg > boot_messages.txt

# Append new log entry to an existing file
echo "$(date): System rebooted" >> /var/log/reboot_history.log
```





[← Previous](02-section-1-the-three-streams.md) | [↑ Index](index.md) | [Next →](04-section-3-redirecting-stdin-the.md)
