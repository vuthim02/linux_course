# 🐧 Linux System Administrator — Complete Course
## Part 9 of ∞: Process Management — ps, top, kill, and Signals

---

> **Reverse Engineering Approach:** Your computer runs hundreds of processes simultaneously. How does Linux decide which one gets CPU time? What happens when a program freezes? How do you find the process eating all your memory? We start from the observable behavior — "my system is slow" — and trace it back to the processes, signals, and kernel scheduler that control everything.

---

## 🎯 What You Will Achieve in Part 9

By the end of this part, you will:

- Understand what a process is and how Linux identifies it
- List and filter processes with `ps`
- Monitor system resources in real time with `top` and `htop`
- Send signals to processes with `kill`, `pkill`, and `killall`
- Understand Linux signals (SIGTERM, SIGKILL, SIGHUP, etc.)
- Manage process priority with `nice` and `renice`
- Run processes in background and foreground
- Use `nohup`, `disown`, and `screen` for long-running tasks
- Find and handle zombie processes
- Complete **15 hands-on practices**

---

## 🔍 Section 1: What Is a Process?

A **process** is a running instance of a program. When you run `ls`, the kernel loads the `/usr/bin/ls` binary into memory, gives it a unique ID (PID), allocates resources, and starts executing it. That running instance is a process.

### Process vs Program

```
Program (on disk):     /usr/bin/python3
Process (in memory):   PID 1234 — running python3 script.py
```

A single program can have multiple processes. For example, your web browser might have 10+ processes, each handling a different tab.

### The Process ID (PID)

Every process gets a unique number called a **PID** (Process ID).

```bash
# PIDs are assigned sequentially
# PID 1 is always 'init' or 'systemd' — the first process started by the kernel
# PIDs wrap around when they reach the maximum
```

### The Process Tree

Every process except the first has a **parent process** (PPID). This creates a tree:

```
systemd (PID 1)
├── sshd (PID 100)
│   └── sshd (PID 200)
│       └── bash (PID 201)
│           ├── ps (PID 300)
│           └── vim (PID 301)
├── cron (PID 110)
├── nginx (PID 120)
│   ├── nginx (PID 121)
│   └── nginx (PID 122)
└── ...
```

```bash
# See your process tree
ps -ef --forest

# Or use pstree
pstree -p
```

---

## 🔍 Section 2: ps — Snapshot of Running Processes

`ps` shows a snapshot of processes at a given moment. It has dozens of options, but most sysadmins use only a few combinations.

### Essential ps Combinations

```bash
# All processes, full format (BSD style)
ps aux

# All processes, full format (standard style)
ps -ef

# All processes with user-defined format
ps -e -o pid,ppid,cmd,%mem,%cpu --sort=-%mem

# Your processes only
ps -u $(whoami)

# Processes of a specific user
ps -u alice

# Processes connected to a terminal
ps -t pts/0
```

### Understanding ps aux Output

```bash
ps aux
```

```
USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.4 168272 13956 ?        Ss   Jan15   0:03 /sbin/init
root       100  0.0  0.1  72340  4568 ?        Ss   Jan15   0:00 sshd: /usr/sbin...
alice     1568  0.1  2.1 584324 67820 ?        Sl   10:00   0:15 /usr/bin/gnome-shell
alice     3201  0.0  0.2  28548  8764 pts/0    Ss   10:05   0:00 -bash
alice     4567  2.5  0.8 485632 25612 ?        Rl   10:30   1:20 /usr/bin/firefox
```

| Column | Meaning |
|--------|---------|
| USER | Owner of the process |
| PID | Process ID |
| %CPU | CPU usage percentage |
| %MEM | Memory usage percentage |
| VSZ | Virtual memory size (KB) |
| RSS | Resident Set Size (physical memory, KB) |
| TTY | Terminal connected to (or `?` for none) |
| STAT | Process state code |
| START | When process started |
| TIME | Total CPU time used |
| COMMAND | The command that started the process |

### Process States (STAT column)

| Code | State | Meaning |
|------|-------|---------|
| R | Running | Actively using CPU or in run queue |
| S | Sleeping | Waiting for something (most processes) |
| D | Uninterruptible Sleep | Waiting for I/O (disk). Cannot be killed easily |
| Z | Zombie | Child process that finished but parent hasn't collected it |
| T | Stopped | Paused by a signal (SIGSTOP or SIGTSTP) |
| X | Dead | Should never be seen |

Additional characters:
- `<` — High priority (not nice to others)
- `N` — Low priority (nice to others)
- `s` — Session leader (contains child processes)
- `l` — Multi-threaded (CLONE_THREAD)
- `+` — In the foreground process group

### Custom ps Output

