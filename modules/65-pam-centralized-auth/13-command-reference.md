## Command Reference

| Task | Command |
|------|---------|
| List PAM config files | `ls /etc/pam.d/` |
| View PAM config | `cat /etc/pam.d/<service>` |
| Check faillock status | `faillock --user <user>` |
| Reset faillock | `faillock --user <user> --reset` |
| List PAM modules | `find /usr/lib64/security/ -name "pam_*.so"` |
| Set password aging | `chage -M 90 -m 7 -W 14 <user>` |
| View password aging | `chage -l <user>` |
| Force password change | `chage -d 0 <user>` |
| Check password policy | `cat /etc/security/pwquality.conf` |
| SSSD domain status | `sssctl domain-status <domain>` |
| SSSD cache expire | `sss_cache -E` |
| Authselect current | `authselect current` |
| Authselect select profile | `authselect select sssd --force` |
| Authselect enable feature | `authselect enable-feature with-faillock` |
| Authselect backup | `authselect backup /path/backup` |
| Authselect restore | `authselect restore /path/backup` |
| Create custom profile | `authselect create-profile myprofile -b sssd` |
| Test LDAP connectivity | `ldapsearch -x -H ldaps://server -b "dc=ex,dc=com" -D "bind-dn" -W` |
| LDAP whoami | `ldapwhoami -x -H ldaps://server -D "bind-dn" -W` |
| View SSSD debug logs | `tail -f /var/log/sssd/sssd_<domain>.log` |
| Join FreeIPA | `ipa-client-install --domain=... --server=... --realm=...` |
| Join Active Directory | `realm join --user=administrator example.com` |
| Audit PAM changes | `ausearch -k pam_config_change -ts recent` |
| View failed logins | `lastb \| head -20` |
| Check PAM-loaded modules | `cat /proc/<pid>/maps \| grep pam_` |
| SSSD user status | `sssctl user-status <user>` |
| Google Authenticator setup | `google-authenticator` (as target user) |
| PAM session logging | `pam_exec.so /path/to/script.sh` |
| Test PAM manually | `pamtester <service> <user> authenticate` |

---



---

[← Previous](12-deep-understanding.md) | [↑ Index](index.md) | [Next →](14-whats-coming-in-part-66.md)
