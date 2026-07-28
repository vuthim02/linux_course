## 15. 15 Hands-On Practices

### Level 1 Practices: Basic Process Management

#### Practice 1: Explore the Process Tree

```
$ pstree -p -u
$ ps -eo pid,ppid,state,comm --sort=pid
$ ps -ef --forest
```

Answer: How many processes are direct children of PID 1 (init/systemd)?

#### Practice 2: Thread View

```
$ ps -eLf | head -20
$ cat /proc/$(pgrep -x systemd-journald)/status | grep Threads
```

Answer: Which processes have more than 10 threads?

#### Practice 3: Find Zombie Processes

```
$ ps -eo pid,stat,comm | grep -w Z
$ top -b -n1 | grep zombie
$ bash -c 'sleep 1 & exec sleep 10' &
$ ps -eo pid,ppid,stat,comm | grep -E "S|Z"
```

Answer: What state are zombie processes in? Can a zombie be killed with SIGKILL?

#### Practice 4: Send Signals

```
$ sleep 300 &
$ kill -SIGSTOP %1
$ ps -o pid,stat,comm $(pgrep -x sleep)
$ kill -SIGCONT %1
$ ps -o pid,stat,comm $(pgrep -x sleep)
$ kill %1
```

Question: What state does a STOPped process show? What about a running process?

#### Practice 5: Custom `ps` Output

```
$ ps -eo pid,ppid,user,%cpu,%mem,comm,etime,lstart,nice,rss,vsz,args \
       --sort=-%mem | head -15
```

Question: Which three processes consume the most memory on your system?

### Level 2 Practices: Intermediary Process Management

#### Practice 6: Change Niceness

```
$ nice -n 19 bash -c 'while true; do :; done' &
$ sudo nice --20 bash -c 'while true; do :; done' &
$ ps -eo pid,comm,nice,%cpu --sort=nice | head -10
$ kill $(pgrep -x bash)
```

Question: How much more CPU does the -20 process get than the +19 process on a single-core machine running only these two?

#### Practice 7: Set File Descriptor Limit

```
$ ulimit -n 30
$ bash -c 'for i in $(seq 1 40); do exec 3<>/dev/null; echo "FD $i opened"; done'
$ ulimit -n 1024
```

Question: What error do you get when exceeding the file descriptor limit?

#### Practice 8: Examine `/proc/PID` in Depth

```
$ echo $$
$ ls -la /proc/$$/fd/
$ cat /proc/$$/status | grep -E "VmRSS|Threads|SigQ"
$ cat /proc/$$/maps | head -10
$ cat /proc/$$/limits | grep "Max open files"
$ cat /proc/$$/sched | head -15
```

Question: How many file descriptors does your current shell have open? How many threads?

#### Practice 9: Trace Process Start Time

```
$ ps -eo pid,comm,lstart,etime --sort=start_time | tail -20
```

Question: Which process has been running the longest (other than PID 1)?

#### Practice 10: Enable and Read a Core Dump

```
$ ulimit -c unlimited
$ python3 -c 'import ctypes; ctypes.string_at(0)' &
$ sleep 2
$ ls -la core.*
```

Question: What's in a core file? (Answer with `file core.PID`)

### Level 3 Practices: Advanced Process Management

#### Practice 11: OOM Score Exploration

```
$ cat /proc/$$/oom_score
$ cat /proc/$$/oom_score_adj
$ sudo bash -c 'echo 500 > /proc/$$/oom_score_adj'
$ cat /proc/$$/oom_score
```

Question: What happens to `oom_score` when you set `oom_score_adj` to 500?

#### Practice 12: Create a cgroup v2 Memory Limit

```
# Only if cgroups v2 is active:
$ sudo mkdir /sys/fs/cgroup/demo
$ echo 50000000 | sudo tee /sys/fs/cgroup/demo/memory.max   # 50 MB limit
$ echo $$ | sudo tee /sys/fs/cgroup/demo/cgroup.procs
$ bash -c 'x=""; while true; do x="$x $(head -c 1M /dev/zero)"; done' &
$ sleep 5 ; dmesg | tail -5
$ sudo rmdir /sys/fs/cgroup/demo
```

Question: What does the kernel do when the process exceeds the cgroup memory limit?

#### Practice 13: Background Job Survival

```
$ ssh localhost
$ nohup sleep 60 &
$ disown
$ exit  # SSH back in
$ ps aux | grep sleep   # still there
```

Then repeat without `nohup` and `disown`:
```
$ ssh localhost
$ sleep 60 &
$ exit  # SSH back in
$ ps aux | grep sleep   # should be gone
```

Question: Why does `nohup` make a difference?

#### Practice 14: tmux Persistent Session

