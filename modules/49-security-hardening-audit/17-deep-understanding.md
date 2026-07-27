## 🧠 Deep Understanding

### How Linux Auditd Hooks Into the Kernel

The Linux Audit Framework operates at the **kernel level** through the following mechanism:

1. **System call interception**: When a syscall like `open()`, `execve()`, or `write()` is made, the kernel's syscall entry point checks whether audit rules are loaded.

2. **kauditd thread**: If a rule matches, the **kauditd** kernel thread generates an audit record containing:
   - Syscall number, arguments, return value
   - Process context (PID, UID, GID, SELinux context)
   - Security context (capabilities, LSM labels)
   - Timestamp and serial number

3. **Netlink socket**: kauditd sends the record to userspace via a **netlink socket** (protocol family `AF_NETLINK`, type `NETLINK_AUDIT`). This is a special socket type for kernel-userspace communication.

4. **auditd daemon**: The userspace `auditd` daemon reads from the netlink socket, formats the records, and writes them to `/var/log/audit/audit.log`.

5. **Audit dispatcher (audispd)**: `audispd` can forward audit events to other consumers (e.g., `ausearch`, SIEM systems, or custom scripts) via plugins in `/etc/audit/plugins.d/`.

```
Userspace:
  ┌──────────────────────────────────────┐
  │  auditd ← reads from netlink socket  │
  │    ↓ writes to /var/log/audit/*.log  │
  │  audispd → dispatches to plugins     │
  │  auditctl → sets rules via netlink   │
  └────────────┬─────────────────────────┘
               │ AF_NETLINK / NETLINK_AUDIT
Kernel:
  ┌────────────┴─────────────────────────┐
  │  syscall entry → audit_filter()      │
  │    ↓ if match                        │
  │  kauditd → build record              │
  │    ↓ send via netlink                │
  │  audit rules stored in kernel memory  │
  └──────────────────────────────────────┘
```

Key kernel source paths:
- `kernel/audit.c` — Core audit subsystem
- `kernel/auditsc.c` — Syscall auditing
- `kernel/auditfilter.c` — Rule matching
- `kernel/audit_watch.c` — File/directory watches (fanotify-based)

### How AIDE Builds and Compares File Hash Databases

AIDE works in two phases:

**Phase 1 — Database Creation (`aideinit`)**:

```
For each file/directory matching rules in aide.conf:
  1. stat() the file → get metadata (permissions, owner, size, mtime)
  2. Read the file → compute hashes:
     - SHA-256
     - SHA-512
     - RMD-160
     - MD5 (if configured)
     - Tiger (if configured)
  3. Store metadata + hashes in /var/lib/aide/aide.db
     (proprietary binary format, compressed)
```

**Phase 2 — Integrity Check (`aide --check`)**:

```
For each file/directory in aide.db:
  1. stat() the file → get current metadata
  2. Read the file → compute current hashes
  3. Compare against stored values:
     ┌──────────────┬──────────────┐
     │ Match?       │ Result       │
     ├──────────────┼──────────────┤
     │ All match    │ "ok"         │
     │ Metadata     │ "changed"    │
     │  changed     │ (report diff)│
     │ Hash changed │ "changed"    │
     │              │ (possible    │
     │              │  tampering)  │
     │ File missing │ "missing"    │
     │ New file     │ "added"      │
     │  (if rule    │              │
     │   allows)    │              │
     └──────────────┴──────────────┘
```

**Security notes**:
- The database file (`aide.db`) should be stored on **read-only media** (e.g., a mounted ISO or USB key) to prevent tampering.
- AIDE must be run from a **trusted environment** (e.g., single-user mode or from a live CD) for forensic-level integrity verification.
- AIDE uses the kernel's `audit_fill_sig` mechanism to verify its own binary has not been tampered with.

### How SELinux MLS/MCS Works

**MLS (Multi-Level Security)** and **MCS (Multi-Category Security)** extend SELinux with sensitivity labels:

**Security context format**:
```
user:role:type:sensitivity[:categories]

Example (MLS):
    john:user_r:user_t:s1:c1.c5,c10

Example (MCS — simplified MLS used by Docker, sVirt):
    system_u:system_r:svirt_t:s0:c98,c312
```

