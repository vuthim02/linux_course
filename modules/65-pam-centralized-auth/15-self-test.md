## Self-Test

1. What are the four PAM module types and what does each one handle?
2. What is the difference between `required` and `requisite` control flags?
3. Why does PAM use `required` instead of `requisite` for password checks (hint: enumeration)?
4. What file does PAM read when `sshd` calls `pam_authenticate()`?
5. What is the purpose of `pam_faillock.so` and how does it differ from the deprecated `pam_tally2.so`?
6. What does `try_first_pass` do vs `use_first_pass` in pam_unix?
7. What are the key components of the SSSD architecture (responders and providers)?
8. Why does `/etc/sssd/sssd.conf` need permissions 0600?
9. What is the purpose of `ldap_default_bind_dn` in SSSD configuration?
10. How does SSSD handle offline authentication?
11. What is `authselect` and why did it replace `authconfig`?
12. What does the `with-faillock` feature do when enabled via authselect?
13. What is the danger of using `pam_permit.so` in an auth stack?
14. How do you reset a locked account managed by pam_faillock?
15. What logs should you check when debugging SSSD authentication failures?

**Answers:**
1. auth (identity verification), account (validity checks), password (password changes), session (setup/teardown)
2. `required` continues checking other modules on failure (delays failure message); `requisite` fails immediately
3. Delayed failure prevents attackers from determining whether a username exists (timing attack)
4. `/etc/pam.d/sshd` — the service name passed to `pam_authenticate()` maps to this file
5. pam_faillock tracks and locks accounts after N failures; pam_tally2 was deprecated due to race conditions and lack of audit support
6. `try_first_pass` uses the password from a previous module and re-prompts if it fails; `use_first_pass` uses it without re-prompting
7. Responders: nss, pam, ssh, sudo. Providers: id, auth, access, chpass, sudo, selinux, autofs
8. SSSD refuses to start with less restrictive permissions to protect LDAP/Kerberos credentials stored in the config
9. It is the DN of the service account used to bind (authenticate) to the LDAP directory for queries
10. SSSD caches credentials and user data in an ldb database; when LDAP is unreachable, it falls back to cached data
11. authselect manages PAM/NSS as profiles with predefined features, preventing manual edits that could break authentication
12. It enables pam_faillock for brute-force protection (deny after N attempts, auto-unlock after timeout)
13. pam_permit.so always succeeds, allowing anyone to authenticate without any checks — a critical security hole
14. `sudo faillock --user <username> --reset`
15. `/var/log/sssd/sssd_<domain>.log`, `/var/log/sssd/sssd_pam.log`, `/var/log/secure` or `/var/log/auth.log`, `journalctl -u sshd`

**Score:** 12/15 correct = ready for Part 66.

---

*Linux SysAdmin Course | Part 65 of ∞ | Reverse Engineering Approach*
*Previous → Part 64: Linux Namespaces*
*Next → Part 66: System Hardening*

[← Previous](part64.md) | [Next →](part66.md)


---

[← Previous](14-whats-coming-in-part-66.md) | [↑ Index](index.md)
