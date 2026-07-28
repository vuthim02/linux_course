## 🔍 Section 10: Kernel Hardening

### sysctl Security Settings

The kernel exposes many runtime parameters via `/proc/sys/`. Hardening them reduces the attack surface:

```bash
sudo tee /etc/sysctl.d/99-security-hardening.conf > /dev/null << 'EOF'
# /etc/sysctl.d/99-security-hardening.conf
# Kernel hardening parameters

# --- ASLR (Address Space Layout Randomization) ---
# 0 = disabled, 1 = randomize stack/library, 2 = full randomize (including brk)
kernel.randomize_va_space = 2

# --- Restrict kernel pointer exposure ---
# 0 = all kernel pointers visible to all
# 1 = only visible to privileged processes (CAP_SYSLOG)
# 2 = always hide (kptr_restrict introduced in kernel 4.x)
kernel.kptr_restrict = 2

# --- Restrict dmesg access ---
# 0 = any user can see kernel log
# 1 = only users with CAP_SYSLOG
kernel.dmesg_restrict = 1

# --- Disable unprivileged BPF (Berkeley Packet Filter) ---
# 0 = unprivileged users can create BPF (potential Spectre-variant attacks)
# 1 = only CAP_BPF or CAP_NET_ADMIN processes
kernel.unprivileged_bpf_disabled = 1

# --- Restrict ptrace scope ---
# 0 = any process can ptrace any other process (default for older kernels)
# 1 = only parent can ptrace child (restricted)
# 2 = only processes with CAP_SYS_PTRACE (admin only)
kernel.yama.ptrace_scope = 2

# --- Restrict perf events ---
# 0 = unprivileged, 1 = privileged only
kernel.perf_event_paranoid = 3

# --- Restrict kexec (used to boot into malicious kernel) ---
kernel.kexec_load_disabled = 1

# --- Disable SysRq (if not needed for debugging) ---
# kernel.sysrq = 0

# --- Core dump settings ---
# Do not follow symlinks when dumping core
fs.suid_dumpable = 0

# --- Restrict user namespace creation ---
# user.max_user_namespaces = 0   # Uncomment if namespaces are not needed
EOF

# Apply immediately
sudo sysctl --system

# Verify settings
sudo sysctl kernel.randomize_va_space kernel.kptr_restrict kernel.dmesg_restrict
```

### ASLR Deep Dive

**ASLR** randomizes the memory addresses where process components (stack, heap, libraries, mmap) are loaded. Without it, an attacker knows exactly where functions like `system()` live in libc (return-to-libc attacks).

```
Without ASLR:                     With ASLR:
┌─────────────────┐               ┌─────────────────┐
│ Stack: 0x7fff...│               │ Stack: 0x7f3a...│  ← different each run
│ Heap:  0x0060...│               │ Heap:  0x01c0...│
│ libc:  0x7f00...│               │ libc:  0x7f9b...│
│ ld.so: 0x7f10...│               │ ld.so: 0x7f8c...│
└─────────────────┘               └─────────────────┘
  (predictable)                      (randomized)
```

### grsecurity / PaX

**grsecurity** is a comprehensive kernel hardening patch set (commercial, requires subscription). **PaX** provides runtime code integrity (W^X — write XOR execute).

```bash
# Most distros do NOT include grsecurity in mainline kernels.
# To use it, you must:
# 1. Subscribe to grsecurity (https://grsecurity.net)
# 2. Obtain the patch for your kernel version
# 3. Apply patch and rebuild kernel

# Alternative: Use the linux-hardened kernel
# Arch Linux: pacman -S linux-hardened
# Gentoo: Enable hardened USE flag

# Check if your kernel has PaX:
grep -i pax /proc/config.gz 2>/dev/null || zcat /proc/config.gz 2>/dev/null | grep -i PAX
```





[← Previous](10-section-9-network-security.md) | [↑ Index](index.md) | [Next →](12-section-11-apparmor-selinux.md)
