# 🐧 Linux System Administrator — Complete Course
## Part 15 of ∞: SSH and Remote Access — Secure Remote Administration

---

> **Reverse Engineering Approach:** Every server you manage will be remote. You will never sit at its physical console. SSH is your hands, your eyes, your ears on a machine that could be in another room or another continent. Understanding SSH from the inside out — how it encrypts, how it authenticates, how it tunnels — is the single most important skill for a sysadmin.

---

## 🎯 What You Will Achieve in Part 15

This module is organized into three progressive levels:

| Level | You Will Learn |
|-------|---------------|
| **⭐ Basic** | How SSH works, client connection basics, key authentication generation and setup, simple remote commands |
| **⭐ Intermediary** | SSH server configuration (sshd_config), file transfer (SCP/rsync/SFTP), client config file for shortcuts |
| **⭐ Advanced** | SSH tunneling and port forwarding, security hardening, troubleshooting, and encryption internals |

---

## ⭐ Level 1: Basic — Understanding SSH and Remote Connections

![Unofficial SSH Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Unofficial_SSH_Logo.svg/800px-Unofficial_SSH_Logo.svg.png)
*Unofficial SSH logo by Jessie Kirk, CC BY 4.0, via Wikimedia Commons*

> **Level 1 Goal:** Understand what SSH is, how it encrypts and authenticates, and gain confidence connecting to remote machines from the command line.

---

## 🔍 Section 1: How SSH Works

SSH (Secure Shell) is a protocol for securely connecting to remote systems.

### The Three Layers of SSH

```
┌──────────────────────────────────────┐
│    SSH Transport Layer (TCP 22)       │  ← Establishes encrypted connection
│    - Server authentication            │
│    - Key exchange                     │
│    - Encryption negotiation           │
├──────────────────────────────────────┤
│    SSH Authentication Layer           │  ← Verifies who you are
│    - Password                        │
│    - Public key                      │
│    - Keyboard-interactive            │
│    - GSSAPI (Kerberos)               │
├──────────────────────────────────────┤
│    SSH Connection Layer               │  ← Multiplexes multiple channels
│    - Interactive shell               │
│    - Remote command execution        │
│    - Port forwarding                 │
│    - X11 forwarding                  │
└──────────────────────────────────────┘
```

### The SSH Handshake

```
1. Client connects to server on port 22
2. Server sends its host key (public)
3. Client checks: is this host key in ~/.ssh/known_hosts?
4. Client and server perform key exchange (Diffie-Hellman)
5. Shared session key is established (SYMMETRIC encryption)
6. All further communication is encrypted with session key
7. Client authenticates (password or public key)
8. Session begins
```

### Host Keys

```bash
# Server identifies itself with a host key
ls /etc/ssh/ssh_host_*
# ssh_host_rsa_key         - RSA
# ssh_host_ecdsa_key      - ECDSA
# ssh_host_ed25519_key    - Ed25519 (most secure)

# Fingerprint of the host key (what you see on first connect)
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
```

When you connect for the first time:

```
$ ssh server.example.com
The authenticity of host 'server.example.com (192.168.1.100)' can't be established.
ED25519 key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

This fingerprint is stored in `~/.ssh/known_hosts`. On subsequent connections, the server must present the same key — or SSH warns you of a possible man-in-the-middle attack.

---

## 🔍 Section 2: SSH Client Basics

### Connecting to a Server

```bash
# Basic connection
ssh user@server.example.com

# Connect on a non-default port
ssh -p 2222 user@server.example.com

# Connect and run a command (then exit)
ssh user@server.example.com "ls -la /tmp"

# Connect with verbose output (debugging)
ssh -v user@server.example.com

# Even more verbose
ssh -vvv user@server.example.com
```

### Running Remote Commands

```bash
# Single command
ssh user@server "uptime"

# Multiple commands
ssh user@server "df -h && free -h"

# Pipeline (local data through SSH to remote)
cat localfile.txt | ssh user@server "cat > /tmp/remotefile.txt"

