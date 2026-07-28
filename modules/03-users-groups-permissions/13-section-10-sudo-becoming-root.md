## 🔍 Section 10: sudo — Becoming Root Safely

The `sudo` command lets authorized users run commands as root (or other users) without knowing the root password.

### How sudo Works

```bash
sudo whoami
# root

sudo -u alice whoami
# alice
```

### Viewing Your Sudo Privileges

```bash
sudo -l
# Lists all commands you are allowed to run
```

### The /etc/sudoers File

```bash
sudo visudo   # ALWAYS use visudo, never edit directly
```

`visudo` locks the file, validates syntax on save, and prevents you from locking yourself out.

### Sudoers Syntax

```
who    where=(whom)  commands
alice  ALL=(ALL)     ALL
```

| Field | Meaning |
|-------|---------|
| `who` | User or group (use `%groupname` for groups) |
| `where` | Which hosts this applies to (`ALL` = any) |
| `(whom)` | Which user they can run commands as |
| `commands` | Which commands (`ALL` = any) |

### Real Sudoers Examples

```bash
# Give alice full sudo access
alice ALL=(ALL) ALL

# Give everyone in 'sudo' group full access
%sudo ALL=(ALL) ALL

# Give bob permission to only restart the web server
bob ALL=(root) /usr/bin/systemctl restart nginx, /usr/bin/systemctl status nginx

# Give developers group permission to run package updates without password
%developers ALL=(root) NOPASSWD: /usr/bin/apt update, /usr/bin/apt upgrade

# Give alice permission to run as any user EXCEPT root
alice ALL=(ALL, !root) ALL

# Run only specific commands as specific users
bob ALL=(dbadmin) /usr/bin/psql
```

### Important sudo Options

```bash
# Run as different user
sudo -u postgres psql

# Run as root but keep current environment
sudo -E ./script.sh

# Start a shell as root
sudo -s          # Root shell with current dir and env
sudo -i          # Root shell with root's environment (login shell)

# Edit a file safely (uses your $EDITOR)
sudo -e /etc/hosts
```

> 🚨 **Security Rule:** Grant the least privilege needed. Never give `ALL=(ALL) ALL` to anyone unless absolutely necessary. Use specific commands.





[← Previous](12-section-9-group-management-commands.md) | [↑ Index](index.md) | [Next →](14-level-3-advanced-advanced-access.md)
