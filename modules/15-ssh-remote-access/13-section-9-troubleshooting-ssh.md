## 🔍 Section 9: Troubleshooting SSH

### Common SSH Problems

**Problem 1: Connection refused**

```bash
ssh: connect to host server port 22: Connection refused

# Causes:
# 1. SSH server not running
sudo systemctl status sshd

# 2. Firewall blocking port 22
sudo ufw status
sudo firewall-cmd --list-all

# 3. SSH is on a different port
ssh -p 2222 user@server
```

**Problem 2: Permission denied (publickey)**

```bash
# Causes and fixes:
# 1. Wrong key
ssh -v user@server  # Check which key is being offered

# 2. Wrong permissions on server
ssh user@server "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

# 3. Public key not in authorized_keys
ssh-copy-id user@server

# 4. SELinux blocking
sudo restorecon -Rv ~/.ssh
```

**Problem 3: Host key verification failed**

```bash
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# Server has been reinstalled or IP reassigned
# Fix: remove old host key
ssh-keygen -R server.example.com
ssh-keygen -R 192.168.1.100
```

**Problem 4: Connection timed out**

```bash
ssh: connect to host server port 22: Connection timed out

# Causes:
# 1. Network issue (server unreachable)
ping server

# 2. Firewall dropping packets
# 3. Wrong IP address
# 4. Server is down
```

**Problem 5: Too many authentication failures**

```bash
# SSH client tries too many keys and gets blocked
# Fix: specify exactly which key to use
ssh -i ~/.ssh/specific-key user@server

# Or in ~/.ssh/config:
IdentitiesOnly yes
IdentityFile ~/.ssh/specific-key
```

### Debugging SSH Connections

```bash
# Verbose mode (-v, -vv, -vvv)
ssh -vvv user@server.example.com 2>&1 | grep -i "debug\|auth\|key\|fail"

# Check SSH config parsing
ssh -G user@server.example.com  # Show effective config

# Check server key fingerprints
ssh-keyscan server.example.com

# Test SSH daemon configuration
sudo sshd -t
```





[← Previous](12-section-8-hardening-ssh-security.md) | [↑ Index](index.md) | [Next →](14-practice-section-15-hands-on-exercises.md)
