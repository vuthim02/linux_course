## 📋 Summary — Complete Command Reference

### Security Auditing Tools

| Command | Purpose | Example |
|---------|---------|---------|
| `lynis audit system` | Run Lynis security audit | `sudo lynis audit system` |
| `lynis show categories` | Show Lynis test categories | `sudo lynis show categories` |
| `oscap xccdf eval` | Run SCAP compliance scan | `sudo oscap xccdf eval --profile cis --results r.xml --report r.html content.xml` |
| `oscap info` | Display SCAP content info | `oscap info ssg-rhel9-ds.xml` |
| `oscap xccdf generate fix` | Generate remediation script | `oscap xccdf generate fix --profile cis --fix-type bash content.xml` |

### Auditd

| Command | Purpose | Example |
|---------|---------|---------|
| `auditctl -l` | List active audit rules | `sudo auditctl -l` |
| `auditctl -w path -p rwxa -k key` | Watch file/directory | `sudo auditctl -w /etc/passwd -p wa -k passwd_changes` |
| `auditctl -a always,exit -S syscall` | Watch system call | `sudo auditctl -a always,exit -F arch=b64 -S execve -k exec` |
| `auditctl -D` | Delete all rules | `sudo auditctl -D` |
| `ausearch -k key` | Search audit log by key | `sudo ausearch -k passwd_changes` |
| `ausearch -au uid` | Search by user ID | `sudo ausearch -au 1000` |
| `ausearch -ts start -te end` | Search by time range | `sudo ausearch -ts 10:00:00 -te 11:00:00` |
| `ausearch -i` | Interpret output (UIDs→names) | `sudo ausearch -k passwd_changes -i` |
| `aureport --summary` | Generate summary report | `sudo aureport --summary` |
| `aureport -au` | Authentication report | `sudo aureport -au` |
| `aureport -x` | Executable report | `sudo aureport -x` |
| `aureport -f` | File access report | `sudo aureport -f` |
| `aureport -l` | Login report | `sudo aureport -l` |

### File Integrity

| Command | Purpose | Example |
|---------|---------|---------|
| `aideinit` | Initialize AIDE database | `sudo aideinit` |
| `aide --check` | Run AIDE integrity check | `sudo aide --check` |
| `aide --update` | Update AIDE database | `sudo aide --update` |
| `ossec-check` | Run OSSEC integrity check | `sudo /var/ossec/bin/ossec-check` |

### AppArmor

| Command | Purpose | Example |
|---------|---------|---------|
| `aa-status` | Show AppArmor status | `sudo aa-status` |
| `aa-enforce profile` | Set profile to enforce | `sudo aa-enforce /usr/sbin/nginx` |
| `aa-complain profile` | Set profile to complain | `sudo aa-complain /usr/sbin/nginx` |
| `aa-disable profile` | Disable profile | `sudo aa-disable /usr/sbin/nginx` |
| `aa-genprof binary` | Generate new profile | `sudo aa-genprof /usr/bin/custom-app` |
| `aa-logprof` | Review log and update profile | `sudo aa-logprof` |

### SELinux

| Command | Purpose | Example |
|---------|---------|---------|
| `getenforce` | Show current SELinux mode | `getenforce` |
| `setenforce 0\|1` | Set permissive/enforcing | `sudo setenforce 1` |
| `getsebool -a` | List all booleans | `getsebool -a` |
| `setsebool -P bool on` | Set boolean persistently | `sudo setsebool -P httpd_can_network_connect on` |
| `ls -Z` | Show file context | `ls -Z /etc/passwd` |
| `ps -Z` | Show process context | `ps -Z $(pgrep httpd)` |
| `chcon -t type file` | Change file context | `sudo chcon -t httpd_sys_content_t /var/www/index.html` |
| `restorecon -Rv dir` | Restore default context | `sudo restorecon -Rv /var/www` |
| `semanage fcontext -l` | List file context defaults | `sudo semanage fcontext -l` |
| `audit2allow -a` | Generate allow rules from log | `sudo audit2allow -a -M mymodule` |
| `audit2why` | Explain SELinux denials | `sudo ausearch -m AVC -ts today | audit2why` |

### Filesystem Security

| Command | Purpose | Example |
|---------|---------|---------|
| `find / -perm -4000 -type f` | Find SUID binaries | `sudo find / -perm -4000 -type f` |
| `find / -perm -2000 -type f` | Find SGID binaries | `sudo find / -perm -2000 -type f` |
| `chmod +t dir` | Set sticky bit | `sudo chmod +t /shared` |
| `chattr +i file` | Make file immutable | `sudo chattr +i /etc/passwd` |
| `chattr +a file` | Make file append-only | `sudo chattr +a /var/log/auth.log` |
| `lsattr file` | List file attributes | `lsattr /etc/passwd` |

### Kernel Hardening

| Command | Purpose | Example |
|---------|---------|---------|
| `sysctl -a` | List all kernel parameters | `sysctl -a | grep kernel` |
| `sysctl --system` | Apply all sysctl files | `sudo sysctl --system` |
| `sysctl -w param=value` | Set parameter temporarily | `sudo sysctl -w kernel.randomize_va_space=2` |

### Network Security

| Command | Purpose | Example |
|---------|---------|---------|
| `ss -tlnp` | List TCP listening ports | `sudo ss -tlnp` |
| `ss -ulnp` | List UDP listening ports | `sudo ss -ulnp` |
| `ufw enable` | Enable UFW firewall | `sudo ufw --force enable` |
| `nft list ruleset` | List nftables rules | `sudo nft list ruleset` |
| `nmap -sV -sC target` | Service/version scan | `nmap -sV -sC localhost` |

### System Information for Auditing

| Command | Purpose | Example |
|---------|---------|---------|
| `lastb` | Show failed login attempts | `lastb \| head -20` |
| `last` | Show last logins | `last \| head -20` |
| `w` | Who is logged in | `w` |
| `journalctl -p err -b` | System errors since boot | `journalctl -p err -b` |





[← Previous](17-deep-understanding.md) | [↑ Index](index.md) | [Next →](19-whats-coming-in-part-50.md)
