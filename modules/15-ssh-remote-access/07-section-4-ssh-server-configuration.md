## 🔍 Section 4: SSH Server Configuration (sshd_config)

### Default Configuration

```bash
sudo cat /etc/ssh/sshd_config
```

```
Port 22
Protocol 2
PermitRootLogin yes        # ← CHANGE THIS
PubkeyAuthentication yes
PasswordAuthentication yes  # ← CHANGE THIS
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
```

### Security Hardening Checklist

```bash
sudo tee -a /etc/ssh/sshd_config << 'EOF'

# Security hardening
Port 2222                          # Change from default (reduces bot scanning)
PermitRootLogin prohibit-password  # Root can only login with key
PasswordAuthentication no          # Disable password auth (keys only)
PubkeyAuthentication yes           # Enable key auth
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3                     # Limit auth attempts
MaxSessions 10                     # Limit concurrent sessions
ClientAliveInterval 300            # Check client every 5 min
ClientAliveCountMax 2              # Disconnect after 2 missed checks
LoginGraceTime 60                  # Timeout for login (60 seconds)
AllowUsers alice bob               # Only these users can SSH (whitelist)
DenyUsers charlie                  # These users cannot SSH
AllowGroups ssh-users              # Only users in this group
EOF
```

### Important sshd_config Directives

| Directive | Default | Recommended | Purpose |
|-----------|---------|-------------|---------|
| Port | 22 | 2222 (or non-standard) | Reduce automated attacks |
| PermitRootLogin | yes | prohibit-password | Don't let root use password |
| PasswordAuthentication | yes | no | Keys only — no passwords |
| PubkeyAuthentication | yes | yes | Enable key authentication |
| MaxAuthTries | 6 | 3 | Limit brute force attempts |
| MaxSessions | 10 | 10 | Max concurrent SSH sessions |
| ClientAliveInterval | 0 | 300 | Check every 5 min if client lives |
| ClientAliveCountMax | 3 | 2 | Drop after 2 failed checks |
| LoginGraceTime | 120 | 60 | Time to complete login |
| AllowUsers | (none) | Specific users | Whitelist who can SSH |
| DenyUsers | (none) | Specific users | Blacklist users |
| AllowGroups | (none) | Specific groups | Group-based access control |

### Applying Changes

```bash
# Test configuration BEFORE restarting
sudo sshd -t

# If no errors, restart SSH
sudo systemctl restart sshd

# NEVER close your current session until you verify the new one works!
# Keep a second terminal open just in case.
```





[← Previous](06-level-2-intermediary-configuring-ssh.md) | [↑ Index](index.md) | [Next →](08-section-5-file-transfer-scp.md)