# Remote output to local file
ssh user@server "cat /var/log/syslog" > local-syslog.txt
```

### The SSH Escape Sequence

```bash
# When connected, type ~? to see escape sequences
# ~.  — terminate connection (if stuck)
# ~^Z — suspend SSH
# ~C  — open command line (for port forwarding)
```

---

## 🔍 Section 3: SSH Key Authentication

Key-based authentication is more secure and more convenient than passwords.

### How It Works

```
Client has:    private key (secret)   +   public key (shared)
Server has:    public key in ~/.ssh/authorized_keys

1. Client requests public key authentication
2. Server checks if client's public key is in authorized_keys
3. Server sends a challenge (random number encrypted with public key)
4. Client decrypts with private key and sends back the number
5. Server verifies → authentication successful
```

### Generating SSH Keys

```bash
# Generate an Ed25519 key (most secure, recommended)
ssh-keygen -t ed25519 -C "my-email@example.com"

# Generate an RSA key (compatible with older systems)
ssh-keygen -t rsa -b 4096 -C "my-email@example.com"

# Output:
# Your identification has been saved in /home/user/.ssh/id_ed25519
# Your public key has been saved in /home/user/.ssh/id_ed25519.pub
```

### Key File Structure

```bash
ls ~/.ssh/
# id_ed25519          — Private key (NEVER share this)
# id_ed25519.pub      — Public key (safe to share)
# authorized_keys     — Public keys allowed to connect
# known_hosts         — Host keys of servers you've connected to
# config              — Client configuration (shortcuts)
```

### Copying Your Public Key to a Server

```bash
# Method 1: ssh-copy-id (easiest, requires password once)
ssh-copy-id user@server.example.com

# Method 2: Manually append
cat ~/.ssh/id_ed25519.pub | ssh user@server.example.com \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Method 3: Using ssh-copy-id on non-standard port
ssh-copy-id -p 2222 user@server.example.com
```

### Key Permissions (Critical!)

```bash
# Correct permissions for SSH to work
chmod 700 ~/.ssh         # Directory: 700 (drwx------)
chmod 600 ~/.ssh/id_ed25519       # Private key: 600 (-rw-------)
chmod 644 ~/.ssh/id_ed25519.pub   # Public key: 644 (-rw-r--r--)
chmod 600 ~/.ssh/authorized_keys  # Authorized keys: 600
chmod 644 ~/.ssh/known_hosts      # Known hosts: 644
```

If permissions are wrong, SSH will refuse to use the keys.

### Testing Key Authentication

```bash
# Connect — should now work WITHOUT a password
ssh user@server.example.com

# If it still asks for a password:
ssh -v user@server.example.com | grep "Authenticated"
# Look for "Authenticated with partial success" or "Authentication succeeded"
```

### ssh-agent (Locking Private Keys in Memory)

```bash
# Start the agent in your session
eval "$(ssh-agent -s)"

# Add your private key (enter passphrase once per session)
ssh-add ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l

# Remove all keys
ssh-add -D
```

---

## ⭐ Level 2: Intermediary — Configuring SSH Servers and Transfers

![OpenSSH Privilege Separation Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/OpenSSH-Privilege-Separation.svg/800px-OpenSSH-Privilege-Separation.svg.png)
*OpenSSH privilege separation model, via Wikimedia Commons*

> **Level 2 Goal:** Configure the SSH server securely, transfer files efficiently, and create client-side shortcuts for daily administrative tasks.

---

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

---

## 🔍 Section 5: File Transfer — SCP, Rsync, SFTP

### SCP (Secure Copy)

```bash
# Copy file TO server
scp localfile.txt user@server:/path/to/destination/

# Copy file FROM server
scp user@server:/path/to/remotefile.txt .

# Copy directory recursively
scp -r /local/dir user@server:/remote/dir/

# Copy with non-standard port
scp -P 2222 file.txt user@server:/tmp/

# Copy between two remote servers (direct)
scp user1@server1:/file.txt user2@server2:/tmp/
```

### rsync (Advanced File Transfer)

rsync is smarter than scp — it only transfers differences.

```bash
# Basic copy (like scp but better)
rsync -av localdir/ user@server:/remote/dir/

# Common flags:
# -a  — archive mode (preserves permissions, timestamps, etc.)
# -v  — verbose
# -z  — compress during transfer
# -P  — show progress AND resume partial transfers
# --delete — remove files at destination that don't exist at source

