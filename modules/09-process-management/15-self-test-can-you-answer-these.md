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


## Answer Key

### Q1: What is the difference between a program and a process?
**Answer:** A program is a static executable file on disk. A process is a program in execution with allocated memory, CPU time, and system resources.

### Q2: What is PID 1 and why is it special?
**Answer:** PID 1 is the first process started by the kernel (usually `init` or `systemd`). It adopts orphan processes and cannot be killed with SIGKILL.

### Q3: What is a zombie process and how do you remove one?
**Answer:** A zombie has finished execution but its parent hasn't called `wait()`. Fix: make the parent reap the child (kill the parent, or fix the parent code).

### Q4: What does `ps aux` show?
**Answer:** All running processes with details: user, CPU%, MEM%, command, PID, TTY, and status.

### Q5: What is the difference between SIGTERM and SIGKILL?
**Answer:** SIGTERM (15) asks the process to terminate gracefully (can be caught and handled). SIGKILL (9) forcefully kills it immediately (cannot be caught).

### Q6: When would you use `kill -9` instead of `kill`?
**Answer:** Only when a process ignores SIGTERM and won't shut down gracefully. It's a last resort.

### Q7: What does `nohup` do and when would you use it?
**Answer:** `nohup` makes a process ignore SIGHUP, so it survives terminal disconnection. Use when running long jobs via SSH.

### Q8: What is the difference between `nice` and `renice`?
**Answer:** `nice` starts a command with a specific priority. `renice` changes the priority of an already-running process.

### Q9: What is the range of nice values and what does each mean?
**Answer:** -20 (highest priority, most CPU) to 19 (lowest priority, least CPU). Default is 0.

### Q10: How do you run a command in the background?
**Answer:** Append `&` to the command: `command &`. Use `bg` to background a suspended process, `fg` to bring it back.

### Q11: What is `lsof` used for?
**Answer:** Lists open files and the processes using them. Useful for finding which process holds a file, port, or socket.

### Q12: What information is available in `/proc/PID/`?
**Answer:** Command line, memory maps, file descriptors, status, environment, limits, and more — all about the process.

### Q13: What does `pkill -u alice` do?
**Answer:** Sends SIGTERM to all processes owned by user `alice`.

### Q14: How do you detach a process from the current shell so it survives logout?
**Answer:** `nohup command &` or use `disown` after running the process. A terminal multiplexer (tmux/screen) also works.

### Q15: What command shows a tree of running processes?
**Answer:** `pstree` — displays processes in a hierarchical tree format.


*Linux SysAdmin Course | Part 9 of ∞ | Reverse Engineering Approach*
*Previous → Part 8: Archiving and Compression — tar, gzip, zip*
*Next → Part 10: The Linux Boot Process — From Power On to Login*

[← Previous](part8.md) | [Next →](part10.md)



[← Previous](14-whats-coming-in-part-10.md) | [↑ Index](index.md)
