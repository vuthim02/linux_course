## Section 8: Time Namespace and seccomp-bpf

### Time Namespace

Introduced in Linux 5.6. Allows per-namespace `CLOCK_MONOTONIC` and `CLOCK_BOOTTIME`.

```bash
# Use with unshare
unshare -T true                # Enter new time namespace
cat /proc/self/timens_offset   # View time offset

# In new time ns, boot time starts at 0
# All processes share the same time view

# Use case: container checkpoint/restore (CRIU)
# Ensures monotonic clock consistency after restore
```

### seccomp-bpf — Programmable Syscall Filtering

seccomp (SECure COMPuting) with BPF to filter system calls.

```bash
# Allow only read, write, exit, sigreturn
seccomp-tools dump ./mybin     # Dump seccomp filter
```

```c
// BPF filter example
struct sock_filter filter[] = {
    BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, nr)),
    // Allow read (0), write (1), exit(60), rt_sigreturn(15)
    BPF_JUMP(BPF_JMP | BPF_JEQ, 0, 4, 0),
    // ... more checks
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_KILL), // Default: kill
};
```

```bash
# Practical: Docker uses seccomp by default
# Default profile: /etc/containers/seccomp.json
docker run --security-opt seccomp=custom.json ubuntu

# With unshare
unshare --seccomp 0 ./sandbox   # No seccomp
unshare --seccomp 1 ./sandbox   # Default deny-all
```