```bash
# Show only specific columns
ps -e -o pid,user,%cpu,%mem,comm --sort=-%cpu

# Top 5 memory consumers
ps -e -o pid,user,%mem,comm --sort=-%mem | head -6

# Find processes using more than 10% CPU
ps -e -o pid,user,%cpu,comm --sort=-%cpu | awk '$3 > 10'

# Script-friendly output (no headers)
ps -e -o pid --no-headers
```

---

## 🔍 Section 3: top — Real-Time Process Monitoring

`top` refreshes every few seconds, showing a live view of the system.

```bash
# Start top
top

# Start top sorted by memory
top -o %MEM

# Show only processes of a specific user
top -u alice

# Batch mode (for scripts)
top -b -n 1
```

### Understanding the top Header

```bash
top - 10:30:45 up 3 days,  2:15,  3 users,  load average: 0.08, 0.12, 0.10
Tasks: 245 total,   1 running, 244 sleeping,   0 stopped,   0 zombie
%Cpu(s):  2.5 us,  0.8 sy,  0.0 ni, 96.5 id,  0.2 wa,  0.0 hi,  0.0 si
MiB Mem :   7932.8 total,   2045.6 free,   3245.2 used,   2642.1 buff/cache
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   4289.6 avail Mem
```

| Line | Key Fields | Meaning |
|------|-----------|---------|
| Top | `load average` | 1, 5, 15 minute averages. < cores = healthy |
| Tasks | `running`, `sleeping`, `zombie` | Process counts |
| CPU | `us`, `sy`, `id`, `wa` | User, system, idle, I/O wait |
| Mem | `total`, `used`, `free`, `buff/cache` | RAM usage |
| Swap | `total`, `used` | Swap usage |

### Interactive top Commands

While `top` is running:

| Key | Action |
|-----|--------|
| `q` | Quit |
| `h` | Help |
| `1` | Toggle per-CPU stats |
| `P` | Sort by CPU usage (descending) |
| `M` | Sort by memory usage (descending) |
| `T` | Sort by running time |
| `k` | Kill a process (enter PID, then signal) |
| `r` | Renice a process (change priority) |
| `u` | Show only one user's processes |
| `c` | Toggle full command path |
| `W` | Write current settings to ~/.toprc |

### htop — Enhanced top

```bash
# Install
sudo apt install htop       # Debian/Ubuntu
sudo dnf install htop        # Fedora

# Run
htop
```

`htop` adds:
- Color-coded display
- Mouse support (click to sort, select)
- Tree view (F5)
- Easy kill/renice with arrow keys
- Scroll through all processes
- Vertical and horizontal scrolling

---

## 🔍 Section 4: Signals — How to Talk to Processes

A **signal** is a notification sent to a process. It can tell it to terminate, stop, continue, reload config, etc.

### Common Signals

| Signal | Number | Action | Default Behavior |
|--------|--------|--------|------------------|
| SIGHUP | 1 | Hang up | Terminate (often reloads config) |
| SIGINT | 2 | Interrupt | Terminate (Ctrl+C sends this) |
| SIGQUIT | 3 | Quit | Terminate with core dump |
| SIGKILL | 9 | Kill | Force terminate (cannot be caught/ignored) |
| SIGTERM | 15 | Terminate | Terminate gracefully (default for `kill`) |
| SIGCONT | 18 | Continue | Resume a stopped process |
| SIGSTOP | 19 | Stop | Pause (cannot be caught/ignored) |
| SIGTSTP | 20 | Terminal stop | Pause (Ctrl+Z sends this) |

### Sending Signals With kill

```bash
# Basic kill — sends SIGTERM (15)
kill 1234

# Send specific signal by name
kill -SIGTERM 1234
kill -TERM 1234
kill -15 1234

# Force kill (SIGKILL) — last resort
kill -SIGKILL 1234
kill -KILL 1234
kill -9 1234

# Reload config (SIGHUP) — no restart needed
kill -HUP 1234
```

### pkill — Kill by Name

```bash
# Kill all processes named "firefox"
pkill firefox

# Kill all processes of a user
pkill -u alice

# Send specific signal
pkill -9 firefox

# Kill by full command
pkill -f "python3 server.py"

# Show what would be killed (safe test)
pkill -f "python3" --echo
```

### killall — Kill by Name (Exact Match)

```bash
# Kill all processes named exactly "nginx"
sudo killall nginx

# Send specific signal
sudo killall -9 nginx

# Interactive mode (ask before each kill)
sudo killall -i nginx
```

### Which Signal to Use When

```
1. Try SIGTERM (kill PID)          Graceful shutdown, allows cleanup
2. Wait 5 seconds
3. If still running: SIGKILL (kill -9 PID)   Force kill, no cleanup

NEVER start with kill -9 unless absolutely necessary.
SIGKILL doesn't let the process save files or close connections.
```