```
$ tmux new -s testwork
  # Inside tmux: run a long command
  $ while true; do date >> /tmp/tmux_test; sleep 5; done
  # Press Ctrl+B d to detach
$ tmux ls
# Close the terminal, open a new one
$ tmux attach -t testwork
$ cat /tmp/tmux_test
```

Question: Did the process continue running while detached?

#### Practice 15: Real-World Integration — Process Audit and Resource Report Script

```bash
#!/bin/bash
# process_audit.sh — Generate a system process resource report

REPORT="/tmp/process_audit_$(date +%Y%m%d_%H%M%S).txt"

{
  echo "=============================================="
  echo "  PROCESS AUDIT REPORT"
  echo "  Generated: $(date)"
  echo "=============================================="
  echo ""

  echo "--- 1. Top 10 Memory Consumers ---"
  ps -eo pid,ppid,user,%mem,%cpu,rss,comm --sort=-%mem \
      --width 120 | head -11
  echo ""

  echo "--- 2. Top 10 CPU Consumers ---"
  ps -eo pid,ppid,user,%cpu,%mem,rss,comm --sort=-%cpu \
      --width 120 | head -11
  echo ""

  echo "--- 3. Process Count by User ---"
  ps -eo user --no-headers | sort | uniq -c | sort -rn
  echo ""

  echo "--- 4. Total Process Count ---"
  echo "  Total processes : $(ps -e --no-headers | wc -l)"
  echo "  Running         : $(ps -e --no-headers -o state | grep -c '^R$')"
  echo "  Sleeping        : $(ps -e --no-headers -o state | grep -c '^S$')"
  echo "  Zombie          : $(ps -e --no-headers -o state | grep -c '^Z$')"
  echo "  Stopped         : $(ps -e --no-headers -o state | grep -c '^T$')"
  echo "  D-state         : $(ps -e --no-headers -o state | grep -c '^D$')"
  echo ""

  echo "--- 5. Zombie Processes (if any) ---"
  ZOMBIES=$(ps -eo pid,ppid,user,comm --state Z)
  if [ -z "$ZOMBIES" ]; then
    echo "  No zombie processes."
  else
    echo "$ZOMBIES"
  fi
  echo ""

  echo "--- 6. Processes with Open Sockets ---"
  for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
    if [ -d "/proc/$pid/fd" ] 2>/dev/null; then
      sockets=$(ls -la /proc/$pid/fd 2>/dev/null | grep -c socket)
      if [ "$sockets" -gt 0 ]; then
        comm=$(cat /proc/$pid/comm 2>/dev/null)
        echo "  PID $pid ($comm): $sockets socket(s)"
      fi
    fi
  done | head -20
  echo ""

  echo "--- 7. Processes with Open File Limits Near Exhaustion ---"
  for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
    if [ -d "/proc/$pid/fd" ] 2>/dev/null && [ -r "/proc/$pid/limits" ] 2>/dev/null; then
      open_fds=$(ls /proc/$pid/fd 2>/dev/null | wc -l)
      max_fds=$(grep "Max open files" /proc/$pid/limits 2>/dev/null | awk '{print $4}')
      if [ -n "$max_fds" ] && [ "$max_fds" -gt 0 ] 2>/dev/null; then
        pct=$(( open_fds * 100 / max_fds ))
        if [ "$pct" -ge 80 ]; then
          comm=$(cat /proc/$pid/comm 2>/dev/null)
          echo "  PID $pid ($comm): ${open_fds}/${max_fds} FDs (${pct}% full)"
        fi
      fi
    fi
  done
  echo ""

  echo "--- 8. Process Tree (Root) ---"
  pstree -h 2>/dev/null || pstree
  echo ""

  echo "--- 9. OOM Scores of Top Memory Consumers ---"
  ps -eo pid,comm,%mem --sort=-%mem --no-headers | head -10 | while read pid comm mem; do
    if [ -r "/proc/$pid/oom_score" ]; then
      score=$(cat /proc/$pid/oom_score)
      echo "  PID $pid ($comm): oom_score=$score, RSS=${mem}%"
    fi
  done
  echo ""

  echo "--- 10. System-wide ulimit Impact ---"
  echo "  File handle limit (system-wide): $(cat /proc/sys/fs/file-max)"
  echo "  File handles used: $(cat /proc/sys/fs/file-nr | cut -f1)"
  echo "  Max PID: $(cat /proc/sys/kernel/pid_max)"
  echo "  Threads max: $(cat /proc/sys/kernel/threads-max)"
  echo ""

  echo "=============================================="
  echo "  END OF REPORT"
  echo "=============================================="
} | tee "$REPORT"

echo ""
echo "Report saved to: $REPORT"
```

Identify:
- Which user owns the most processes
- Any zombie processes
- Any processes close to their FD limit
- The highest OOM score and what process has it





[← Previous](20-14-command-reference.md) | [↑ Index](index.md) | [Next →](22-17-self-test.md)
