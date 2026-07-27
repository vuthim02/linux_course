## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### ✅ Practice 1: Explore ps

```bash
mkdir -p ~/linux-course/part9
cd ~/linux-course/part9

# Your processes
ps -u $(whoami)

# All system processes
ps -ef | head -20

# Count total processes
echo "Total processes: $(ps -e --no-headers | wc -l)"

# Count your processes
echo "Your processes: $(ps -u $(whoami) --no-headers | wc -l)"
```

---

### ✅ Practice 2: Process Tree

```bash
# See the process tree
ps -ef --forest | head -30

# With pstree (if installed)
pstree -p | head -30

# Find PID 1
ps -p 1 -o pid,comm
```

---

### ✅ Practice 3: Custom ps Output

```bash
# Top 5 CPU consumers
ps -e -o pid,user,%cpu,comm --sort=-%cpu | head -6

# Top 5 memory consumers
ps -e -o pid,user,%mem,comm --sort=-%mem | head -6

# Processes using more than 50MB memory
ps -e -o pid,user,rss,comm --sort=-rss | awk 'NR==1 || $3 > 51200'
```

---

### ✅ Practice 4: Explore top

```bash
# Run top for 3 iterations, then exit
top -b -n 3 | head -30

# Run top for a specific user
top -u $(whoami) -b -n 1 | head -20
```

---

### ✅ Practice 5: Background Jobs

```bash
# Run a long command in background
sleep 120 &

# Check jobs
jobs

# Bring to foreground
fg %1
# It will show "sleep 120" — press Ctrl+C to cancel

# Another way:
sleep 60 &
disown %1
# Now it's detached from shell
```

---

### ✅ Practice 6: Send Signals

```bash
# Start a process that will run for a while
sleep 300 &
PID=$!
echo "Started sleep with PID: $PID"

# Send SIGTERM
kill $PID
echo "Sent SIGTERM to $PID"

# Wait and check
sleep 1
ps -p $PID &>/dev/null && echo "Still running" || echo "Terminated"
```

---

### ✅ Practice 7: Practice kill Signals

```bash
# Start multiple sleep processes
sleep 100 &
sleep 101 &
sleep 102 &
sleep 103 &

# Kill all processes named "sleep" with SIGTERM
pkill sleep

# Or use killall
# killall sleep

# Verify
ps -C sleep
```

---

### ✅ Practice 8: Signal Handling

```bash
cd ~/linux-course/part9

# Create a script that handles signals
cat > signal_demo.sh << 'EOF'
#!/bin/bash
echo "My PID is $$"
echo "Send signals to me to see what happens."

cleanup() {
    echo "Received SIGTERM, cleaning up..."
    exit 0
}

trap cleanup SIGTERM SIGINT

echo "Try: kill -TERM $$ in another terminal"
echo "Or:  kill -INT $$"
echo ""

count=0
while true; do
    echo "Running... ($count)"
    ((count++))
    sleep 2
done
EOF

chmod +x signal_demo.sh
echo "Run: ./signal_demo.sh"
echo "In another terminal: kill -TERM <PID>"
```

---

### ✅ Practice 9: nohup

```bash
cd ~/linux-course/part9

# Create a script
cat > long_task.sh << 'EOF'
#!/bin/bash
for i in $(seq 1 10); do
    echo "Iteration $i at $(date)"
    sleep 2
done
echo "Done at $(date)"
EOF

chmod +x long_task.sh

# Run with nohup
nohup ./long_task.sh &

# Check output
cat nohup.out

# Run with custom log
nohup ./long_task.sh > my_task.log 2>&1 &
```

---

### ✅ Practice 10: Process Priority

```bash
# Check current nice value
nice

# Start a process with different priorities
nice -n 10 sleep 30 &
ps -o pid,ni,comm -p $!

nice -n -10 sleep 30 &
# Note: may need sudo for negative values
ps -o pid,ni,comm -p $!

# Renice a running process
sleep 30 &
PID=$!
sudo renice -n 5 -p $PID
ps -o pid,ni,comm -p $PID
```

