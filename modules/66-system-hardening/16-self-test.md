## Self-Test

1. What are the three levels of CIS Benchmarks and who uses each?
2. What does `kernel.randomize_va_space = 2` enable and why does it matter?
3. What is the difference between `noexec`, `nosuid`, and `nodev` mount options?
4. Why should `/tmp` be on a separate tmpfs partition?
5. What is the purpose of auditd's `-e 2` rule and what happens when you use it?
6. How do you search audit logs for all events related to password file changes?
7. What is the difference between `audit2allow` and `audit2why`?
8. In fail2ban, what do `bantime`, `findtime`, and `maxretry` control?
9. Why should you never edit `/etc/fail2ban/jail.conf` directly?
10. What does Lynis score 67 vs 82 tell you about a system's security?
11. How does AIDE detect unauthorized file changes?
12. What must you do after running `apt upgrade` if AIDE is active?
13. What is the correct order to initialize and activate AIDE?
14. How does OpenSCAP differ from Lynis in purpose?
15. Why is defense in depth more effective than relying on a single hardening tool?

**Answers:**
1. Level I = minimum hygiene (all systems), Level II = defense in depth (servers), Level III = maximum hardening (classified/high-security)
2. Full ASLR — randomizes stack, heap, mmap, and VDSO addresses; prevents attackers from predicting memory layout for exploitation
3. `noexec` = prevent code execution, `nosuid` = ignore SUID/SGID bits, `nodev` = don't treat as device files
4. Separate tmpfs prevents /tmp from filling the root partition, enables noexec/nosuid/nodev, and is cleared on reboot (no persistent malware)
5. `-e 2` makes rules immutable — no changes possible until reboot; prevents attackers from deleting audit rules
6. `ausearch -k passwd_changes --start today` searches by key; `ausearch -f /etc/passwd` searches by file path
7. `audit2allow` generates SELinux policy modules to permit denied actions; `audit2why` explains the reason behind the denial
8. `bantime` = duration of ban, `findtime` = window to count failures, `maxretry` = failures before ban
9. `jail.conf` is overwritten on package upgrades; `jail.local` persists your customizations
10. 67 = moderate (some hardening done), 82 = very good (well-hardened with most controls in place)
11. AIDE computes cryptographic hashes (SHA256/512) of files at baseline, then re-computes and compares on each check
12. Run `aide --update` and copy `aide.db.new` to `aide.db` to accept legitimate changes as new baseline
13. `aide --init` (generate baseline) → `cp aide.db.new aide.db` (activate) → `aide --check` (verify)
14. OpenSCAP validates compliance against formal standards (CIS, STIG, PCI-DSS) with pass/fail per rule; Lynis provides security scoring with suggestions
15. Each tool covers different attack vectors; layered defense means if one control fails or is bypassed, others still provide protection

**Score:** 12/15 correct = ready for Part 67.


*Linux SysAdmin Course | Part 66 of ∞ | Reverse Engineering Approach*
*Previous → Part 65: PAM & Centralized Auth*
*Next → Part 67: Course Summary*

[← Previous](part65.md) | [Next →](part67.md)



[← Previous](15-whats-coming-in-part-67.md) | [↑ Index](index.md)
