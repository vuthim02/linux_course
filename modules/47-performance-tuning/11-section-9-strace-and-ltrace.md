## 🔍 Section 9: strace and ltrace

### strace — System Call Tracing

Traces every system call a process makes:

```bash
# Trace a command's syscalls
strace ls

# Show only specific syscalls
strace -e trace=open,read,write ls

# Show a summary (count, time, errors per syscall)
strace -c ls

# Attach to a running process
strace -p 1234

# Follow child processes (forks)
strace -f -c nginx

# Timestamps and relative times
strace -r ls         # relative timestamps
strace -T ls         # syscall duration

# Output to file
strace -o /tmp/strace.out -p 1234
```

**Identifying slow syscalls:**

```bash
# Find syscalls taking longer than 1 ms
strace -T -e trace=all 2>&1 ./slowapp | grep "<0.00[1-9]"

# Summarize the slowest
strace -c -w ./slowapp   # -w = summarize wall-clock time

# Common performance-draining syscalls:
# - read()/write() on slow I/O
# - poll()/select()/epoll_wait() with long timeouts
# - open()/stat() on many small files
# - mmap()/munmap() frequent allocations
```

**Practical example — find what's slowing a web request:**

```bash
# Attach to an nginx worker
sudo strace -p $(pgrep -o nginx) -e trace=network -T 2>&1 | head -50

# Or Apache
sudo strace -p $(pgrep httpd | head -1) -e trace=file -T 2>&1 | head -50
```

### ltrace — Library Call Tracing

Traces calls to dynamically linked library functions:

```bash
# Trace library calls
ltrace ls

# With summary
ltrace -c ls

# Attach to process
ltrace -p 1234

# Filter specific library
ltrace -e strcmp+ ./myapp
```

---



---

[← Previous](10-section-8-perf-linux-profiler.md) | [↑ Index](index.md) | [Next →](12-section-10-systemtap-and-bpftrace.md)