---

## 🔍 Section 5: Managing Background and Foreground Jobs

### Running a Process in Background

```bash
# Add & at the end
long_running_command &

# Or press Ctrl+Z to suspend, then bg to background
long_running_command
# Press Ctrl+Z
[1]+  Stopped                 long_running_command
bg
[1]+ long_running_command &
```

### Managing Jobs

```bash
# List background jobs
jobs

# Bring a job to foreground
fg %1

# Run a stopped job in background
bg %1

# Kill a job
kill %1
```

### Output from Background Jobs

```bash
# Background jobs still write to the terminal
# This can be annoying:
find / > output.txt &
# It's fine if output is redirected

# To suppress all output:
find / > /dev/null 2>&1 &
```

---

## 🔍 Section 6: nohup, disown, and screen

When you close a terminal, all processes started from it receive SIGHUP and terminate. These tools prevent that.

### nohup — No Hang Up

```bash
# Run a command immune to hangups
nohup long_running_script.sh &

# Output goes to nohup.out (unless redirected)
nohup backup.sh > backup.log 2>&1 &

# If you log out and back in, the process continues running
```

### disown — Detach From Shell

```bash
# Start a job
long_running_script &

# Remove it from the shell's job table
disown %1

# Now closing the terminal won't kill it
# The process is orphaned and re-parented to init/systemd
```

### screen — Terminal Multiplexer

```bash
# Install
sudo apt install screen

# Start a screen session
screen -S mysession

# Inside screen:
# Run your long command
# Detach: Ctrl+A, then d

# Re-attach:
screen -r mysession

# List sessions
screen -ls

# Re-attach to a detached session
screen -r

# Kill a session
screen -S mysession -X quit
```

### tmux — Modern Alternative

```bash
# Install
sudo apt install tmux

# Start
tmux new -s mysession

# Detach: Ctrl+B, then d
# Re-attach: tmux attach -t mysession
# List: tmux ls
```

---

## 🔍 Section 7: nice and renice — Process Priority

Linux schedules processes based on **niceness** (NI). Higher nice value = lower priority.

### Nice Values

```
-20 (highest priority)  ←── Only root can set negative values
  0 (default)
 19 (lowest priority)   ←── Anyone can set this
```

### Starting a Process With Different Priority

```bash
# Start with low priority (nice = 10)
nice -n 10 ./backup.sh

# Start with high priority (requires root)
sudo nice -n -10 ./urgent_task.sh

# Default nice is 10 if no value given
nice ./script.sh
```

### Changing Priority of Running Process

```bash
# Make PID 1234 lower priority (nicer to other processes)
renice 10 -p 1234

# Make PID 1234 higher priority (needs root)
sudo renice -5 -p 1234

# Renice by user (all processes)
renice 10 -u alice

# Renice by group
renice 10 -g developers
```

### Viewing Nice Values

```bash
# Show nice values in ps
ps -eo pid,ni,comm

# In top, press 'r' to renice, or sort by NI with '<' and '>'
```

---

## 🔍 Section 8: /proc — The Process Filesystem

Every running process has a directory in `/proc` with detailed information.

```bash
# View your own process info
ls /proc/$$/
# cmdline          — command that started the process
# cwd              — symlink to current working directory
# environ          — environment variables
# exe              — symlink to executable
# fd/              — open file descriptors
# limits           — resource limits
# maps             — memory mappings
# status           — process status summary

# Read a process's command line
cat /proc/1234/cmdline | tr '\0' ' '

# Read a process's environment
cat /proc/1234/environ | tr '\0' '\n'

# See open files (like lsof)
ls -la /proc/1234/fd/

# Check process status
cat /proc/1234/status
```

### lsof — List Open Files

```bash
# List all open files
lsof

# List files opened by a specific process
lsof -p 1234

# List processes that have a specific file open
lsof /var/log/syslog

# List files opened by a user
lsof -u alice

# List network connections
lsof -i

# List listening ports
lsof -i -P -n | grep LISTEN
```

---

## 🔍 Section 9: Zombie and Orphan Processes

### Zombie Processes

A **zombie** is a process that has finished executing but still has an entry in the process table because its parent hasn't read its exit status.

```bash
# Find zombies
ps aux | grep Z
# Or:
top -b -n 1 | grep zombie

# Zombies show STAT = Z in ps
```

**Can you kill a zombie?** No. A zombie is already dead. It's just waiting for its parent to call `wait()`. The only ways to remove zombies:
1. Kill the parent process (zombies are inherited by init which reaps them)
2. The parent calls `wait()` to collect the exit status

### Orphan Processes

When a parent dies before its child, the child becomes an **orphan**. Orphans are adopted by PID 1 (systemd/init), which periodically calls `wait()` to clean them up.

