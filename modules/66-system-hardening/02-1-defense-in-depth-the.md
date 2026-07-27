## 1. Defense in Depth — The Layered Security Model

### The Core Principle

No single security measure is enough. Defense in depth stacks multiple independent controls so that breaching one layer still leaves the attacker facing others.

```
┌──────────────────────────────────────────────────────────────┐
│                    ATTACK SURFACE                             │
│                                                               │
│  Layer 1: PHYSICAL                                            │
│  ├─ BIOS/UEFI passwords                                      │
│  ├─ Full-disk encryption (LUKS)                               │
│  └─ Secure Boot                                               │
│                                                               │
│  Layer 2: NETWORK                                             │
│  ├─ Firewall rules (iptables/nftables/firewalld)              │
│  ├─ fail2ban                                                  │
│  ├─ Network segmentation                                      │
│  └─ TLS everywhere                                            │
│                                                               │
│  Layer 3: OS KERNEL                                           │
│  ├─ Kernel hardening (sysctl)                                 │
│  ├─ Module signing                                            │
│  ├─ Kernel lockdown                                           │
│  └─ Seccomp / AppArmor / SELinux                              │
│                                                               │
│  Layer 4: FILESYSTEM                                          │
│  ├─ Mount options (noexec, nosuid, nodev)                     │
│  ├─ File integrity monitoring (AIDE)                          │
│  ├─ Proper permissions (least privilege)                      │
│  └─ Encryption at rest                                        │
│                                                               │
│  Layer 5: USER / AUTHENTICATION                               │
│  ├─ Strong passwords / PAM policies                           │
│  ├─ SSH hardening                                             │
│  ├─ Multi-factor authentication                               │
│  └─ Least-privilege sudo                                      │
│                                                               │
│  Layer 6: APPLICATION                                         │
│  ├─ Minimal packages installed                                │
│  ├─ Non-root service accounts                                 │
│  ├─ Sandboxing (containers, namespaces)                       │
│  └─ Input validation                                          │
│                                                               │
│  Layer 7: MONITORING & RESPONSE                               │
│  ├─ auditd (syscall tracing)                                  │
│  ├─ logwatch / journald                                       │
│  ├─ AIDE (integrity)                                          │
│  ├─ Lynis (continuous assessment)                             │
│  └─ Incident response plan                                   │
└──────────────────────────────────────────────────────────────┘
```

### Attack Surface Reduction Checklist

```bash
# Audit installed packages — remove what you don't need
dpkg --audit -l | grep "^ii"       # Debian/Ubuntu
rpm -qa --qf '%{NAME}\n' | wc -l    # RHEL/CentOS

# List listening services
ss -tlnp
systemctl list-units --type=service --state=running

# List running SUID/SGID binaries
find / -xdev -perm -4000 -type f 2>/dev/null   # SUID
find / -xdev -perm -2000 -type f 2>/dev/null   # SGID

# List open kernel modules
lsmod | wc -l
```

> 🔍 **Reverse Engineering Insight:** The average Linux server runs 150+ services, but a hardened web server might need only 5. Every unnecessary service is an unpatched door. Attack surface reduction is the single most effective hardening step.

### Common Attack Vectors on Linux

| Vector | Countermeasure |
|--------|---------------|
| SSH brute force | fail2ban, key-only auth, non-standard port |
| Exploited web app | AppArmor/SELinux, non-root, chroot |
| Kernel vulnerability | Kernel lockdown, ASLR, patching |
| Privilege escalation | SUID audit, sudo hardening, least privilege |
| Persistence via cron | auditd rules, AIDE monitoring |
| Lateral movement | Network segmentation, firewall |
| Supply chain | Image scanning, signed packages |

---



---

[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-2-cis-benchmarks-the-security.md)
