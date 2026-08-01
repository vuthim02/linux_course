## 🔍 Section 11: ProxyJump and Bastion Hosts

A bastion (jump host) is a hardened server that sits between your workstation and internal servers.

### Jump Host Basics

```bash
# Traditional way (two steps)
ssh user@bastion.example.com
bastion$ ssh user@internal-server

# Modern way: ProxyJump (-J flag, OpenSSH 7.3+)
ssh -J user@bastion.example.com user@internal-server

# Multiple jumps
ssh -J jump1,jump2 user@target
```

### ~/.ssh/config with ProxyJump

```bash
# ~/.ssh/config
Host bastion
    HostName bastion.example.com
    User alice
    Port 22

Host internal-*
    User alice
    ProxyJump bastion
    ForwardAgent yes             # Required for key forwarding

# Now connect directly:
ssh internal-web01       # Automatically routes through bastion
```

### ProxyCommand (Legacy, Pre-OpenSSH 7.3)

```bash
# Older syntax (works with any SSH version)
Host internal-*
    User alice
    ProxyCommand ssh -W %h:%p bastion.example.com
    # -W forwards stdin/stdout to the target:port
```

### Bastion Hardening

```bash
# /etc/ssh/sshd_config on the bastion:
PermitRootLogin no
PasswordAuthentication no
AllowUsers alice bob            # Only specific users
AllowTcpForwarding yes          # Required for -J / -W
GatewayPorts no                 # Don't expose forwarded ports
ClientAliveInterval 60          # Drop idle connections

# Only allow SSH from bastion to internal network
# On internal servers:
sshd_config: AllowUsers alice@bastion.example.com
```

### SOCKS Proxy Through Bastion

```bash
# Create a SOCKS proxy on the bastion
ssh -D 1080 user@bastion.example.com

# Or tunnel through bastion to an internal server
ssh -J user@bastion -L 8080:internal-web:80 user@internal-web

# Persistent tunnel with autossh
autossh -M 0 -o "ProxyJump user@bastion" \
    -L 3306:db.internal:3306 user@db.internal
```



[← Previous](19-section-10-agent-forwarding-and-multiplexing.md) | [↑ Index](index.md) | [Next →](21-section-12-sftp-chroot-and-restricted-shells.md)
