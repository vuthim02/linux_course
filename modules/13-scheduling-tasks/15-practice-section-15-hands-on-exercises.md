## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### ✅ Level 1: Basic Practices


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


### ✅ Level 2: Intermediary Practices


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


### ✅ Level 3: Advanced Practices


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





[← Previous](14-deep-understanding-how-scheduling-really.md) | [↑ Index](index.md) | [Next →](16-summary-complete-command-reference-for.md)
