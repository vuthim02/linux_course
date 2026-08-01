## 🔍 Section 12: SFTP Chroot and Restricted Shells

### SFTP Subsystem — internal-sftp vs sftp-server

```bash
# Default (separate binary):
Subsystem sftp /usr/lib/openssh/sftp-server

# Better: internal-sftp (built into sshd, no external binary)
Subsystem sftp internal-sftp
```

### Chroot SFTP Jail

Restrict an SFTP-only user to their home directory:

```bash
# 1. Create user and setup
sudo useradd -m -s /sbin/nologin sftp_user
sudo mkdir -p /home/sftp_user/uploads
sudo chown root:root /home/sftp_user
sudo chmod 755 /home/sftp_user
sudo chown sftp_user:sftp_user /home/sftp_user/uploads

# 2. /etc/ssh/sshd_config — at the END of file:
Match User sftp_user
    ChrootDirectory /home/sftp_user
    ForceCommand internal-sftp
    X11Forwarding no
    AllowTcpForwarding no
    PasswordAuthentication yes

# 3. Test
sftp sftp_user@localhost
# User is locked to /home/sftp_user — sees it as /
```

### Chroot SFTP for a Group

```bash
# Create a group for SFTP-only users
sudo groupadd sftp-only

# /etc/ssh/sshd_config:
Match Group sftp-only
    ChrootDirectory /home/sftp/%u
    ForceCommand internal-sftp
    X11Forwarding no
    AllowTcpForwarding no
    PasswordAuthentication no
    PubkeyAuthentication yes
```

### Chroot Directory Requirements

| Requirement | Why |
|-------------|-----|
| `ChrootDirectory` must be owned by **root** | Security: user must not control the chroot root |
| `ChrootDirectory` must not be writable by the user | Prevents privilege escalation |
| User's writable directories go **inside** the chroot | `mkdir uploads && chown user:user uploads` |

### Restricted Shell with ForceCommand

```bash
# Authorized_keys with command restriction
# In ~/.ssh/authorized_keys on the server:
command="/usr/local/bin/safe-script.sh" ssh-ed25519 AAAA...
# User can ONLY run that command, nothing else

# With restrict keyword (OpenSSH 7.2+)
restrict,command="/usr/local/bin/backup.sh" ssh-ed25519 AAAA...
# restrict disables: X11/tcp/agent forwarding, PTY allocation
```

### Match Blocks — Advanced Conditional Config

```bash
# /etc/ssh/sshd_config
Match User alice
    PasswordAuthentication no
    X11Forwarding yes

Match Group admins
    AllowTcpForwarding yes

Match Address 10.0.0.*
    MaxAuthTries 5

Match LocalAddress 192.168.1.1
    Port 2222

Match User bob,carol
    ForceCommand /usr/local/bin/monitor.sh

# Match rules are evaluated in order, FIRST match wins
# Place Match blocks at the END of sshd_config
```

### AuthorizedKeysCommand

Fetch authorized keys from a database or API instead of a file:

```bash
# /etc/ssh/sshd_config
AuthorizedKeysCommand /usr/local/bin/fetch-keys.sh
AuthorizedKeysCommandUser nobody

# /usr/local/bin/fetch-keys.sh
#!/bin/bash
# Fetch keys from an API or LDAP
curl -s "https://keys.example.com/users/$1" 2>/dev/null
```



[← Previous](20-section-11-proxyjump-and-bastion-hosts.md) | [↑ Index](index.md) | [Next →](22-section-13-ssh-certificates.md)
