## ✅ Self-Test

### Question 1
What does the USE method in performance analysis stand for?
```
A) Understand, Simulate, Evaluate
B) Utilization, Saturation, Errors
C) Unify, Scale, Execute
D) User, System, Environment
```

### Question 2
Which CPU governor should you use for a latency-sensitive database server?
```
A) powersave
B) ondemand
C) performance
D) conservative
```

### Question 3
What effect does setting `vm.swappiness=10` have compared to the default (60)?
```
A) It makes the system swap more aggressively
B) It reduces swapping of anonymous pages, preferring to drop file-backed pages instead
C) It disables swap entirely
D) It increases the size of swap space
```

### Question 4
Which I/O scheduler is recommended for NVMe drives?
```
A) mq-deadline
B) BFQ
C) none
D) kyber
```

### Question 5
What does `numactl --cpunodebind=0 --membind=0 ./app` do?
```
A) Runs the app on any CPU but allocates memory on node 0
B) Runs the app on CPU 0 and allocates memory on node 0 only
C) Runs the app on all CPUs but binds memory to node 0
D) Distributes the app equally across all NUMA nodes
```

### Question 6
Which sysctl parameter controls the maximum receive socket buffer size?
```
A) net.core.rmem_default
B) net.core.rmem_max
C) net.ipv4.tcp_rmem
D) net.core.netdev_budget
```

### Question 7
What is the purpose of `perf record` followed by `perf report`?
```
A) To count system calls during a program's execution
B) To sample a running program's call stack at regular intervals and display the hottest paths
C) To trace disk I/O operations
D) To benchmark network throughput
```

### Question 8
In `strace`, what does the `-T` flag do?
```
A) Filter syscalls by type
B) Show the time spent in each system call
C) Follow child processes
D) Trace threads only
```

### Question 9
Which of the following is a bpftrace tool for generating a latency histogram of block I/O?
```
A) perf stat -e block:*
B) strace -e trace=io
C) bpftrace -e 'kprobe:blk_account_io_done { @usecs = hist(nsecs / 1000); }'
D) iostat -x 1
```

### Question 10
What does the `direct=1` option do in `fio`?
```
A) Enables direct memory access
B) Bypasses the page cache, using O_DIRECT
C) Directs output to a file
D) Runs the test in the background
```

### Question 11
What is the primary benefit of using `noatime` as a filesystem mount option?
```
A) It disables all disk write operations
B) It prevents access time updates on reads, reducing write operations
C) It enables faster directory lookups
D) It disables journaling for improved performance
```

### Question 12
In the CFS scheduler, what does a lower vruntime mean for a task?
```
A) It has run longer and is less entitled to CPU time
B) It has run less and is more entitled to CPU time
C) It is a real-time task with higher priority
D) It is an I/O-bound task that should sleep longer
```

### Question 13
What is direct reclaim in Linux memory management?
```
A) kswapd freeing pages in the background
B) A process that is allocating memory is forced to wait and reclaim pages synchronously
C) The OOM killer selecting a process to terminate
D) Reclaiming memory by dropping page cache entries
```

### Question 14
Which netfilter/NAPI parameter controls how many packets are processed per softirq poll cycle?
```
A) net.core.somaxconn
B) net.core.netdev_budget
C) net.ipv4.tcp_rmem
D) net.core.rmem_default
```

### Question 15
What is the key difference between HDD and NVMe tuning?
```
A) HDDs need `none` scheduler; NVMe needs `mq-deadline`
B) HDDs benefit from lower queue depth; NVMe benefits from much higher queue depth
C) NVMe requires read-ahead to be disabled; HDDs require it enabled
D) There is no difference in tuning approach
```

---

**Score:** 12/15 correct = ready for Part 48.

**Answers:** 1-B, 2-C, 3-B, 4-C, 5-B, 6-B, 7-B, 8-B, 9-C, 10-B, 11-B, 12-B, 13-B, 14-B, 15-B

---

*Previous → Part 46: Monitoring and Alerting*
*Next → Part 48: High Availability and Clustering*

[← Previous](part46.md) | [Next →](part48.md)


---

[← Previous](20-whats-coming-in-part-48.md) | [↑ Index](index.md)
