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



---

[← Previous](13-section-9-troubleshooting-ssh.md) | [↑ Index](index.md) | [Next →](15-deep-understanding-how-ssh-encryption.md)
