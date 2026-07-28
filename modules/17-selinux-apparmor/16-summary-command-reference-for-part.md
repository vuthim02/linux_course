## 📋 Summary — Command Reference for Part 17

### Level 1 — Basic MAC Commands

| Command | Action |
|---------|--------|
| `getenforce` | Show current SELinux mode |
| `setenforce 0\|1` | Set permissive (0) or enforcing (1) |
| `sestatus` | Full SELinux status and policy info |
| `ls -Z FILE` | Show file context |
| `ps -Z` | Show process contexts |
| `id -Z` | Show current user/role/type context |
| `cat /etc/selinux/config` | View permanent SELinux configuration |

### Level 2 — Intermediary Configuration and Daily Use

| Command | Action |
|---------|--------|
| `restorecon -Rv DIR` | Restore default file contexts recursively |
| `chcon -t TYPE FILE` | Change file context type |
| `getsebool -a` | List all SELinux booleans |
| `setsebool -P BOOL on` | Set boolean persistently |
| `semanage fcontext -l` | List file context rules |
| `semanage boolean -l` | List booleans with descriptions |
| `semanage port -l` | List port contexts |
| `aa-status` | Show all AppArmor profiles |
| `aa-enforce PROG` | Set profile to enforce mode |
| `aa-complain PROG` | Set profile to complain mode |
| `aa-disable PROG` | Disable AppArmor profile |
| `systemctl reload apparmor` | Reload all AppArmor profiles |
| `cat /etc/apparmor.d/PROFILE` | View AppArmor profile contents |

### Level 3 — Advanced Troubleshooting and Policy Management

| Command | Action |
|---------|--------|
| `ausearch -m avc` | Search audit log for AVC denials |
| `audit2why` | Explain why a denial occurred |
| `audit2allow` | Generate a policy module from denial |
| `semodule -i MOD.pp` | Install a custom policy module |
| `semodule -l` | List all loaded policy modules |
| `semodule -r MOD` | Remove a policy module |
| `aa-genprof PROG` | Interactively generate AppArmor profile |
| `apparmor_parser -r PROFILE` | Reload a specific AppArmor profile |
| `semanage permissive -a TYPE` | Put a domain in permissive mode |





[← Previous](15-deep-understanding-how-mac-really.md) | [↑ Index](index.md) | [Next →](17-whats-coming-in-part-18.md)
