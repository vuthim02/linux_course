# 🐧 Linux System Administrator — Complete Course
## Part 13 of ∞: Scheduling Tasks — cron, at, systemd timers

---

> **Reverse Engineering Approach:** In production, you never sit at a terminal running commands manually at 3 AM. You schedule them. The heart of Linux automation is three tools: cron for recurring tasks, at for one-shot jobs, and systemd timers for the modern approach. Understanding scheduling is what separates an admin who reacts from an admin who plans.

---

## 🎯 What You Will Achieve in Part 13

| Level | Focus | What You'll Master |
|-------|-------|-------------------|
| ⭐ **Level 1: Basic** | Cron fundamentals | cron daemon, crontab syntax, system vs user crontabs, cron directories |
| ⭐ **Level 2: Intermediary** | Scheduling workflows | crontab environment, logging, debugging, at/batch, systemd timers |
| ⭐ **Level 3: Advanced** | Real-world patterns and internals | Sysadmin scheduling patterns, cron internals, timer states, auditing |

---

## ⭐ Level 1: Basic — Cron Fundamentals

![Cron Backup Scheduling Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/d/db/Backup-CRON-incremental-Y-diferencial.svg/626px-Backup-CRON-incremental-Y-diferencial.svg.png)
*Schematic of cron-based backup scheduling with incremental, differential, and full strategies. Source: Wikimedia Commons*

> **Level 1 Goal:** Understand how the cron daemon works, master the 5-field crontab syntax, and know where different types of crontabs live on the system.

---

## 🔍 Section 1: cron — The Classic Scheduler

cron is a daemon (`crond`) that reads configuration files called "crontabs" and executes commands at specified times.

### How cron Works

```
cron daemon (crond)        ← starts at boot, runs forever
    ↓
Reads crontab files        ← /etc/crontab, /var/spool/cron/crontabs/*
    ↓
Checks every minute        ← looks at current time
    ↓
Matches against schedule   ← compares with each crontab line
    ↓
Executes command           ← runs as the crontab owner
    ↓
Sleeps 60 seconds          ← checks again
```

### The crontab Command

```bash
# Edit your crontab (opens in default editor)
crontab -e

# List your crontab entries
crontab -l

# List another user's crontab (root only)
sudo crontab -l -u www-data

# Remove your crontab
crontab -r

# Edit another user's crontab
sudo crontab -e -u www-data
```

### Crontab Syntax (The Five Stars)

```
* * * * * command_to_execute
│ │ │ │ │
│ │ │ │ └── Day of week (0-7)  [0=Sunday, 7=Sunday]
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)
```

### Common Schedule Examples

```bash
# Every minute
* * * * * command

# Every hour at minute 0
0 * * * * command

# Every day at midnight
0 0 * * * command

# Every day at 2:30 AM
30 2 * * * command

# Every Monday at 8 AM
0 8 * * 1 command

# First day of every month at midnight
0 0 1 * * command

# Every 15 minutes
*/15 * * * * command

# Every 6 hours (at minute 0)
0 */6 * * * command

# Every weekday (Mon-Fri) at 9:30 AM
30 9 * * 1-5 command

# Multiple times: 8 AM, 12 PM, and 4 PM every day
0 8,12,16 * * * command

# First and fifteenth of each month
0 0 1,15 * * command
```

### Special @-Times

```bash
# These are aliases for common schedules:
@reboot        On system boot (once)
@yearly        0 0 1 1 *     (once a year)
@annually      0 0 1 1 *     (once a year)
@monthly       0 0 1 * *     (once a month)
@weekly        0 0 * * 0     (once a week)
@daily         0 0 * * *     (once a day)
@hourly        0 * * * *     (once an hour)

# Examples
@daily    /usr/local/bin/rotate-logs.sh
@reboot   /usr/local/bin/check-disks.sh
```

---

## 🔍 Section 2: Where Crontabs Live

### System Crontab vs User Crontabs

There are two types:

1. **System crontab** (`/etc/crontab`) — has an extra field for user
2. **User crontabs** (`/var/spool/cron/crontabs/username`) — run as that user

### System Crontab Example

```bash
cat /etc/crontab
```

