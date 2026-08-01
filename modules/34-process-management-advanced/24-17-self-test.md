## 17. Self-Test

**Instructions:** Answer each question. Score 12/15 correct = ready for Part 35.

### Question 1
What field in `task_struct` distinguishes a process from a thread?
a) `pid`  b) `tgid`  c) `ppid`  d) `__state`

### Question 2
Which process state is uninterruptible and cannot be killed even with SIGKILL?
a) S  b) R  c) D  d) T

### Question 3
What does `ps -eLf` show that `ps -ef` does not?
a) Full command lines  b) Thread IDs (LWP)  c) Memory maps  d) CPU affinity

### Question 4
Which signal is uncatchable and terminates a process immediately?
a) SIGTERM  b) SIGHUP  c) SIGSTOP  d) SIGKILL

### Question 5
How do you check if a process with PID 1234 exists without sending a signal?
a) `kill -1 1234`  b) `kill -0 1234`  c) `kill -15 1234`  d) `kill -9 1234`

### Question 6
What is the range of niceness values?
a) -100 to 100  b) 0 to 139  c) -20 to 19  d) 0 to 1000

### Question 7
A process started with `nice -n 19` will get ____________ CPU compared to a default process.
a) More  b) Less  c) The same  d) No

### Question 8
What does `ulimit -n` control?
a) Maximum number of processes  b) Maximum number of open file descriptors
c) Maximum stack size  d) Maximum core file size

### Question 9
What file in `/proc/PID/` shows the process's current resource limits?
a) `status`  b) `limits`  c) `rlimit`  d) `ulimit`

### Question 10
Which `oom_score_adj` value makes a process completely immune to the OOM killer?
a) 0  b) -500  c) -1000  d) 1000

### Question 11
In cgroups v2, which file sets the memory limit?
a) `memory.limit_in_bytes`  b) `memory.max`  c) `memory.high`  d) `memory.swap.max`

### Question 12
What is the difference between `nohup cmd &` and `cmd &` alone?
a) `nohup` redirects output to `nohup.out`  b) `nohup` ignores SIGHUP
c) Both a and b  d) There is no difference

### Question 13
What happens to a zombie process that has been reparented to init and init calls wait()?
a) It becomes a running process again  b) It is reaped (freed from the process table)
c) It stays a zombie forever  d) It is killed with SIGKILL

### Question 14
Which CFS data structure is used to pick the next task to run?
a) A linked list  b) A red-black tree keyed by vruntime
c) A priority bitmap  d) A hash table keyed by PID

### Question 15
Which scheduling class has the highest priority?
a) `idle_sched_class`  b) `fair_sched_class`  c) `rt_sched_class`  d) `stop_sched_class`


### Answer Key

| Q | Answer | Explanation |
|---|---|---|
| 1 | **b)** `tgid` | Main threads have `pid == tgid`, worker threads have `pid != tgid`. |
| 2 | **c)** D | Uninterruptible sleep (D state) blocks all signals, including SIGKILL. |
| 3 | **b)** Thread IDs (LWP) | `ps -eLf` adds the LWP (TID) column and shows one line per thread. |
| 4 | **d)** SIGKILL | Signal 9 is uncatchable, unblockable, and immediately kills the process. |
| 5 | **b)** `kill -0 1234` | Signal 0 performs error checking only — no signal is actually sent. |
| 6 | **c)** -20 to 19 | Lower is nicer to the process (more CPU priority), higher is less nice. |
| 7 | **b)** Less | Nice 19 is the lowest priority — CFS gives this process minimal CPU. |
| 8 | **b)** Maximum number of open file descriptors | `ulimit -n` controls `RLIMIT_NOFILE`. |
| 9 | **b)** `limits` | `/proc/PID/limits` shows soft and hard limits for all resources. |
| 10 | **c)** -1000 | `oom_score_adj = -1000` subtracts 1000 from the badness score, making it 0 or negative. |
| 11 | **b)** `memory.max` | In cgroups v2, `memory.max` replaces v1's `memory.limit_in_bytes`. |
| 12 | **c)** Both a and b | `nohup` both ignores SIGHUP and redirects output to `nohup.out`. |
| 13 | **b)** It is reaped | Init's `wait()` call collects the exit status and frees the zombie's `task_struct`. |
| 14 | **b)** A red-black tree keyed by vruntime | CFS stores tasks in an rbtree; the leftmost node (smallest vruntime) runs next. |
| 15 | **d)** `stop_sched_class` | Stop class is the highest priority (for CPU hotplug and stop-machine). |

**Score:** ___/15 correct

- 14-15: Ready for Part 35. Excellent.
- 12-13: Ready for Part 35. Good foundation.
- 10-11: Review the Deep Understanding section before proceeding.
- 0-9: Re-read Part 34 and redo the hands-on practices.





[← Previous](21-15-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](23-18-whats-coming-in-part.md)