**MLS (Bell-LaPadula model)**:
- Each subject (process) has a **clearance level** (e.g., s0 = unclassified, s1 = secret, s2 = top_secret)
- Each object (file) has a **classification level**
- **No read up**: A subject at s1 cannot read an object at s2
- **No write down**: A subject at s2 cannot write to an object at s1

**MCS (simplified MLS)**:
- Adds categories (`c0` through `c1023`)
- Categories are orthogonal to levels — they represent compartments (e.g., `c100 = finance`, `c200 = HR`)
- A subject must have all of an object's categories to access it

```
                   MLS Level
                s2 (Top Secret)
                s1 (Secret)
                s0 (Unclassified)
                     │
       ┌─────────────┼─────────────┐
       c0     c1     c2 ...  c1023
       └──────────────────────────┘
             MCS Categories
```

**Docker/sVirt example**:
```
Container A: system_u:system_r:svirt_t:s0:c1,c2
Container B: system_u:system_r:svirt_t:s0:c3,c4
File A:      system_u:object_r:svirt_file_t:s0:c1,c2
File B:      system_u:object_r:svirt_file_t:s0:c3,c4
```
Container A can access File A (same categories) but not File B (different categories). This is how sVirt isolates container filesystems even if the processes escape.

### How LSM (Linux Security Module) Framework Works

The **Linux Security Module** framework is a kernel hook system that allows security modules (SELinux, AppArmor, Smack, Tomoyo, Yama) to intercept system calls **after** the standard DAC (Discretionary Access Control) check:

```
System call (e.g., open())
  │
  ▼
┌──────────────────────┐
│ 1. DAC Check         │ ← Standard Unix permissions
│    (uid/gid/mode)    │    If DENIED → return -EACCES
└──────────┬───────────┘
           │ PASS
           ▼
┌──────────────────────┐
│ 2. LSM Hook          │ ← Generic hook point
│    (security_*)       │    Called by kernel for every
│                       │    security-relevant operation
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 3. Specific Module   │ ← SELinux / AppArmor / etc.
│    Check             │    Makes MAC decision
│    (e.g., selinux_    │    If DENIED → return -EACCES
│     inode_permission)│
└──────────┬───────────┘
           │ PASS
           ▼
    Operation proceeds
```

**Key LSM hooks** (defined in `include/linux/security.h`):
```c
// File operations
security_file_permission()
security_inode_permission()
security_inode_create()
security_inode_unlink()

// Process operations
security_task_ptrace()
security_task_kill()
security_bprm_check()      // execve checks

// Network operations
security_socket_connect()
security_socket_bind()
security_socket_listen()

// System-wide
security_sb_mount()
security_kernel_module_from_file()
```

**The `CONFIG_LSM` kernel option** determines which modules are stacked:

```bash
# Check which LSMs are enabled
cat /sys/kernel/security/lsm
# Example output: "lockdown,capability,yama,apparmor"
# Example output: "lockdown,capability,yama,selinux"
```

**Module initialization flow**:
1. Kernel boots, calls `security_init()` for each module in `CONFIG_LSM` order
2. Each module initializes its own data structures (policy database, context caches)
3. Each module registers its hook functions in the global `security_hook_heads`
4. When a hook point is reached, the kernel iterates through stacked modules and calls each one's hook function
5. If any module returns an error, the operation is denied

### DAC vs MAC — The Fundamental Difference

| Aspect | DAC (Discretionary Access Control) | MAC (Mandatory Access Control) |
|--------|-----------------------------------|--------------------------------|
| **Who decides** | File owners set permissions | System policy (written by admin) |
| **Override** | Root can override anything | Even root is constrained |
| **Mechanism** | `rwx` bits, ACLs | SELinux types, AppArmor profiles |
| **Granularity** | Owner/group/other | Full process/file labeling |
| **Scope** | Files only | Files, processes, network, IPC, capabilities |
| **Bypass** | `sudo`, `chmod 777` | Only policy changes (require reload) |
| **Example** | `chmod 600 /etc/shadow` | `allow httpd_t httpd_log_t:file { write };` |

**DAC** is discretionary because the owner of a file decides who can access it. Root can always override.

**MAC** is mandatory because the system policy applies to everyone, including root. If the SELinux policy says Apache cannot write to `/etc/shadow`, then `httpd_t` cannot — even if the DAC permissions say `rw-rw-rw-`.

Both are needed: DAC first, then MAC as a safety net.

---



---

[← Previous](16-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](18-summary-complete-command-reference.md)
