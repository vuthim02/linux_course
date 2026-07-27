## 🔍 Section 7: at — One-Time Scheduling

`at` runs a command once at a specified time.

### Basic Usage

```bash
# Run a command at a specific time
echo "shutdown -h now" | at 23:00

# Run a script at a specific time
at 02:00 -f /usr/local/bin/backup.sh

# Interactive mode
at 15:30
warning: commands will be executed using /bin/sh
at> /usr/local/bin/backup.sh
at> echo "Backup complete"
at> <Ctrl+D>
```

### Time Specification

```bash
at 10:00                 # Today at 10:00 AM
at 10:00 tomorrow        # Tomorrow at 10:00 AM
at 10:00 + 5 days        # 5 days from now at 10:00 AM
at 10:00 next week       # Next week at 10:00 AM
at now + 30 minutes      # 30 minutes from now
at now + 2 hours         # 2 hours from now
at 14:00 July 15 2024    # Specific date and time
at teatime               # 4:00 PM (traditional)
at midnight              # 12:00 AM
at noon                  # 12:00 PM
```

### Managing at Jobs

```bash
# List pending at jobs
atq

# Show details of a job
at -c job_id

# Remove a job
atrm job_id

# Examples
echo "apt update && apt upgrade -y" | at 03:00 tomorrow
atq
# Output: 3      Wed Jan 16 03:00:00 2024 a root
atrm 3
```

### at vs cron

| Feature | at | cron |
|---------|----|------|
| Runs | Once | Recurring |
| Scheduling | Time in words (tomorrow, +2h) | crontab syntax |
| Use case | One-off maintenance | Regular backups, cleanup, rotation |
| Output | Mailed to user | Mailed to user |
| Listing | `atq` | `crontab -l` |
| Removal | `atrm JOBID` | `crontab -e` (manual) |

### batch — Run When Load Is Low

```bash
# batch is like at, but runs when system load is low (< 1.5 on average)
echo "/usr/local/bin/cpu-heavy-task.sh" | batch

# Same time syntax as at
batch now
at> /usr/local/bin/cpu-heavy-task.sh
at> <Ctrl+D>
```

---



---

[← Previous](09-section-6-security-cronallow-and.md) | [↑ Index](index.md) | [Next →](11-section-8-systemd-timers-review.md)