# Backup with progress
rsync -avzP /home/user/important/ user@server:/backup/

# Mirror a directory (exact copy)
rsync -avz --delete /source/ user@server:/destination/

# Over non-standard SSH port
rsync -avz -e "ssh -p 2222" /source/ user@server:/destination/

# Dry run (see what would happen)
rsync -avz --dry-run /source/ user@server:/destination/
```

### SFTP (SSH File Transfer Protocol)

Interactive file transfer over SSH.

```bash
# Connect
sftp user@server.example.com

# SFTP commands (once connected):
# ls                   — list remote directory
# lls                  — list local directory
# cd                   — change remote directory
# lcd                  — change local directory
# get remote_file      — download
# put local_file       — upload
# get -r remote_dir/   — download directory
# put -r local_dir/    — upload directory
# rm file              — delete remote file
# mkdir dir            — create remote directory
# rmdir dir            — remove remote directory
# !command             — run local command
# help                 — show help
# quit                 — exit

# Batch mode (non-interactive)
echo "put /local/file.txt /remote/" | sftp -b - user@server
```

### Which Tool to Use?

| Tool | Best For |
|------|----------|
| scp | Quick one-off file copies |
| rsync | Large transfers, backups, directory syncing |
| sftp | Interactive file management on remote server |

---

## 🔍 Section 6: SSH Config File (~/.ssh/config)

Create shortcuts for frequently accessed servers.

### Basic Host Entries

```bash
cat ~/.ssh/config

# Defaults for all hosts
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Specific host
Host webserver
    HostName 192.168.1.100
    User admin
    Port 2222
    IdentityFile ~/.ssh/webserver-key
```

Once configured:

```bash
# Instead of:
ssh admin@192.168.1.100 -p 2222 -i ~/.ssh/webserver-key

# You just type:
ssh webserver
```

### Advanced Config Examples

```bash
# Multiple names for same host
Host web web1 webserver
    HostName 192.168.1.100
    User admin

# Wildcard for a domain
Host *.example.com
    User sysadmin
    IdentityFile ~/.ssh/example-key
    ForwardAgent yes

# Jump host (bounce through one server to reach another)
Host internal-server
    HostName 10.0.0.50
    User sysadmin
    ProxyJump jumphost.example.com
    # Or for older SSH: ProxyCommand ssh jumphost.example.com -W %h:%p

# Force command on connection
Host readonly
    HostName 192.168.1.100
    User backup
    IdentityFile ~/.ssh/readonly-key
    RemoteCommand /usr/local/bin/readonly-shell
    RequestTTY yes

# Local port forwarding shortcut
Host tunnel
    HostName db.example.com
    User admin
    LocalForward 3306 localhost:3306
```

### SSH Config Options

```bash
Host                    # Pattern to match (can use *)
HostName                # Actual hostname or IP
Port                    # Port number (default: 22)
User                    # Username
IdentityFile            # Path to private key
ProxyJump               # Jump host (bastion)
LocalForward            # Local port → remote port
RemoteForward           # Remote port → local port
ForwardAgent            # Forward SSH agent (yes/no)
ServerAliveInterval     # Keep-alive interval (seconds)
ServerAliveCountMax     # Failed keep-alive limit
StrictHostKeyChecking   # How to handle unknown hosts (ask/yes/no)
UserKnownHostsFile      # Custom known_hosts file
LogLevel                # Verbosity (QUIET, INFO, VERBOSE, DEBUG)
Compression             # Enable compression (yes/no)
```

---

## ⭐ Level 3: Advanced — Tunneling, Hardening, and Troubleshooting

![SSH Binary Packet Structure](https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Ssh_binary_packet_alt.svg/800px-Ssh_binary_packet_alt.svg.png)
*SSH binary packet structure, CC BY 2.5, via Wikimedia Commons*

> **Level 3 Goal:** Create encrypted tunnels, harden SSH against attacks, diagnose connection problems, and understand the cryptographic internals of the SSH protocol.

---

## 🔍 Section 7: SSH Tunneling (Port Forwarding)

SSH can forward ports through encrypted channels.

### Local Port Forwarding

Access a remote service as if it were local:

```bash
# Access a database on a remote server through SSH
# Remote server has MySQL on port 3306, not exposed to internet
ssh -L 3306:localhost:3306 user@server.example.com

