## ✅ Self-Test

**Score:** 15/15 correct = ready for Part 50.

1. What are the three principles of the CIA triad? Give a real-world example of each.

2. Explain defense in depth. Why is a single firewall not enough?

3. What does the Lynis **hardening index** measure? What is a reasonable target score?

4. Write the command to run a Lynis audit and save the output to a file.

5. What is the difference between XCCDF, OVAL, and CPE in the SCAP standard?

6. Write an auditctl rule to watch `/etc/shadow` for write and attribute changes, with key `shadow_mon`.

7. After adding an audit rule, how do you search the log for events matching that rule?

8. What is the purpose of `kernel.randomize_va_space = 2`? Explain what happens at each value (0, 1, 2).

9. Explain the difference between `chattr +i` and `chattr +a`. When would you use each?

10. In SELinux, what do each of the four fields in `unconfined_u:object_r:httpd_sys_content_t:s0` mean?

11. What is the difference between `aa-enforce` and `aa-complain`? When should you use each?

12. Write the sshd_config directives needed to disable root login and require SSH keys only.

13. What is the role of the `kauditd` kernel thread? How does it communicate with `auditd`?

14. What is the difference between DAC and MAC? Give one example of each.

15. Your boss asks you to "harden the company's production web server." List the 5 most impactful changes you would make, in order of priority.

**Answers:**

**1.** Confidentiality (only authorized access — file permissions 600 on /etc/shadow), Integrity (data not tampered — AIDE checksums), Availability (system is up — RAID, backups, failover cluster).

**2.** Defense in depth layers multiple independent security controls. A firewall alone is not enough because: (a) an insider can bypass it, (b) a compromised web app can be attacked through allowed ports (80/443), (c) zero-day exploits bypass known rules. You need firewalls + SELinux + auditd + AIDE + PAM + SSH hardening + regular patching.

**3.** The hardening index (0-100) measures how well the system is secured based on hundreds of individual tests. A score of 60-80 is reasonable for a general-purpose server; 80+ is well-hardened.

**4.** `sudo lynis audit system | tee /tmp/lynis-audit.log`

**5.** XCCDF = checklist/benchmark format (what to check); OVAL = language for checking system state (how to check); CPE = platform identification (what system this applies to).

**6.** `sudo auditctl -w /etc/shadow -p wa -k shadow_mon`

**7.** `sudo ausearch -k shadow_mon -i`

**8.** `kernel.randomize_va_space`: 0 = ASLR disabled (all addresses predictable); 1 = randomize stack, libraries, mmap; 2 = full randomization including brk/heap base. Value 2 provides maximum protection against buffer overflow attacks.

**9.** `chattr +i` (immutable) — file cannot be modified, deleted, renamed, or linked, even by root. Use for critical config files like `/etc/passwd`, `/etc/sudoers`. `chattr +a` (append-only) — file can only be opened for appending. Use for log files like `/var/log/auth.log` so logs cannot be deleted or overwritten, only appended.

**10.** `unconfined_u` = SELinux user; `object_r` = role; `httpd_sys_content_t` = type (the primary access control attribute); `s0` = MLS sensitivity level.

**11.** `aa-enforce` actively blocks actions not in the profile (production use). `aa-complain` logs violations but allows them (testing/development — used to build and refine a profile before enforcing).

**12.** ```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
```

**13.** `kauditd` is a kernel thread that generates audit records when syscalls match audit rules. It communicates with `auditd` via a netlink socket (AF_NETLINK, NETLINK_AUDIT) — a special socket type for kernel-to-userspace communication.

**14.** DAC (Discretionary Access Control) — file owners set permissions; root can override. Example: `chmod 600 file`. MAC (Mandatory Access Control) — system policy applies to all, including root. Example: SELinux type enforcement prevents `httpd_t` from writing to `/etc/shadow` even if DAC says yes.

**15.** Priority order: (1) Harden SSH — disable root login, require keys; (2) Set up firewall — deny all inbound except ports 80, 443, 22; (3) Enable automatic security updates; (4) Enable auditd and AIDE to detect and log changes; (5) Apply kernel hardening parameters (ASLR, kptr_restrict, etc.) and SELinux/AppArmor enforcing.





[← Previous](19-whats-coming-in-part-50.md) | [↑ Index](index.md) | [Next →](21-course-progress-whats-ahead.md)