```
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Example of job definition:
# .---------------- minute (0-59)
# |  .------------- hour (0-23)
# |  |  .---------- day of month (1-31)
# |  |  |  .------- month (1-12)
# |  |  |  |  .---- day of week (0-6)
# |  |  |  |  |
# *  *  *  *  * user command
```

Notice: System crontab has a **user** column (6th field). User crontabs do NOT have this.

### The cron.d Directory

```bash
# Packages install their cron jobs here
ls /etc/cron.d/

# Example: /etc/cron.d/php
cat /etc/cron.d/php
```

```
# /etc/cron.d/php
* * * * * root /usr/lib/php/sessionclean
```

### The cron.hourly/daily/weekly/monthly Directories

```bash
# Scripts placed here run automatically
ls /etc/cron.hourly/
ls /etc/cron.daily/
ls /etc/cron.weekly/
ls /etc/cron.monthly/

# Example: add a backup script
sudo cp /usr/local/bin/daily-backup.sh /etc/cron.daily/
sudo chmod +x /etc/cron.daily/daily-backup.sh
```

These are managed by `run-parts` — a utility that runs all scripts in a directory.

---

## ⭐ Level 2: Intermediary — Scheduling Workflows

![Crontab Format and Syntax Diagram](https://upload.wikimedia.org/wikipedia/commons/3/3c/Crontab.png)
*Crontab format showing the five standard time fields. Source: Wikimedia Commons*

> **Level 2 Goal:** Configure cron environment variables, redirect cron output, debug common mistakes, use `at`/`batch` for one-time jobs, and create systemd timers for modern scheduling.

---

## 🔍 Section 3: crontab Environment

cron runs commands in a minimal environment. This is a COMMON source of bugs.

### The Problem

```bash
# When you type this in terminal, it works:
mysqldump -u root mydb > /tmp/backup.sql

# When cron runs it, it FAILS because:
# 1. PATH is different (might not include /usr/bin)
# 2. HOME is different
# 3. No terminal (TTY) available
# 4. Environment variables are not set
```

### The Solution — Set Environment in Crontab

```bash
# Set variables at the TOP of your crontab
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOME=/home/username
MAILTO=admin@example.com

# Now commands will work
0 2 * * * mysqldump -u root mydb > /tmp/backup.sql
```

### Cron Environment Variables

| Variable | Purpose |
|----------|---------|
| SHELL | Shell to use for commands (default: /bin/sh) |
| PATH | Where to find executables (default: /usr/bin:/bin) |
| HOME | Home directory (default: user's home) |
| MAILTO | Who gets cron output via email (default: user) |
| LOGNAME | Username |

### Always Use Full Paths

```bash
# Bad cron job (cron might not find 'tar'):
0 3 * * * tar -czf /backup/www.tar.gz /var/www

# Good cron job:
0 3 * * * /usr/bin/tar -czf /backup/www.tar.gz /var/www

# Even better — put PATH in crontab:
PATH=/usr/bin:/bin:/usr/local/bin
0 3 * * * tar -czf /backup/www.tar.gz /var/www
```

---

## 🔍 Section 4: Cron Output and Logging

### Where Cron Output Goes

```bash
# By default, cron MAILS output to the user
# If mail is not configured, it may be lost

# To redirect output (SUPPRESS mailing):
0 2 * * * /usr/local/bin/backup.sh > /dev/null 2>&1

# To LOG output to a file:
0 2 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1

# To log with timestamp:
0 2 * * * echo "[$(date)] Running backup" >> /var/log/backup.log; \
            /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
```

### Cron Logging

```bash
# cron logs to syslog, which goes to journald
journalctl -u cron -n 20

# Or check syslog directly
grep CRON /var/log/syslog | tail -20

# Sample log entry:
# Jan 15 02:00:01 server CRON[12345]: (root) CMD (/usr/local/bin/backup.sh)
```

### Checking If cron Ran

```bash
# 1. Check syslog
sudo grep "$(date +%b%e)" /var/log/syslog | grep CRON

# 2. Check journal
journalctl -u cron --since "1 hour ago"

# 3. Check your mail
mail
```

---

## 🔍 Section 5: Common Cron Mistakes and Debugging

### Mistake 1: Wrong PATH

```bash
# Symptom: "command not found" in cron output
# Fix: Set PATH at top of crontab
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### Mistake 2: Percent Signs Not Escaped

```bash
# % has special meaning in cron (newline)
# BAD: (the % breaks the command)
0 2 * * * date +%Y-%m-%d > /tmp/date.txt

# GOOD: (escape % with backslash)
0 2 * * * date +\%Y-\%m-\%d > /tmp/date.txt

# BETTER: (use script instead)
0 2 * * * /usr/local/bin/dated-backup.sh
```

### Mistake 3: Script Depends on Terminal

```bash
# BAD: (chron doesn't have a terminal)
0 2 * * * mysql -u root -p

# GOOD: (use non-interactive authentication)
0 2 * * * mysql -u root -pPassword < /tmp/query.sql
# Or use my.cnf with credentials
```

### Mistake 4: Not Using Full Paths

```bash
# BAD:
0 2 * * * mycommand

# GOOD:
0 2 * * * /usr/local/bin/mycommand
```

### Mistake 5: Forgetting the Newline

```bash
# Every crontab MUST end with a blank line!
# Without it, the last entry won't work
```

### Debugging Steps

```bash
# 1. Verify cron is running
systemctl status cron

# 2. Check crontab syntax
crontab -l

# 3. Test the command manually (as the same user)
sudo -u username /usr/local/bin/command

# 4. Add logging to the command
* * * * * /usr/local/bin/command >> /tmp/cron-debug.log 2>&1

# 5. Watch the log in real-time
tail -f /var/log/syslog | grep CRON
```

---

## 🔍 Section 6: Security — cron.allow and cron.deny

```bash
# Who can use cron?
# Controlled by two files:
/etc/cron.allow     # If exists, ONLY listed users can use cron
/etc/cron.deny      # If exists, listed users CANNOT use cron

# If neither exists, only root can use cron (on some systems)
# or all users can (on others)

# Best practice: create cron.allow with specific users
echo "root" > /etc/cron.allow
echo "www-data" >> /etc/cron.allow
echo "backup" >> /etc/cron.allow
```

---

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

## 🔍 Section 8: Systemd Timers (Review from Part 12)

systemd timers are the modern replacement for cron. They offer more features.

### Recap — Basic Timer Structure

```ini
# /etc/systemd/system/weekly-cleanup.timer
[Unit]
Description=Weekly cleanup timer

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/weekly-cleanup.service
[Unit]
Description=Weekly cleanup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cleanup.sh
```

### Systemd Timer Schedule Syntax (More Detail)

```bash
# Format: DayOfWeek Year-Month-Day Hour:Minute:Second
# * means "every"

OnCalendar=*-*-* *:*:*              # Every minute (like */1 * * *)
OnCalendar=*-*-* *:00:00            # Every hour
OnCalendar=*-*-* 00:00:00           # Daily at midnight
OnCalendar=Mon *-*-* 00:00:00       # Every Monday
OnCalendar=*-*-01 00:00:00          # First of every month
OnCalendar=*-*-01/7 00:00:00        # Every 7 days starting day 1
OnCalendar=*-01-01 00:00:00         # January 1 every year
OnCalendar=Sat,Tue *-*-* 03:00:00   # Every Saturday and Tuesday at 3 AM

# Multiple schedules
OnCalendar=Mon..Fri 09:00:00
OnCalendar=Mon..Fri 17:00:00
```

### Monotonic Timers (Relative to Events)

```ini
[Timer]
OnBootSec=5min              # 5 minutes after boot
OnUnitActiveSec=1h          # 1 hour after the service last ran
OnUnitInactiveSec=30m       # 30 minutes after the service stops
OnStartupSec=10min          # 10 minutes after systemd starts
```

### Timer Features cron Doesn't Have

```bash
# 1. Persistent=true — catch up after downtime
# If the system was off at 2 AM, run immediately on boot
[Timer]
OnCalendar=daily
Persistent=true

# 2. RandomizedDelay — avoid thundering herd
[Timer]
OnCalendar=daily
RandomizedDelaySec=1h    # Run at a random time between midnight and 1 AM

# 3. AccuracySec — power saving
[Timer]
OnCalendar=hourly
AccuracySec=1h           # Allow up to 1 hour of delay (saves wake-ups)

# 4. FixedRandomDelay — same random offset each time
[Timer]
OnCalendar=daily
FixedRandomDelay=true
RandomizedDelaySec=30m   # Always +15 minutes (5000/10000 * 30m for example)
```

### When to Use Systemd Timers vs Cron

**Use systemd timers when:**
- You need persistent (catch-up) behavior
- You want randomized delays
- You need dependency management (run after network.target)
- You want unified logging via journald
- The task is closely related to a systemd service

**Use cron when:**
- You need simple, portable scheduling
- Multiple admins need to view/edit easily
- You're on a non-systemd system (rare these days)
- You need user crontabs (non-root scheduled tasks)
- You want the `@reboot` syntax (which systemd handles differently)

---

## ⭐ Level 3: Advanced — Real-World Patterns and Internals

![Crontab Format Illustration](https://upload.wikimedia.org/wikipedia/commons/3/3c/Crontab.png)
*Standard crontab format with the five timing fields and command. Source: Wikimedia Commons*

> **Level 3 Goal:** Implement real-world scheduling patterns (log rotation, backups, health checks), understand cron daemon internals, and master systemd timer states and auditing.

---

## 🔍 Section 9: Real Sysadmin Scheduling Patterns

### Pattern 1: Log Rotation

```bash
# /etc/cron.daily/logrotate
# Most distros handle this automatically
# But you can add custom rotation rules in /etc/logrotate.d/

# Test logrotate manually:
sudo logrotate -d /etc/logrotate.conf    # Dry run
sudo logrotate -f /etc/logrotate.conf    # Force run
```

### Pattern 2: Database Backup

```bash
# cron: daily backup at 2 AM
0 2 * * * /usr/local/bin/mysql-backup.sh

# mysql-backup.sh:
#!/bin/bash
BACKUP_DIR=/var/backups/mysql
TIMESTAMP=$(date +\%Y-\%m-\%d_\%H:\%M:\%S)
mkdir -p $BACKUP_DIR
mysqldump --all-databases | gzip > $BACKUP_DIR/all-dbs_$TIMESTAMP.sql.gz
find $BACKUP_DIR -type f -mtime +30 -delete  # Keep 30 days
```

### Pattern 3: System Cleanup

```bash
# cron: clean temp files every Sunday at 3 AM
0 3 * * 0 /usr/local/bin/cleanup.sh

# cleanup.sh:
#!/bin/bash
find /tmp -type f -atime +7 -delete
find /var/tmp -type f -atime +7 -delete
apt autoremove -y 2>/dev/null || dnf autoremove -y 2>/dev/null
```

### Pattern 4: Health Check

```bash
# cron: monitor disk space every hour
0 * * * * /usr/local/bin/disk-check.sh

# disk-check.sh:
#!/bin/bash
THRESHOLD=90
df -h | awk -v threshold=$THRESHOLD 'NR>1 {gsub(/%/,"",$5); if($5>threshold) print "WARNING: "$6" is "$5"% full"}' \
    | mail -s "Disk Space Alert on $(hostname)" admin@example.com
```

### Pattern 5: Certificate Renewal

```bash
# Let's Encrypt certs renew automatically via cron/systemd timer
# Certbot usually installs this automatically:
ls /etc/cron.d/certbot
# or
systemctl list-timers | grep certbot
```

---

## 🧠 Deep Understanding — How Scheduling Really Works

### The cron Daemon Internals

```
1. crond starts at boot (from systemd or init)
2. Reads all crontab files into memory
3. Sleeps 60 seconds
4. Wakes up, checks if current time matches any entry
5. If match: forks a child process, executes command
6. Child's stdout/stderr is captured
7. If output exists: pipes to /usr/sbin/sendmail
8. Parent (crond) goes back to sleep
```

### Why cron Uses a Blank Line Requirement

The crontab parser reads line by line. When it encounters EOF without a newline on the last line, the last line may be ignored. The blank line ensures proper termination.

### The Timing Precision

cron has **minute-level** precision. If you need second-level precision:
- Use a script with a `sleep` loop
- Or use systemd timers with `OnCalendar=` specifying seconds:
  ```
  OnCalendar=*:*:00   # every minute at second 0
  OnCalendar=*:*:30   # every minute at second 30
  ```

### How `at` Stores Jobs

```bash
# at jobs are stored as files
ls /var/spool/at/  # or /var/spool/cron/atjobs/
# Each job is a file containing:
# - Environment variables
# - The command to run
# - Execution time (encoded in filename)

# The at daemon (atd) checks these files every 60 seconds
```

### Systemd Timer States

```
timer unit (loaded but inactive)
    ↓ enable
timer unit (wanted by timers.target)
    ↓ start
timer unit (active, waiting)
    ↓ OnCalendar matches
service unit (triggered, runs)
    ↓ service completes
timer unit (active, waiting for next trigger)
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### ✅ Level 1: Basic Practices

---

### ✅ Practice 1: Check If cron Is Running

```bash
mkdir -p ~/linux-course/part13
cd ~/linux-course/part13

# Check cron daemon status
systemctl status cron

# Check if crontab command is available
which crontab

# Check cron process
ps aux | grep -E "[c]ron|[c]rond"
```

---

### ✅ Practice 2: Create Your First Crontab

```bash
cd ~/linux-course/part13

# Create the crontab with a single entry
echo '* * * * * echo "cron ran at $(date)" >> /home/$(whoami)/linux-course/part13/cron-test.log' > mycron
echo '' >> mycron  # Must end with blank line!

# Install it
crontab mycron

# Verify
crontab -l

# Wait for it to run
echo "Waiting for cron to run..." 
sleep 90
cat cron-test.log 2>/dev/null || echo "No log yet — wait longer"

# Remove it
crontab -r
rm mycron
```

---

### ✅ Practice 3: List All Crontabs on the System

```bash
# As root, you can see everyone's crontabs
# List crontabs in the spool directory
sudo ls -la /var/spool/cron/crontabs/ 2>/dev/null || echo "No user crontabs directory"

# List system crontab
cat /etc/crontab 2>/dev/null | grep -v "^#" | grep -v "^$"

# List cron.d scripts
ls /etc/cron.d/ 2>/dev/null

# List cron.daily scripts
ls /etc/cron.daily/ 2>/dev/null
```

---

### ✅ Level 2: Intermediary Practices

---

### ✅ Practice 4: Schedule a Daily Backup (Simulated)

```bash
cd ~/linux-course/part13

# Create a backup script
cat > simulated-backup.sh << 'EOF'
#!/bin/bash
echo "[$(date)] Simulated backup started"
echo "Backing up /home to /tmp/backup..."
sleep 2
echo "[$(date)] Backup complete"
EOF
chmod +x simulated-backup.sh

# Create a crontab that runs it every day at 2 AM
echo "0 2 * * * $(pwd)/simulated-backup.sh >> $(pwd)/backup.log 2>&1" > backup-cron
crontab backup-cron
crontab -l

echo "Backup script scheduled. (Will run at 2 AM daily)"
echo "To test immediately, run: ./simulated-backup.sh"

# Clean up the crontab (don't leave test entries)
crontab -r
rm backup-cron
```

---

### ✅ Practice 5: Use @-Times

```bash
cd ~/linux-course/part13

# Create a script
cat > cleanup-sim.sh << 'EOF'
#!/bin/bash
echo "[$(date)] Cleaning temporary files..." >> /tmp/cleanup.log
EOF
chmod +x cleanup-sim.sh

# Create a crontab with @daily
echo "@daily $(pwd)/cleanup-sim.sh" > cleanup-cron
crontab cleanup-cron
crontab -l

# Clean up
crontab -r
rm cleanup-cron
```

---

### ✅ Practice 6: Debug Cron with Logging

```bash
cd ~/linux-course/part13

# Create a script that intentionally fails
cat > failing-script.sh << 'EOF'
#!/bin/bash
echo "This script will fail"
exit 1
EOF
chmod +x failing-script.sh

# Schedule it every minute and capture all output
echo "* * * * * $(pwd)/failing-script.sh >> $(pwd)/cron-output.log 2>&1" > debug-cron
crontab debug-cron

# Wait for a minute
sleep 70

# Check the log
cat cron-output.log 2>/dev/null || echo "No output"

# Check cron syslog
sudo grep "failing-script" /var/log/syslog 2>/dev/null | tail -3 || \
    journalctl -u cron -n 5 --no-pager | grep -i "fail"

# Clean up
crontab -r
rm debug-cron failing-script.sh
```

---

### ✅ Practice 7: Use the at Command

```bash
cd ~/linux-course/part13

# Schedule a command 1 minute from now
echo "echo 'at job ran at \$(date)' > $(pwd)/at-test.txt" | at now + 1 minute

# List the job
atq

# Wait for it to run
sleep 70
cat at-test.txt 2>/dev/null || echo "at job not yet run"

# More practical: schedule a script
cat > at-task.sh << 'EOF'
#!/bin/bash
echo "[$(date)] This is a one-time scheduled task" > $(pwd)/at-result.txt
EOF
chmod +x at-task.sh

at now + 2 minutes -f at-task.sh
atq

sleep 130
cat at-result.txt 2>/dev/null || echo "at job not yet run"

# Clean up
atrm $(atq | awk '{print $1}') 2>/dev/null || true
```

---

### ✅ Practice 8: Use batch Command

```bash
cd ~/linux-course/part13

# batch runs when system load is low
echo "echo 'Batch job ran at \$(date)' > $(pwd)/batch-test.txt" | batch

# Check it
atq
sleep 30
cat batch-test.txt 2>/dev/null || echo "Batch job waiting for low load"
```

---

### ✅ Practice 9: Create a Systemd Timer (One-Shot)

```bash
cd ~/linux-course/part13

# Create the service file
sudo tee /etc/systemd/system/oneshot-task.service << 'EOF'
[Unit]
Description=One-shot task

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Timer triggered at $(date)" | systemd-cat -t oneshot-demo'
EOF

# Create the timer
sudo tee /etc/systemd/system/oneshot-task.timer << 'EOF'
[Unit]
Description=Run one minute after boot

[Timer]
OnBootSec=1min

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now oneshot-task.timer
systemctl list-timers | grep oneshot

echo "Timer will trigger on next boot (or simulate with:)"
echo "sudo systemctl start oneshot-task.service"

# Clean up
sudo systemctl disable --now oneshot-task.timer 2>/dev/null || true
sudo rm /etc/systemd/system/oneshot-task.*
sudo systemctl daemon-reload
```

---

### ✅ Practice 10: Create a Calendar Timer

```bash
cd ~/linux-course/part13

# Timer that runs every 2 minutes
sudo tee /etc/systemd/system/interval-demo.service << 'EOF'
[Unit]
Description=Interval demo

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Interval timer ran at $(date)" | systemd-cat -t interval-demo'
EOF

sudo tee /etc/systemd/system/interval-demo.timer << 'EOF'
[Unit]
Description=Runs every 2 minutes

[Timer]
OnCalendar=*:0/2
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now interval-demo.timer

# Check it
systemctl list-timers | grep interval-demo
sleep 130

# Verify it ran
journalctl -t interval-demo -n 5 --no-pager

# Clean up
sudo systemctl disable --now interval-demo.timer
sudo rm /etc/systemd/system/interval-demo.*
sudo systemctl daemon-reload
```

---

### ✅ Practice 11: Compare Cron and Systemd Timer Logging

```bash
cd ~/linux-course/part13

# Cron entry
echo "* * * * * echo 'Cron ran at \$(date)' >> $(pwd)/cron-compare.log" > compare-cron
crontab compare-cron

# Systemd timer equivalent
sudo tee /etc/systemd/system/compare-demo.service << 'EOF'
[Unit]
Description=Compare demo

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Timer ran at $(date)" | systemd-cat -t compare-demo'
EOF

sudo tee /etc/systemd/system/compare-demo.timer << 'EOF'
[Unit]
Description=Every minute

[Timer]
OnCalendar=*:*:00

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now compare-demo.timer

# Wait for both to run
sleep 70

# Compare logging
echo "=== Cron log ==="
cat cron-compare.log 2>/dev/null || echo "No cron log yet"

echo ""
echo "=== systemd journal ==="
journalctl -t compare-demo -n 5 --no-pager

# Clean up
crontab -r
rm compare-cron
sudo systemctl disable --now compare-demo.timer
sudo rm /etc/systemd/system/compare-demo.*
sudo systemctl daemon-reload
```

---

### ✅ Practice 12: Schedule a Maintenance Window

```bash
cd ~/linux-course/part13

# Simulate scheduling maintenance for tonight at midnight
echo "echo 'Maintenance starting at \$(date)' > $(pwd)/maintenance.log" | at midnight

# Also schedule a reminder email (simulated)
echo "echo 'Reminder: maintenance scheduled for midnight' >> $(pwd)/reminder.log" | at 23:30

# Check both
atq
echo "Maintenance tasks scheduled. Check later with: atq"
```

---

### ✅ Practice 13: Explore cron.daily Structure

```bash
cd ~/linux-course/part13

# View all daily cron scripts
echo "=== Daily cron scripts ==="
ls -la /etc/cron.daily/

echo ""
echo "=== Contents of a typical daily script ==="
if [ -f /etc/cron.daily/logrotate ]; then
    head -20 /etc/cron.daily/logrotate
fi

echo ""
echo "=== How run-parts executes them ==="
# Check how run-parts works
which run-parts
man -P cat run-parts 2>/dev/null | head -30
```

---

### ✅ Practice 14: Permission Issues with cron

```bash
cd ~/linux-course/part13

# Check if cron.allow/cron.deny exist
ls -la /etc/cron.allow 2>/dev/null || echo "/etc/cron.allow does not exist"
ls -la /etc/cron.deny 2>/dev/null || echo "/etc/cron.deny does not exist"

# Check permissions on crontab
ls -la /usr/bin/crontab

# Try to add a crontab for another user (should fail)
crontab -u www-data -l 2>&1 || echo "Cannot access other user's crontab (expected)"
```

---

### ✅ Level 3: Advanced Practices

---

### ✅ Practice 15: Real SysAdmin Scenario — Scheduled Task Audit

```bash
cd ~/linux-course/part13

cat > scheduled_task_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="scheduled_tasks_report.txt"

echo "============================================" > "$REPORT"
echo "  SCHEDULED TASK AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: User crontabs
echo "1. USER CRONTABS" >> "$REPORT"
echo "----------------" >> "$REPORT"
for user in $(cut -d: -f1 /etc/passwd); do
    crontab -l -u "$user" 2>/dev/null | grep -v "^#" | grep -v "^$" | while read line; do
        echo "  [$user] $line" >> "$REPORT"
    done
done
echo "" >> "$REPORT"

# Section 2: System crontab
echo "2. SYSTEM CRONTAB (/etc/crontab)" >> "$REPORT"
echo "-------------------------------" >> "$REPORT"
grep -v "^#" /etc/crontab 2>/dev/null | grep -v "^$" | while read line; do
    echo "  $line" >> "$REPORT"
done
echo "" >> "$REPORT"

# Section 3: cron.d files
echo "3. CRON.D SCRIPTS" >> "$REPORT"
echo "----------------" >> "$REPORT"
for file in /etc/cron.d/*; do
    if [ -f "$file" ]; then
        echo "  File: $file" >> "$REPORT"
        grep -v "^#" "$file" | grep -v "^$" | while read line; do
            echo "    $line" >> "$REPORT"
        done
    fi
done
echo "" >> "$REPORT"

# Section 4: cron.daily/weekly/monthly
echo "4. CRON DIRECTORIES" >> "$REPORT"
echo "------------------" >> "$REPORT"
for dir in cron.hourly cron.daily cron.weekly cron.monthly; do
    count=$(ls /etc/$dir 2>/dev/null | wc -l)
    echo "  /etc/$dir: $count scripts" >> "$REPORT"
done
echo "" >> "$REPORT"

# Section 5: systemd timers
echo "5. SYSTEMD TIMERS" >> "$REPORT"
echo "----------------" >> "$REPORT"
systemctl list-timers --all --no-legend 2>/dev/null | awk '{print "  " $0}' >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: at jobs
echo "6. AT JOBS" >> "$REPORT"
echo "---------" >> "$REPORT"
atq 2>/dev/null | while read line; do
    echo "  $line" >> "$REPORT"
done
echo "" >> "$REPORT"

# Section 7: Summary
echo "7. SUMMARY" >> "$REPORT"
echo "---------" >> "$REPORT"
user_cron_count=$(for u in $(cut -d: -f1 /etc/passwd); do crontab -l -u "$u" 2>/dev/null | grep -v "^#" | grep -c -v "^$" || true; done | awk '{s+=$1} END {print s}')
echo "  User crontab entries: ${user_cron_count:-0}" >> "$REPORT"
timer_count=$(systemctl list-timers --all --no-legend 2>/dev/null | wc -l)
echo "  Systemd timers: $timer_count" >> "$REPORT"
at_count=$(atq 2>/dev/null | wc -l)
echo "  Pending at jobs: $at_count" >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x scheduled_task_audit.sh
./scheduled_task_audit.sh
```

---

## 📋 Summary — Complete Command Reference for Part 13

### Level 1: Basic Commands — cron

| Command | Action |
|---------|--------|
| `crontab -e` | Edit crontab |
| `crontab -l` | List crontab entries |
| `crontab -r` | Remove crontab |
| `crontab -u USER -l` | List another user's crontab (root) |
| `systemctl status cron` | Check if cron is running |
| `journalctl -u cron` | View cron logs |
| `grep CRON /var/log/syslog` | View cron syslog entries |

**Crontab Fields**

```
Field        Value Range
minute       0-59
hour         0-23
day          1-31
month        1-12
weekday      0-7 (0=Sunday, 7=Sunday)
```

**Special @-Times**

| Keyword | Equivalent |
|---------|-----------|
| `@reboot` | Run once at boot |
| `@daily` | `0 0 * * *` |
| `@weekly` | `0 0 * * 0` |
| `@monthly` | `0 0 1 * *` |
| `@hourly` | `0 * * * *` |
| `@yearly` | `0 0 1 1 *` |

### Level 2: Intermediary Commands — at and systemd timers

**at**

| Command | Action |
|---------|--------|
| `at TIME` | Schedule a command |
| `atq` | List pending jobs |
| `atrm ID` | Remove a job |
| `at -c ID` | Show job contents |
| `batch` | Run when load is low |

**Systemd Timers**

| Command | Action |
|---------|--------|
| `systemctl list-timers` | List active timers |
| `systemctl start NAME.timer` | Start a timer |
| `systemctl enable NAME.timer` | Enable timer at boot |
| `systemctl status NAME.timer` | Show timer status |

### Level 3: Advanced Commands (No additional commands — see scheduling patterns and deep understanding sections above)

---

## 🚀 What's Coming in Part 14

**Part 14: Logging and Journald — System Monitoring and Troubleshooting**

You will learn:
- The traditional syslog system (rsyslog)
- Journald — systemd's structured logging
- Log rotation with logrotate
- Centralized logging setup
- Analyzing logs for troubleshooting
- Log security and retention
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the five fields of a crontab entry (in order)?
2. What is the difference between a system crontab (`/etc/crontab`) and a user crontab?
3. How do you prevent cron from mailing you output?
4. What does `@daily` mean in crontab syntax?
5. Why should you always use full paths in cron jobs?
6. What is the `at` command used for?
7. How do you list pending `at` jobs?
8. What is `batch` and how is it different from `at`?
9. Name two features systemd timers have that cron does not.
10. How do you check if a cron job actually ran?
11. What does `Persistent=true` do in a systemd timer?
12. What is the `RandomizedDelaySec` directive used for?
13. What is `run-parts` and where is it used?
14. How do you add a script to run daily via cron?
15. What happens to cron output if MAILTO is not set?

**Score:** 12/15 correct = ready for Part 14.

---

*Linux SysAdmin Course | Part 13 of ∞ | Reverse Engineering Approach*
*Previous → Part 12: Systemd and Services*
*Next → Part 14: Logging and Journald*

[← Previous](part12.md) | [Next →](part14.md)