# Now on YOUR machine:
mysql -h localhost -P 3306
# This connects through the SSH tunnel to the remote MySQL
```

```
Your Machine                     SSH Server              MySQL Server
:3306  ←←←  SSH Tunnel  →→→  localhost:3306 →→→  localhost:3306
```

### Remote Port Forwarding

Expose a local service on a remote server:

```bash
# You have a web server on port 8080 on your machine
# You want someone on the remote server to access it
ssh -R 8080:localhost:8080 user@server.example.com

# Now on the REMOTE server:
curl http://localhost:8080
# This reaches your local web server through the tunnel
```

### Dynamic Port Forwarding (SOCKS Proxy)

Create a SOCKS proxy through SSH:

```bash
# All traffic through the remote server
ssh -D 1080 user@server.example.com

# Configure your browser to use SOCKS proxy:
# Proxy: SOCKS5, localhost, port 1080
# Now your web traffic appears to come from the SSH server
```

### Practical Tunnel Examples

```bash
# Access a web admin interface on a remote server
ssh -L 8080:localhost:80 user@server.example.com
# Then open: http://localhost:8080

# Access a remote PostgreSQL database through a jump host
ssh -L 5432:db.internal.example.com:5432 user@jumphost.example.com

# Multi-hop tunnel (through jump host to internal server)
ssh -L 8080:internal-web:80 user@jumphost.example.com

# Persistent tunnel (autossh — stays up)
autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
  -L 3306:localhost:3306 user@server.example.com
```

---

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

---

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

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: Foundational SSH Skills

---

### ✅ Practice 1: Check Your SSH Setup

```bash
mkdir -p ~/linux-course/part15
cd ~/linux-course/part15

# Check if SSH is running
systemctl status sshd 2>/dev/null || systemctl status ssh 2>/dev/null

# Check SSH version
ssh -V

# Check your SSH directory
ls -la ~/.ssh/
```

---

### ✅ Practice 2: Generate SSH Keys

```bash
cd ~/linux-course/part15

# Generate an Ed25519 key
ssh-keygen -t ed25519 -C "course-practice-$(hostname)" -f ~/.ssh/course_key -N ""

# Examine the private key
echo "=== Private key (first line) ==="
head -1 ~/.ssh/course_key

echo ""
echo "=== Public key ==="
cat ~/.ssh/course_key.pub

echo ""
echo "=== Key fingerprint ==="
ssh-keygen -l -f ~/.ssh/course_key.pub
```

---

### ✅ Practice 3: Connect to Localhost with Key

```bash
cd ~/linux-course/part15

# Add your new key to authorized_keys
cat ~/.ssh/course_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Test connecting to localhost
ssh -i ~/.ssh/course_key localhost "echo 'SSH to localhost works!'"

# First time will show host key warning — answer "yes"
```

---

### ✅ Practice 4: Explore sshd Configuration

```bash
cd ~/linux-course/part15

# Check the main config
sudo cat /etc/ssh/sshd_config

# Find active settings
echo ""
echo "=== Active SSH settings ==="
sudo sshd -T 2>/dev/null | grep -E "port|permitrootlogin|passwordauthentication|pubkeyauthentication"

# Check listening port
ss -tlnp | grep ssh
```

---

### Level 2 Practices: Configuration and File Transfers

### ✅ Practice 5: Remote Commands

```bash
cd ~/linux-course/part15

# Run commands on localhost via SSH
ssh -i ~/.ssh/course_key localhost "uname -a"
ssh -i ~/.ssh/course_key localhost "uptime"
ssh -i ~/.ssh/course_key localhost "df -h /"

# Chain commands
ssh -i ~/.ssh/course_key localhost "uptime && free -h && df -h"
```

---

### ✅ Practice 6: SCP File Transfer

```bash
cd ~/linux-course/part15

# Create a test file
echo "This is a test file for SCP" > test-scp.txt

# Copy TO localhost
scp -i ~/.ssh/course_key test-scp.txt localhost:/tmp/
ssh -i ~/.ssh/course_key localhost "cat /tmp/test-scp.txt"