---

### ✅ Practice 11: Explore /proc

```bash
# Your own process
ls /proc/$$

# Read command line
cat /proc/$$/cmdline | tr '\0' ' '
echo

# Process status
grep -E "Name|Pid|State|VmRSS|Threads" /proc/$$/status

# Open file descriptors
ls -la /proc/$$/fd/

# Current working directory
ls -la /proc/$$/cwd
```

---

### ✅ Practice 12: lsof

```bash
# Files opened by your shell
lsof -p $$ | head -20

# Network connections
sudo lsof -i 2>/dev/null | head -10

# Processes using a specific file
lsof /var/log/syslog 2>/dev/null || echo "Cannot access syslog"
```

---

### ✅ Practice 13: Monitor a Process

```bash
cd ~/linux-course/part9

# Create a script that uses CPU
cat > cpu_consumer.sh << 'EOF'
#!/bin/bash
echo "Consuming CPU for 30 seconds (PID: $$)"
echo "Watch in top or htop"
for i in $(seq 1 30); do
    result=$(echo "scale=10; 2^100" | bc 2>/dev/null || python3 -c "print(2**100)")
    echo -n "."
done
echo ""
echo "Done"
EOF

chmod +x cpu_consumer.sh

# Run it in background
./cpu_consumer.sh &

# Monitor with top (run this manually)
# top -u $(whoami)
```

---

### ✅ Practice 14: Find and Handle Issues

```bash
# Find processes with high memory
echo "Top 5 memory consumers:"
ps -e -o pid,user,%mem,rss,comm --sort=-%mem | head -6

# Find processes with high CPU
echo "Top 5 CPU consumers:"
ps -e -o pid,user,%cpu,comm --sort=-%cpu | head -6

# Find processes running as root
echo "Processes running as root:"
ps -U root -o pid,user,comm --no-headers | head -10

# Count processes per user
echo "Processes per user:"
ps -e -o user --no-headers | sort | uniq -c | sort -rn
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Process Investigation

```bash
cd ~/linux-course/part9

cat > process_investigator.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "======================================"
echo "  PROCESS INVESTIGATION REPORT"
echo "  Date: $(date)"
echo "======================================"
echo ""

echo "1. SYSTEM SUMMARY"
echo "----------------"
echo "Total processes: $(ps -e --no-headers | wc -l)"
echo "Running:     $(ps -e --no-headers -o stat | grep -c '^R')"
echo "Sleeping:    $(ps -e --no-headers -o stat | grep -c '^S')"
echo "Zombie:      $(ps -e --no-headers -o stat | grep -c '^Z')"
echo "Stopped:     $(ps -e --no-headers -o stat | grep -c '^T')"
echo ""

echo "2. TOP CPU CONSUMERS"
echo "-------------------"
ps -e -o pid,user,%cpu,comm --sort=-%cpu | head -6
echo ""

echo "3. TOP MEMORY CONSUMERS"
echo "---------------------"
ps -e -o pid,user,%mem,rss,comm --sort=-%mem | head -6
echo ""

echo "4. PROCESS COUNT BY USER"
echo "----------------------"
ps -e -o user --no-headers | sort | uniq -c | sort -rn
echo ""

echo "5. OLDEST PROCESSES"
echo "-----------------"
ps -e -o pid,user,etime,comm --no-headers --sort=-etime | head -10
echo ""

echo "6. PROCESS TREE (top level)"
echo "-------------------------"
pstree -p 2>/dev/null | head -20 || ps -ef --forest | head -20
echo ""

echo "======================================"
echo "  END OF REPORT"
echo "======================================"
EOF

chmod +x process_investigator.sh
./process_investigator.sh
```

---



---

[← Previous](10-section-9-zombie-and-orphan.md) | [↑ Index](index.md) | [Next →](12-deep-understanding-how-the-scheduler.md)
