## 📝 Self-Test — Can You Answer These?

1. What is the difference between DAC and MAC?
2. What are the three modes of SELinux?
3. What does `getenforce` show and what are the possible outputs?
4. What is an SELinux "context" and what are its four components?
5. What command restores SELinux file contexts to their defaults?
6. What is an SELinux boolean and how do you make the change permanent?
7. How do you check the SELinux context of a running process?
8. What are the two modes of AppArmor?
9. Where are AppArmor profiles stored?
10. How does AppArmor profile syntax differ from SELinux policy?
11. What command checks AppArmor status?
12. How do you find SELinux denials in the audit log?
13. What does `audit2allow` do?
14. Why does moving a file sometimes break SELinux but copying does not?
15. What is the `restorecon` command used for?

**Score:** 12/15 correct = ready for Part 18.


## Answer Key

### Q1: What is the difference between DAC and MAC?
**Answer:** DAC (Discretionary Access Control) — file owners control permissions. MAC (Mandatory Access Control) — system-wide policy applies to all, including root (SELinux/AppArmor).

### Q2: What are the three modes of SELinux?
**Answer:** Enforcing (policy enforced), Permissive (logged but not enforced), Disabled (SELinux turned off).

### Q3: What does `getenforce` show?
**Answer:** Shows the current SELinux mode: `Enforcing`, `Permissive`, or `Disabled`.

### Q4: What is an SELinux context and what are its four components?
**Answer:** `user:role:type:level` — e.g., `unconfined_u:object_r:httpd_sys_content_t:s0`. Type is the primary access control field.

### Q5: What command restores SELinux file contexts to their defaults?
**Answer:** `restorecon -Rv /path` — recursively restores contexts based on policy.

### Q6: What is an SELinux boolean and how do you make the change permanent?
**Answer:** A boolean is a toggle for common policy settings. Make permanent: `setsebool -P httpd_can_network_connect on`.

### Q7: How do you check the SELinux context of a running process?
**Answer:** `ps auxZ | grep process-name` — the `Z` flag shows context.

### Q8: What are the two modes of AppArmor?
**Answer:** Enforce (actively blocks) and Complain (logs violations without blocking).

### Q9: Where are AppArmor profiles stored?
**Answer:** `/etc/apparmor.d/` — each profile is a text file defining allowed capabilities and file access.

### Q10: How does AppArmor profile syntax differ from SELinux?
**Answer:** AppArmor uses path-based rules (deny/allow `/var/www/**`). SELinux uses type-based rules with contexts. AppArmor is simpler but less flexible.

### Q11: What command checks AppArmor status?
**Answer:** `aa-status` — shows loaded profiles and their mode.

### Q12: How do you find SELinux denials in the audit log?
**Answer:** `ausearch -m avc` or `audit2why < /var/log/audit/audit.log` — explains denial reasons.

### Q13: What does `audit2allow` do?
**Answer:** Generates SELinux policy modules from audit log denials to permit specific denied actions.

### Q14: Why does moving a file sometimes break SELinux but copying does not?
**Answer:** Moving preserves the original context. Copying applies the destination directory's default context. `mv` keeps the source label; `cp` applies the target's label.

### Q15: What is the `restorecon` command used for?
**Answer:** Resets file contexts to their policy-defined defaults. Essential after moving files or correcting mislabeled contexts.


[← Previous](17-whats-coming-in-part-18.md) | [↑ Index](index.md)