# Copy FROM localhost
ssh -i ~/.ssh/course_key localhost "echo 'Remote file content' > /tmp/remote-file.txt"
scp -i ~/.ssh/course_key localhost:/tmp/remote-file.txt .
cat remote-file.txt

# Clean up
rm -f test-scp.txt remote-file.txt
```

---

### ✅ Practice 7: rsync Transfer

```bash
cd ~/linux-course/part15

# Create a test directory
mkdir test-dir
echo "file1 content" > test-dir/file1.txt
echo "file2 content" > test-dir/file2.txt
mkdir test-dir/subdir
echo "subdir file" > test-dir/subdir/file3.txt

# rsync to /tmp
rsync -av test-dir/ localhost:/tmp/test-dir/

# Verify
ssh -i ~/.ssh/course_key localhost "find /tmp/test-dir -type f"

# rsync back
rsync -av localhost:/tmp/test-dir/ retrieved-dir/
ls -la retrieved-dir/

# Clean up
rm -rf test-dir retrieved-dir
```

---

### ✅ Practice 8: SFTP Interactive Session

```bash
cd ~/linux-course/part15

# Create a batch file for SFTP
echo "Put a file via SFTP" > sftp-test.txt

# Non-interactive SFTP
echo "put sftp-test.txt /tmp/" | sftp -b - -i ~/.ssh/course_key localhost

# Verify
ssh -i ~/.ssh/course_key localhost "cat /tmp/sftp-test.txt"

# Download via batch
echo "get /tmp/sftp-test.txt downloaded.txt" | sftp -b - -i ~/.ssh/course_key localhost
cat downloaded.txt

# Clean up
rm -f sftp-test.txt downloaded.txt
```

---

### ✅ Practice 9: SSH Config File

```bash
cd ~/linux-course/part15

# Create an SSH config entry
cat >> ~/.ssh/config << 'EOF'

# Course practice
Host local-course
    HostName localhost
    User $(whoami)
    IdentityFile ~/.ssh/course_key
    Port 22
EOF

chmod 600 ~/.ssh/config

# Test the shortcut
ssh local-course "echo 'SSH config shortcut works!'"
```

---

### Level 3 Practices: Tunneling, Hardening, and Automation

### ✅ Practice 10: Port Forwarding

```bash
cd ~/linux-course/part15

# Start a simple Python HTTP server on the "remote" end (localhost)
python3 -m http.server 8888 --bind 127.0.0.1 &
HTTP_PID=$!
sleep 1

# Test direct access
curl -s http://127.0.0.1:8888/ | head -5

# Now forward remote 8888 to local 9999 through SSH
ssh -i ~/.ssh/course_key -L 9999:localhost:8888 -N -f localhost

# Test through the tunnel
echo ""
echo "=== Through SSH tunnel ==="
curl -s http://127.0.0.1:9999/ | head -5

# Clean up
kill $HTTP_PID 2>/dev/null
pkill -f "ssh.*-L 9999" 2>/dev/null || true
```

---

### ✅ Practice 11: SSH Agent

```bash
cd ~/linux-course/part15

# Start SSH agent
eval "$(ssh-agent -s)"
echo "SSH agent started: $SSH_AGENT_PID"

# Add key
ssh-add ~/.ssh/course_key
ssh-add -l

# Use agent for connection
ssh -o StrictHostKeyChecking=no localhost "echo 'Agent forwarding works'"

# Remove key
ssh-add -d ~/.ssh/course_key
ssh-add -l

# Kill agent
ssh-agent -k
```

---

### ✅ Practice 12: Server Hardening (Simulated)

```bash
cd ~/linux-course/part15

# Check current security settings
echo "=== Current SSH Security Settings ==="
sudo sshd -T 2>/dev/null | grep -E \
  "permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries|port"

# Note: In a real environment, you would edit /etc/ssh/sshd_config
# For this course, we'll just demonstrate the lines to add
echo ""
echo "=== Suggested security settings ==="
cat << 'EOF'
Port 2222
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
EOF
```

---

### ✅ Practice 13: fail2ban Overview

```bash
cd ~/linux-course/part15

# Check if fail2ban is installed
if command -v fail2ban-client &>/dev/null; then
    echo "fail2ban is installed"
    sudo fail2ban-client status
    sudo fail2ban-client status sshd 2>/dev/null || echo "sshd jail not active"