```bash
# Orphans are normal and harmless
# They just get re-parented to PID 1
```

---

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

## 🧠 Deep Understanding — How the Scheduler Works

### The O(1) and CFS Schedulers

Linux uses the **Completely Fair Scheduler** (CFS), which tries to give every process a fair share of CPU time.

```
Key concepts:
  - vruntime: virtual runtime — how long each process has run
  - CFS keeps processes sorted by vruntime in a red-black tree
  - Always picks the process with the lowest vruntime (least served)
  - nice values act as weight multipliers:
    - nice 0 = weight 1024
    - nice 10 = weight ~335 (gets ~1/3 of default)
    - nice -10 = weight ~3162 (gets ~3x of default)
```

### Context Switching

When the kernel switches from one process to another:

```
1. Save current process registers to its kernel stack
2. Save current process memory mapping (page tables)
3. Flush TLB (translation lookaside buffer)
4. Load new process memory mapping
5. Load new process registers
6. Resume execution

This takes microseconds, but frequent context switching
(too many processes) adds overhead.
```

### Why Too Many Processes Slows Things Down

```
100 processes all wanting CPU time:
  Each gets 1% of CPU time
  Plus overhead of 100 context switches per second
  
This is why "runaway processes" (fork bombs) can freeze a system.
```

---

## 📋 Summary — Complete Command Reference for Part 9

### Process Listing

| Command | Action |
|---------|--------|
| `ps aux` | All processes (BSD style) |
| `ps -ef` | All processes (standard) |
| `ps -u user` | Processes of a user |
| `ps -p PID` | Specific process |
| `ps -e -o pid,comm --sort=-%cpu` | Custom format, sorted |
| `pstree` | Process tree |
| `top` | Real-time monitor |
| `htop` | Enhanced real-time monitor |

### Signals

| Command | Action |
|---------|--------|
| `kill PID` | Send SIGTERM |
| `kill -9 PID` | Send SIGKILL (force kill) |
| `kill -HUP PID` | Send SIGHUP (reload config) |
| `pkill name` | Kill by process name |
| `pkill -u user` | Kill all processes of user |
| `killall name` | Kill by exact name |
| `kill -l` | List all signals |

### Background Jobs

| Command | Action |
|---------|--------|
| `command &` | Run in background |
| `jobs` | List background jobs |
| `fg %1` | Bring job 1 to foreground |
| `bg %1` | Resume job 1 in background |
| `Ctrl+Z` | Suspend current job |
| `Ctrl+C` | Terminate current job |

### Process Persistence

| Command | Action |
|---------|--------|
| `nohup command &` | Immune to hangups |
| `disown %1` | Detach from shell |
| `screen -S name` | Create screen session |
| `screen -r name` | Reattach to screen |
| `tmux new -s name` | Create tmux session |

### Priority

| Command | Action |
|---------|--------|
| `nice -n 10 command` | Start with low priority |
| `renice 10 -p PID` | Change priority of running process |
| `renice 10 -u user` | Change priority of user's processes |

### Process Information

| Command | Action |
|---------|--------|
| `cat /proc/PID/status` | Process status |
| `cat /proc/PID/cmdline` | Command line |
| `ls -la /proc/PID/fd/` | Open file descriptors |
| `lsof -p PID` | List open files |
| `lsof -i` | List network connections |
| `pidof command` | Find PID of command |

---

## 🚀 What's Coming in Part 10

**Part 10: The Linux Boot Process — From Power On to Login**

You will learn:
- What happens from the moment you press the power button
- BIOS/UEFI — the first code that runs
- GRUB — the bootloader that loads the kernel
- The kernel initialization
- systemd — the first userspace process
- Service startup and targets
- Troubleshooting boot problems
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between a program and a process?
2. What is PID 1 and why is it special?
3. What is a zombie process and how do you remove one?
4. What does the `ps aux` command show?
5. What is the difference between SIGTERM and SIGKILL?
6. When would you use `kill -9` instead of `kill`?
7. What does `nohup` do and when would you use it?
8. What is the difference between `nice` and `renice`?
9. What is the range of nice values and what does each mean?
10. How do you run a command in the background?
11. What is `lsof` used for?
12. What information is available in `/proc/PID/`?
13. What does `pkill -u alice` do?
14. How do you detach a process from the current shell so it survives logout?
15. What command shows a tree of running processes?

**Score:** 12/15 correct = ready for Part 10.

---

*Linux SysAdmin Course | Part 9 of ∞ | Reverse Engineering Approach*
*Previous → Part 8: Archiving and Compression — tar, gzip, zip*
*Next → Part 10: The Linux Boot Process — From Power On to Login*

[← Previous](part8.md) | [Next →](part10.md)
