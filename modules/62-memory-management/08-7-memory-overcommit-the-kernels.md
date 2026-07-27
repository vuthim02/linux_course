## 7. Memory Overcommit — The Kernel's Gamble

### What Is Overcommit?

The kernel may allow more virtual memory allocation than physical + swap. This is called **overcommit**:

```bash
# View overcommit settings
cat /proc/sys/vm/overcommit_memory
# 0 = heuristic (default, guesses if there's enough)
# 1 = always (no checks, allocate freely)
# 2 = never (strict limit based on overcommit_ratio)

cat /proc/sys/vm/overcommit_ratio
# 50  (percentage of physical + swap to allow for overcommit)

cat /proc/sys/vm/overcommit_kbytes
# 0  (alternative: fixed bytes instead of ratio)

# Current overcommit status
grep -E "CommitLimit|Committed_AS" /proc/meminfo
# CommitLimit:    24576000 kB   (physical + swap × overcommit_ratio)
# Committed_AS:   20480000 kB   (total memory committed by processes)

# If Committed_AS > CommitLimit, the system is overcommitted
```

### Overcommit Strategies

```
┌──────────────────────────────────────────────────────────────┐
│              OVERCOMMIT STRATEGIES                            │
│                                                                │
│  overcommit_memory = 0 (HEURISTIC - DEFAULT)                  │
│  ┌─────────────────────────────────────────────────────┐      │
│  │ Kernel estimates if allocation is "reasonable"       │      │
│  │ - Small allocations: allowed                         │      │
│  │ - Large allocations: denied if looks dangerous       │      │
│  │ - Best for: general purpose servers                  │      │
│  │ - Risk: some OOM kills possible                      │      │
│  └─────────────────────────────────────────────────────┘      │
│                                                                │
│  overcommit_memory = 1 (ALWAYS)                               │
│  ┌─────────────────────────────────────────────────────┐      │
│  │ No overcommit checks — allocate freely               │      │
│  │ - Best for: scientific computing, VMs with tmpfs     │      │
│  │ - Risk: guaranteed OOM kills possible                │      │
│  │ - Use when: you know what you're doing               │      │
│  └─────────────────────────────────────────────────────┘      │
│                                                                │
│  overcommit_memory = 2 (NEVER)                                │
│  ┌─────────────────────────────────────────────────────┐      │
│  │ Strict limit: physical RAM × overcommit_ratio%       │      │
│  │ - Best for: databases, real-time systems             │      │
│  │ - Risk: allocations may fail even with free memory   │      │
│  │ - Safe: guarantees no OOM from overcommit            │      │
│  └─────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

```bash
# Set overcommit strategy
sudo sysctl vm.overcommit_memory=0     # Heuristic (default)
sudo sysctl vm.overcommit_memory=1     # Always
sudo sysctl vm.overcommit_memory=2     # Never (strict)

# Set overcommit ratio (used with mode 2)
sudo sysctl vm.overcommit_ratio=80     # 80% of RAM + swap
# With 32GB RAM + 8GB swap: limit = 40GB × 80% = 32GB

# For databases (mode 2 recommended):
echo "vm.overcommit_memory = 2" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.overcommit_ratio = 80" | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf

# For tmpfs (needs mode 1):
# tmpfs allocates RAM for its contents
# With mode 0, tmpfs may fail to mount if overcommit is near limit
sudo mount -t tmpfs -o size=16G tmpfs /mnt/ramdisk
# This needs overcommit_memory=1 or enough free RAM
```

### Testing Overcommit

```bash
# Test overcommit behavior
cat << 'EOF' > /tmp/test_overcommit.c
#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>

int main() {
    // Try to allocate 90% of RAM
    size_t size = 29ULL * 1024 * 1024 * 1024;  // 29GB on 32GB system
    void *ptr = mmap(NULL, size, PROT_READ|PROT_WRITE,
                     MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    if (ptr == MAP_FAILED) {
        printf("mmap FAILED (overcommit prevented allocation)\n");
        return 1;
    }
    printf("mmap SUCCEEDED (address: %p)\n", ptr);
    // Actually touch the memory to trigger OOM
    // char *p = (char *)ptr;
    // for (size_t i = 0; i < size; i += 4096) p[i] = 'A';  // Would OOM
    munmap(ptr, size);
    return 0;
}
EOF
gcc -o /tmp/test_overcommit /tmp/test_overcommit.c
/tmp/test_overcommit
```

> 🔍 **Reverse Engineering Insight:** `overcommit_memory=1` is a common cause of mysterious OOM kills in production. The kernel allows a process to mmap() terabytes of virtual memory, but when it tries to actually use that memory, there's nothing physical available. Use `overcommit_memory=2` for databases and any process that needs guaranteed memory availability.

---



---

[← Previous](07-6-oom-killer-last-resort.md) | [↑ Index](index.md) | [Next →](09-8-diagnosing-memory-pressure.md)