else
    echo "fail2ban is not installed"
    echo "Install with: sudo apt install fail2ban"
fi

# Show how fail2ban works
cat << 'EOF'
fail2ban monitoring flow:
1. Watches /var/log/auth.log
2. Detects failed SSH attempts
3. After 5 failures from same IP
4. Adds iptables rule to block that IP
5. Ban lasts for 1 hour (configurable)
6. Automatically removes ban after time expires
EOF
```

---

### ✅ Practice 14: Test SSH Connection Debugging

```bash
cd ~/linux-course/part15

# Verbose connection (shows auth process)
echo "=== Verbose SSH (showing auth) ==="
ssh -v -i ~/.ssh/course_key -o StrictHostKeyChecking=no localhost "exit" 2>&1 | \
  grep -E "debug1: (Offering|Authentication|Authenticated|Connection)"

# Check known_hosts
echo ""
echo "=== Known hosts ==="
cat ~/.ssh/known_hosts
```

---

### ✅ Practice 15: Real SysAdmin Scenario — SSH Audit Script

```bash
cd ~/linux-course/part15

cat > ssh_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="ssh_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  SSH AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: SSH daemon status
echo "1. SSH DAEMON STATUS" >> "$REPORT"
systemctl status sshd 2>/dev/null | head -5 >> "$REPORT" || \
systemctl status ssh 2>/dev/null | head -5 >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: Listening port
echo "2. LISTENING PORT" >> "$REPORT"
ss -tlnp | grep ssh >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: Security settings
echo "3. SECURITY SETTINGS" >> "$REPORT"
sudo sshd -T 2>/dev/null | grep -E \
  "port|permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries|maxsessions|allowusers|allowgroups" \
  >> "$REPORT"
echo "" >> "$REPORT"

# Section 4: Host keys
echo "4. HOST KEYS" >> "$REPORT"
for key in /etc/ssh/ssh_host_*_key.pub; do
    if [ -f "$key" ]; then
        echo -n "  " >> "$REPORT"
        ssh-keygen -l -f "$key" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# Section 5: Authentication attempts
echo "5. RECENT AUTHENTICATION ATTEMPTS" >> "$REPORT"
echo "  Successful logins:" >> "$REPORT"
last | head -5 >> "$REPORT"
echo "" >> "$REPORT"
echo "  Failed attempts (today):" >> "$REPORT"
sudo grep "$(date +%b\ %e)" /var/log/auth.log | grep "Failed password" | wc -l | \
  awk '{print "  " $1 " failed attempts today"}' >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: Authorized keys
