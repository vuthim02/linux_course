## 🔍 Section 3: SSH Server

### Installing SSH Server

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install openssh-server

# Fedora/RHEL
sudo dnf install openssh-server

# Check status (sshd on RHEL/Fedora, ssh on Debian/Ubuntu)
sudo systemctl status sshd || sudo systemctl status ssh
```

### SSH Server Configuration

```bash
cat /etc/ssh/sshd_config
```

### Key Configuration Directives

| Directive | Purpose | Recommended |
|-----------|---------|-------------|
| `Port 22` | Which port to listen on | Change to non-standard (e.g., 2222) |
| `PermitRootLogin yes` | Allow root login | `no` or `prohibit-password` |
| `PasswordAuthentication yes` | Password login | `no` (use keys) |
| `PubkeyAuthentication yes` | Key login | `yes` |
| `AllowUsers user1 user2` | Limit users | Specify authorized users |
| `DenyUsers baduser` | Block users | Block unauthorized |
| `MaxAuthTries 6` | Max attempts | `3` |
| `ClientAliveInterval 300` | Check client alive | 300 seconds |
| `ClientAliveCountMax 3` | Max missed checks | 3 |
| `LoginGraceTime 120` | Time to login | 60 seconds |
| `Banner /etc/issue.net` | Pre-login banner | Legal warning |

### Harden SSH Configuration

```
# /etc/ssh/sshd_config — Security-hardened settings

Port 2222                          # Change default port

PermitRootLogin no                 # No direct root login
PasswordAuthentication no          # Key-based authentication only
PubkeyAuthentication yes           # Enable key auth

AllowUsers alice bob               # Explicit user whitelist
MaxAuthTries 3                     # Limit attempts
MaxSessions 2                      # Limit concurrent sessions

LoginGraceTime 60                  # 60 seconds to complete login
ClientAliveInterval 300            # Check every 5 minutes
ClientAliveCountMax 3              # Disconnect after ~15 min of inactivity

Banner /etc/issue.net              # Legal banner

# Use only strong key exchange algorithms
KexAlgorithms curve25519-sha256,diffie-hellman-group-exchange-sha256

# Log verbose
LogLevel VERBOSE
```

```bash
# After editing, restart
sudo systemctl restart sshd   # RHEL/Fedora; use "ssh" on Debian/Ubuntu

# Always verify config before restart
sudo sshd -t
```

### SSH Key Management

```bash
# Generate key pair (on client)
ssh-keygen -t ed25519 -C "your_email@example.com"
# Or: ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy public key to server
ssh-copy-id user@server-ip
# Or manually append to ~/.ssh/authorized_keys

# SSH with key
ssh user@server-ip

# SSH with non-standard port
ssh -p 2222 user@server-ip
```

### SSH Tunneling

```bash
# Local port forwarding
ssh -L 8080:internal-server:80 user@gateway

# Remote port forwarding
ssh -R 8080:localhost:80 user@public-server

# Dynamic forwarding (SOCKS proxy)
ssh -D 1080 user@server

# Example: Access a database through a jump server
ssh -L 3306:db.internal:3306 user@jump-server -N
```

### SSH in the Real World

SSH is not just for interactive logins. In production, SSH is the backbone of automation and secure tunnels:

```
Internet ──→ Bastion Host (Jump Box)
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
    Web Server  App Server  Database
    (port 22)   (port 22)  (no direct access)

# Common SSH patterns:
# 1. Jump host / Bastion — single entry point to a private network
# 2. Port forwarding — tunnel to databases without public IPs
# 3. SOCKS proxy — route all traffic through a secure tunnel
# 4. SSH config (~/.ssh/config) — manage complex multi-hop setups
```

```bash
# Jump host: connect through bastion
ssh -J bastion.example.com web.internal

# SSH config for jump host (~/.ssh/config)
Host internal-*
    ProxyJump bastion.example.com

# Tunnel to a database through a jump host
ssh -L 3306:db.internal:3306 bastion.example.com -N
```

### SSH Security Best Practices

```bash
# 1. Disable root login
# 2. Use key-based auth only
# 3. Change default port
# 4. Use fail2ban to block brute force
sudo apt install fail2ban          # Debian/Ubuntu
sudo dnf install fail2ban          # RHEL/Fedora (requires EPEL)
# Then configure /etc/fail2ban/jail.local with [sshd] section

# 5. Disable SSH protocol 1
# 6. Limit user access
# 7. Use SSH config file (~/.ssh/config)
cat ~/.ssh/config
Host myserver
    HostName 192.168.1.100
    Port 2222
    User alice
    IdentityFile ~/.ssh/id_ed25519
```





[← Previous](05-level-2-intermediary-ssh-and.md) | [↑ Index](index.md) | [Next →](07-section-4-network-service-management.md)
