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





[← Previous](11-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](13-summary-complete-command-reference-for.md)