echo "6. AUTHORIZED KEYS" >> "$REPORT"
echo "  Users with authorized_keys:" >> "$REPORT"
for user_dir in /home/* /root; do
    if [ -f "$user_dir/.ssh/authorized_keys" ]; then
        username=$(basename "$user_dir")
        key_count=$(wc -l < "$user_dir/.ssh/authorized_keys")
        echo "  $username: $key_count key(s)" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# Section 7: SSH client config
echo "7. SSH CLIENT CONFIG" >> "$REPORT"
if [ -f ~/.ssh/config ]; then
    echo "  ~/.ssh/config exists with $(grep -c "^Host " ~/.ssh/config) host(s)" >> "$REPORT"
else
    echo "  No client config file" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x ssh_audit.sh
./ssh_audit.sh
```

---

## 🧠 Deep Understanding — How SSH Encryption Works

### Symmetric vs Asymmetric Encryption

```
SSH uses BOTH:

1. Asymmetric (public key) — for key exchange and authentication
   - Server has private host key
   - You see the public host key on first connect
   - Used to establish a secure channel

2. Symmetric (shared secret) — for the actual session
   - Both sides derive the same session key
   - Much faster than asymmetric
   - Used for ALL data during the session
```

### The Key Exchange (Diffie-Hellman)

```
1. Client and server agree on a large prime number p and generator g
2. Client picks secret a, sends A = g^a mod p
3. Server picks secret b, sends B = g^b mod p
4. Client computes: K = B^a mod p = g^(a*b) mod p
5. Server computes: K = A^b mod p = g^(a*b) mod p
6. Both now have the SAME session key K
7. Even if attacker captures A and B, they cannot compute K
   (discrete logarithm problem — computationally infeasible)
```

### Perfect Forward Secrecy

Modern SSH uses ephemeral Diffie-Hellman — a NEW key pair is generated for each session. Even if the server's long-term private key is stolen later, past sessions cannot be decrypted.

### SSH Agent Protocol

```
ssh-agent stores your decrypted private key in memory.
When you authenticate:

1. Server sends challenge (random data encrypted with your public key)
2. SSH client asks agent: "Please decrypt this"
3. Agent decrypts with private key (held in memory)
4. SSH client sends decrypted challenge back to server
5. Server verifies → authenticated

The private key NEVER leaves the agent.
```

---

## 📋 Summary — Complete Command Reference for Part 15

### Level 1: Basic SSH Commands

| Command | Action |
|---------|--------|
| `ssh user@host` | Connect to remote host |
| `ssh -p PORT user@host` | Connect on specific port |
| `ssh -i KEY user@host` | Use specific private key |
| `ssh -v user@host` | Verbose (debug) output |
| `ssh-keygen -t ed25519` | Generate Ed25519 key pair |
| `ssh-keygen -l -f KEY.pub` | Show key fingerprint |
| `ssh-copy-id user@host` | Copy public key to server |
| `ssh-add` | Add key to agent |
| `ssh-add -l` | List loaded keys |
| `ssh-agent -s` | Start agent |

### Level 2: Configuration and File Transfer

| Command | Action |
|---------|--------|
| `scp file user@host:path` | Copy file to server |
| `scp user@host:file .` | Copy file from server |
| `scp -r dir user@host:path` | Copy directory recursively |
| `rsync -avz src user@host:dest` | Sync files efficiently |
| `sftp user@host` | Interactive file transfer |
| `sudo systemctl status sshd` | Check SSH daemon status |
| `sudo sshd -t` | Test config before restart |
| `sudo systemctl restart sshd` | Restart SSH daemon |
| `cat /etc/ssh/sshd_config` | View server config |

### Level 3: Advanced and Troubleshooting

| Command | Action |
|---------|--------|
| `ssh -L LPORT:RHOST:RPORT user@host` | Local port forwarding |
| `ssh -D PORT user@host` | SOCKS proxy |
| `ssh -N -f user@host` | No command, background |
| `ssh -J user@jumphost user@target` | Jump host (ProxyJump) |
| `autossh -L LPORT:RHOST:RPORT user@host` | Persistent tunnel |
| `ssh-keygen -R hostname` | Remove host key from known_hosts |
| `ssh-keyscan hostname` | Fetch remote host key |
| `ssh -G user@host` | Show effective SSH config |
| `sudo sshd -T` | Show active SSH daemon settings |

---

## 🚀 What's Coming in Part 16

**Part 16: Firewalls — iptables, firewalld, nftables**

You will learn:
- How Linux packet filtering works
- iptables concepts (tables, chains, rules)
- firewalld (zones, services, rich rules)
- nftables — the modern replacement
- Creating and managing firewall rules
- Saving and restoring firewall configurations
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the three layers of the SSH protocol?
2. What is the difference between a host key and a user key?
3. What command generates an Ed25519 SSH key pair?
4. What permissions should ~/.ssh and ~/.ssh/authorized_keys have?
5. How does `ssh-copy-id` work?
6. What is the purpose of ssh-agent?
7. What is the difference between `scp` and `rsync`?
8. What does `ssh -L 8080:localhost:80 user@server` do?
9. What three settings should you change to harden SSH?
10. How do you test sshd_config before restarting?
11. What does `MaxAuthTries` do in sshd_config?
12. How do you copy a file FROM a remote server?
13. What is a SOCKS proxy and how do you create one with SSH?
14. What does `ssh-keygen -R hostname` do?
15. How does fail2ban protect SSH?

**Score:** 12/15 correct = ready for Part 16.

---

*Linux SysAdmin Course | Part 15 of ∞ | Reverse Engineering Approach*
*Previous → Part 14: Logging and Journald*
*Next → Part 16: Firewalls — iptables, firewalld, nftables*

[← Previous](part14.md) | [Next →](part16.md)
