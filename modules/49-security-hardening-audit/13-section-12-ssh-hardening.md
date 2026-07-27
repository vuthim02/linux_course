## 🔍 Section 12: SSH Hardening

### Comprehensive sshd_config

```bash
# Backup the original
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Write hardened configuration
sudo tee /etc/ssh/sshd_config > /dev/null << 'EOF'
# /etc/ssh/sshd_config — Hardened

# --- Protocol and Port ---
Port 22
Protocol 2                     # Only protocol 2 (protocol 1 is insecure)

# --- Authentication ---
PermitRootLogin no              # Never allow direct root login
PubkeyAuthentication yes        # Enable key-based auth
PasswordAuthentication no       # Disable password auth (keys only)
KbdInteractiveAuthentication no # Disable keyboard-interactive
ChallengeResponseAuthentication no
AuthenticationMethods publickey # Only publickey (no keyboard-interactive fallback)

# --- Key Types ---
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
# Disable weak host keys:
# HostKey /etc/ssh/ssh_host_dsa_key     # DSA is broken
# HostKey /etc/ssh/ssh_host_ecdsa_key   # ECDSA has questionable NIST curves

# --- Access Control ---
AllowUsers alice bob charlie      # Only these users can SSH
# DenyUsers mallory                  # Explicitly deny
# AllowGroups ssh-users              # Or use groups
# DenyGroups attackers

# --- Rate Limiting ---
MaxAuthTries 3                    # Max 3 auth attempts before disconnect
MaxSessions 10                    # Max 10 concurrent sessions from one connection
MaxStartups 10:30:60              # Startrate: 10 max unauthenticated, 30% drop chance at 60

# --- Timeouts ---
ClientAliveInterval 300           # Send keepalive every 300 seconds
ClientAliveCountMax 2             # Max 2 missed keepalives before disconnect
LoginGraceTime 60                 # Must authenticate within 60 seconds

# --- Cryptographic Settings ---
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512

# --- Logging ---
SyslogFacility AUTH
LogLevel VERBOSE                   # Log key fingerprints

# --- PAM ---
UsePAM yes                         # Enable PAM for account restrictions

# --- Environment ---
PermitUserEnvironment no           # Never allow user environment variables
AcceptEnv LANG LC_*

# --- Forwarding ---
AllowTcpForwarding no              # Disable TCP forwarding (reduce lateral movement)
X11Forwarding no                   # Disable X11 forwarding (security risk)
AllowAgentForwarding no            # Disable agent forwarding
PermitTunnel no

# --- Chroot and Restricted Shell ---
# Subsystem sftp internal-sftp      # Use internal-sftp for chroot
# Match Group sftp-users
#     ChrootDirectory /srv/sftp/%u
#     ForceCommand internal-sftp
#     X11Forwarding no
#     AllowTcpForwarding no
#     PermitTunnel no
EOF

# Test configuration before restarting
sudo sshd -t

# Restart SSH
sudo systemctl restart sshd
```

### ChrootDirectory for Restricted Users

```bash
# Create a chroot environment for SFTP-only users
sudo mkdir -p /srv/sftp/john/{incoming,.ssh}
sudo chown root:root /srv/sftp/john
sudo chmod 755 /srv/sftp/john
sudo chown john:john /srv/sftp/john/incoming
sudo chmod 755 /srv/sftp/john/incoming

# SSH config for chroot:
# Match Group sftp-users
#     ChrootDirectory /srv/sftp/%u
#     ForceCommand internal-sftp
#     X11Forwarding no
#     AllowTcpForwarding no
```

### SSH Key Types and Strength

```bash
# Generate strong keys
ssh-keygen -t ed25519 -a 100     # Fast, secure, short keys
ssh-keygen -t rsa -b 4096        # Compatible, but slower
ssh-keygen -t ecdsa -b 521       # ECDSA with P-521 curve

# Check existing key fingerprints
ssh-keygen -lf ~/.ssh/id_ed25519.pub
# 256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx user@host (ED25519)

# Add key to agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### SSH Audit Script

```bash
#!/bin/bash
# ssh-audit.sh — Quick SSH security check
echo "=== SSH Configuration Audit ==="
echo ""

# Check PermitRootLogin
ROOT_LOGIN=$(sudo sshd -T | grep permitrootlogin | awk '{print $2}')
echo "PermitRootLogin: $ROOT_LOGIN"
[ "$ROOT_LOGIN" = "no" ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

# Check PasswordAuthentication
PASS_AUTH=$(sudo sshd -T | grep passwordauthentication | awk '{print $2}')
echo "PasswordAuthentication: $PASS_AUTH"
[ "$PASS_AUTH" = "no" ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

# Check Protocol
PROTOCOL=$(sudo sshd -T | grep protocol | awk '{print $2}')
echo "Protocol: $PROTOCOL"
[ "$PROTOCOL" = "2" ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

# Check MaxAuthTries
MAX_TRIES=$(sudo sshd -T | grep maxauthtries | awk '{print $2}')
echo "MaxAuthTries: $MAX_TRIES"
[ "$MAX_TRIES" -le 3 ] 2>/dev/null && echo "  ✅ PASS" || echo "  ⚠️ CHECK"

# Check key exchange algorithms
KEX=$(sudo sshd -T | grep kexalgorithms | tr ',' '\n' | head -5)
echo "Key exchange algorithms (first 5):"
echo "$KEX" | sed 's/^/  /'

# Check for weak ciphers
WEAK=$(sudo sshd -T | grep ciphers | grep -c -E 'aes128-cbc|aes256-cbc|3des')
echo ""
[ "$WEAK" -gt 0 ] && echo "❌ WEAK CIPHERS DETECTED" || echo "✅ No weak ciphers detected"
```

---



---

[← Previous](12-section-11-apparmor-selinux.md) | [↑ Index](index.md) | [Next →](14-section-13-log-security.md)
