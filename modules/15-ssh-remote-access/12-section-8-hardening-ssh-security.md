## 🔍 Section 8: Hardening SSH Security

### Preventing Brute Force Attacks

```bash
# 1. Change default port (reduces 99% of automated attacks)
Port 2222

# 2. Disable password authentication
PasswordAuthentication no

# 3. Disable root login
PermitRootLogin prohibit-password

# 4. Use fail2ban (automatically bans IPs after failed attempts)
sudo apt install fail2ban
sudo systemctl enable --now fail2ban

# fail2ban config for SSH:
sudo tee /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF
```

### Additional Security Measures

```bash
# 5. Allow only specific users
AllowUsers alice bob carol

# 6. Allow only specific groups
AllowGroups ssh-users

# 7. Use an SSH banner (legal warning)
sudo tee /etc/ssh/ssh-banner.txt << 'EOF'
****************************************************************
  WARNING: Authorized Access Only
  All activities are monitored and logged.
  Unauthorized access is prohibited.
****************************************************************
EOF
# In sshd_config:
Banner /etc/ssh/ssh-banner.txt

# 8. Limit authentication attempts
MaxAuthTries 3
MaxSessions 3

# 9. Use key types that are known secure
# In sshd_config:
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
# Remove weak key types: HostKeyAlgorithms, PubkeyAcceptedKeyTypes

# 10. Disable protocol 1 (only protocol 2 exists now)
Protocol 2
```

### Two-Factor Authentication with SSH

```bash
# Using Google Authenticator (TOTP)
sudo apt install libpam-google-authenticator

# Run as the user:
google-authenticator

# In /etc/pam.d/sshd, add:
auth required pam_google_authenticator.so

# In /etc/ssh/sshd_config:
ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive

# Now users need: SSH key + TOTP code
```





[← Previous](11-section-7-ssh-tunneling-port.md) | [↑ Index](index.md) | [Next →](13-section-9-troubleshooting-ssh.md)
