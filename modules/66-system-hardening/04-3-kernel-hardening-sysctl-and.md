## 3. Kernel Hardening — sysctl and Beyond

### ASLR (Address Space Layout Randomization)

```bash
# Check current ASLR setting
cat /proc/sys/kernel/randomize_va_space
# 0 = Disabled, 1 = Partial (mmap), 2 = Full (stack + heap + mmap) ← recommended

# Enable full ASLR
sysctl -w kernel.randomize_va_space=2

# Make persistent
echo "kernel.randomize_va_space = 2" >> /etc/sysctl.d/99-hardening.conf
```

### Stack Protector and NX Bit

```bash
# Verify kernel compiled with stack protector
grep -i stack_protector /boot/config-$(uname -r)
# CONFIG_CC_STACKPROTECTOR=y
# CONFIG_CC_STACKPROTECTOR_STRONG=y

# Verify NX (No-Execute) support
grep -i nx /proc/cpuinfo | head -1
# flags: nx            ← present if CPU supports NX
```

### Kernel Lockdown Mode (Linux 5.4+)

```bash
# Three modes: none, integrity, confidentiality
# integrity: blocks unsigned kernel modules, /dev/mem writes
# confidentiality: also blocks reading kernel memory

# Set via boot parameter (recommended method)
sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="lsm=lockdown /' /etc/default/grub
update-grub

# Or set at runtime (requires boot param for next reboot)
cat /sys/kernel/security/lockdown
# [none] integrity confidentiality
```

### Comprehensive sysctl Hardening

```bash
cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
# === Network Hardening ===
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_ra = 0

# === Kernel Hardening ===
kernel.randomize_va_space = 2
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1

# === Filesystem Hardening ===
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

# Apply all settings
sysctl -p /etc/sysctl.d/99-hardening.conf
```

> 🔍 **Reverse Engineering Insight:** `kptr_restrict = 2` prevents even root from reading `/proc/kallsyms` without CAP_SYSLOG, closing a kernel infoleak that rootkits exploit to find function addresses for hooking.

### Module Signing Enforcement

```bash
# Check if module signing is enabled
grep MODULE_SIG /boot/config-$(uname -r)
# CONFIG_MODULE_SIG=y
# CONFIG_MODULE_SIG_FORCE=y     ← rejects unsigned modules

# Verify a module's signature
modinfo -F signer /lib/modules/$(uname -r)/kernel/drivers/net/e1000/e1000.ko
```





[← Previous](03-2-cis-benchmarks-the-security.md) | [↑ Index](index.md) | [Next →](05-4-filesystem-hardening.md)
