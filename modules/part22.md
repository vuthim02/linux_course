# 🐧 Linux System Administrator — Complete Course
## Part 22 of ∞: Network Services — DHCP, HTTP, SSH

---

> **Reverse Engineering Approach:** A server that nobody can reach is not a server — it's a paperweight. Networking services turn a Linux machine into a utility that other machines depend on: handing out IP addresses (DHCP), serving web pages (HTTP), and providing remote access (SSH). Understanding how to configure, secure, and troubleshoot these services is the difference between a server that works and one that is a vulnerability.

---

## 🎯 What You Will Achieve in Part 22

This module is organized into three progressive levels:

| Level | Focus | What You'll Master |
|-------|-------|--------------------|
| ⭐ Level 1: Basic | DHCP and HTTP Basics | Configuring a DHCP server and a basic HTTP (Apache/Nginx) server |
| ⭐ Level 2: Intermediary | SSH and Service Management | SSH server setup, network service management, security, and monitoring |
| ⭐ Level 3: Advanced | Troubleshooting and Internals | Diagnosing service failures and understanding service internals |

---

## ⭐ Level 1: Basic — DHCP and HTTP Basics

![DHCP interaction — Discover, Offer, Request, Acknowledge](https://upload.wikimedia.org/wikipedia/commons/5/58/DHCP_session.svg)

*DHCP session flow — Discover, Offer, Request, Acknowledge (Wikimedia Commons / public domain)*

> **Level 1 Goal:** Set up a DHCP server to assign IP addresses automatically and configure a basic Apache or Nginx web server to serve static content.

## 🔍 Section 1: DHCP Server

### What is DHCP?

DHCP (Dynamic Host Configuration Protocol) automatically assigns IP addresses and network configuration to clients.

### How DHCP Works (DORA)

```
Client                    DHCP Server
  │                            │
  │ 1. DHCP Discover (broadcast) → │
  │                            │
  │ ← 2. DHCP Offer            │
  │                            │
  │ 3. DHCP Request →          │
  │                            │
  │ ← 4. DHCP Acknowledge      │
  │                            │
```

### Installing DHCP Server

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install isc-dhcp-server

# Fedora/RHEL
sudo dnf install dhcp-server
```

### Configuration

```bash
sudo cat /etc/dhcp/dhcpd.conf
```

```
# Global settings
option domain-name "example.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 600;
max-lease-time 7200;
authoritative;

# Subnet definition
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option broadcast-address 192.168.1.255;
}

# Static reservation
host printer {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 192.168.1.50;
}
```

### Key Configuration Directives

| Directive | Purpose |
|-----------|---------|
| `subnet` | Define a subnet with range |
| `range` | Pool of assignable IPs |
| `option routers` | Default gateway |
| `option domain-name-servers` | DNS servers |
| `default-lease-time` | Lease duration (seconds) |
| `max-lease-time` | Maximum lease duration |
| `host` | Static reservation for MAC |
| `fixed-address` | IP for static reservation |
| `authoritative` | This is the official DHCP server |

### Managing DHCP Server

```bash
# Start/stop/restart
sudo systemctl start isc-dhcp-server
sudo systemctl stop isc-dhcp-server
sudo systemctl restart isc-dhcp-server

# Enable on boot
sudo systemctl enable isc-dhcp-server

# Check status
sudo systemctl status isc-dhcp-server

# View leases
cat /var/lib/dhcp/dhcpd.leases
```

### DHCP Client

```bash
# Release and renew IP
sudo dhclient -r       # Release current lease
sudo dhclient          # Request new lease

# View DHCP info
ip addr show           # See assigned IP
ip route               # See default gateway
cat /etc/resolv.conf   # See DNS servers
```

---

## 🔍 Section 2: HTTP Server

### Apache vs Nginx

| Feature | Apache | Nginx |
|---------|--------|-------|
| Architecture | Process/thread-based | Event-driven |
| Memory usage | Higher | Lower |
| Static content | Good | Excellent |
| Dynamic content | Native (.htaccess) | Reverse proxy to FastCGI |
| Configuration | .htaccess per directory | Centralized config |
| Modules | Dynamic loading | Compiled in |

### Installing Apache

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install apache2

# Fedora/RHEL
sudo dnf install httpd
```

### Apache Basic Configuration

```bash
# Main config file (Debian/Ubuntu)
cat /etc/apache2/apache2.conf

# Main config file (RHEL/Fedora)
cat /etc/httpd/conf/httpd.conf
```

### Key Directives

```
# Document root
DocumentRoot /var/www/html

# Directory settings
<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# Virtual Host (name-based)
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/example
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

### Serving Content

```bash
# Default web root
sudo ls -la /var/www/html/

# Create a test page
echo "<h1>Hello from Linux Server!</h1>" | sudo tee /var/www/html/index.html

# Check it in browser
curl http://localhost
```

### Managing Apache

```bash
# Debian/Ubuntu
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl reload apache2

# RHEL/Fedora
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl reload httpd

# Check syntax
sudo apache2ctl configtest     # Debian
sudo httpd -t                  # RHEL
```

### Apache Virtual Hosts

```bash
# Create a site directory
sudo mkdir -p /var/www/example
echo "<h1>Example Site</h1>" | sudo tee /var/www/example/index.html

# Create virtual host config
sudo tee /etc/apache2/sites-available/example.conf << 'EOF'
<VirtualHost *:80>
    ServerName example.com
    DocumentRoot /var/www/example
    ErrorLog ${APACHE_LOG_DIR}/example-error.log
    CustomLog ${APACHE_LOG_DIR}/example-access.log combined
</VirtualHost>
EOF

# Enable site
sudo a2ensite example.conf

# Disable default
sudo a2dissite 000-default.conf

# Reload Apache
sudo systemctl reload apache2
```

---

## ⭐ Level 2: Intermediary — SSH and Service Management

![SSH protocol — secure remote access architecture](https://upload.wikimedia.org/wikipedia/commons/7/75/Secure_Shell_-_SSH_protocol.svg)

*Secure Shell (SSH) protocol architecture (Wikimedia Commons / public domain)*

> **Level 2 Goal:** Configure and harden an SSH server, manage network services with systemd, implement security best practices, and monitor service health.

## 🔍 Section 3: SSH Server

### Installing SSH Server

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install openssh-server

# Fedora/RHEL
sudo dnf install openssh-server

# Check status
sudo systemctl status sshd
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
Protocol 2                         # Only SSH protocol 2

PermitRootLogin no                 # No direct root login
PasswordAuthentication no          # Key-based authentication only
PubkeyAuthentication yes           # Enable key auth

AllowUsers alice bob               # Explicit user whitelist
MaxAuthTries 3                     # Limit attempts
MaxSessions 2                      # Limit concurrent sessions

LoginGraceTime 60                  # 60 seconds to complete login
ClientAliveInterval 300            # Check every 5 minutes
ClientAliveCountMax 0              # Disconnect on inactive

Banner /etc/issue.net              # Legal banner

# Use only strong key exchange algorithms
KexAlgorithms curve25519-sha256,diffie-hellman-group-exchange-sha256

# Log verbose
LogLevel VERBOSE
```

```bash
# After editing, restart
sudo systemctl restart sshd

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

### SSH Security Best Practices

```bash
# 1. Disable root login
# 2. Use key-based auth only
# 3. Change default port
# 4. Use fail2ban to block brute force
sudo apt install fail2ban

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

---

## 🔍 Section 4: Network Service Management

### systemd Service Management

```bash
# List all services
systemctl list-units --type=service

# List running services
systemctl list-units --type=service --state=running

# Start/stop/restart/reload
sudo systemctl start sshd
sudo systemctl stop sshd
sudo systemctl restart sshd
sudo systemctl reload sshd    # Load config without dropping connections

# Enable/disable at boot
sudo systemctl enable sshd
sudo systemctl disable sshd

# Check status
systemctl status sshd         # Shows whether running, recent logs
```

### Service Dependencies

```bash
# Show service dependencies
systemctl list-dependencies sshd

# Show what depends on this service
systemctl list-dependencies sshd --reverse

# Edit service override (don't edit the main unit file)
sudo systemctl edit sshd

# Show service file content
systemctl cat sshd
```

### Checking Ports and Sockets

```bash
# Check listening ports
sudo ss -tlnp     # TCP listening with process info
sudo ss -ulnp     # UDP listening
ss -tlnp | grep :80    # Check if HTTP is listening

# Alternative
sudo netstat -tlnp      # If netstat is installed

# Check socket units
systemctl list-sockets
```

---

## 🔍 Section 5: Securing Network Services

### Firewall Basics (ufw)

```bash
# Enable firewall
sudo ufw enable

# Allow services
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 2222/tcp    # Custom SSH port

# Deny/block
sudo ufw deny 23/tcp       # Block telnet

# Status
sudo ufw status verbose
sudo ufw status numbered

# Delete rule by number
sudo ufw delete 3

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### Firewall Basics (firewalld - RHEL/CentOS)

```bash
# Check status
sudo firewall-cmd --state

# List zones
sudo firewall-cmd --get-active-zones

# Add services
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --zone=public --add-port=2222/tcp --permanent

# Reload
sudo firewall-cmd --reload

# List rules
sudo firewall-cmd --list-all
```

### TCP Wrappers (Legacy)

```bash
# /etc/hosts.allow — Allow connections
sshd: 192.168.1.0/24
sshd: 10.0.0.0/8

# /etc/hosts.deny — Deny all other
sshd: ALL

# Note: TCP wrappers are deprecated. Use firewalld/ufw instead.
```

---

## 🔍 Section 6: Monitoring Network Services

### Service Monitoring

```bash
# Check service health
systemctl is-active sshd        # Returns active/inactive
systemctl is-enabled sshd       # Returns enabled/disabled
systemctl is-failed sshd        # Returns failed/active

# Check if port is responding
nc -zv localhost 22
nc -zv localhost 80

# Check if service is accepting connections
curl -I http://localhost

# Monitor logs
journalctl -u sshd -n 20 --no-pager
journalctl -u apache2 -n 20 --no-pager
journalctl -u isc-dhcp-server -n 20 --no-pager

# Follow logs in real-time
sudo journalctl -u sshd -f
```

### Resource Monitoring

```bash
# Check process resource usage
ps aux | grep sshd
ps aux | grep apache2

# Check memory usage
systemd-cgtop

# Check open files per service
sudo lsof -i :22
sudo lsof -i :80
```

---

## ⭐ Level 3: Advanced — Troubleshooting and Internals

![TCP/IP model and protocol layers](https://upload.wikimedia.org/wikipedia/commons/c/c4/OSI_Model_v1.svg)

*OSI model — network communication layers (Wikimedia Commons / public domain)*

> **Level 3 Goal:** Diagnose and resolve complex service failures, understand service internals, and develop systematic troubleshooting approaches.

## 🔍 Section 7: Troubleshooting Network Services

### Troubleshooting Methodology

```
1. CHECK — Is the service running?
   systemctl status service-name

2. CHECK — Is it listening on the right port?
   ss -tlnp | grep PORT

3. CHECK — Is the firewall allowing it?
   sudo ufw status
   sudo firewall-cmd --list-all

4. CHECK — Can localhost connect?
   nc -zv localhost PORT
   curl http://localhost

5. CHECK — Can other hosts connect?
   From client: nc -zv SERVER-IP PORT

6. CHECK — Are logs showing errors?
   journalctl -u service-name -n 50
```

### Common Problems

**Problem 1: Service won't start**

```bash
# Check systemd status
sudo systemctl status service-name

# Check journal for errors
sudo journalctl -xe -u service-name

# Check config syntax
sudo sshd -t               # SSH
sudo apache2ctl configtest  # Apache
sudo nginx -t               # Nginx
sudo dhcpd -t               # DHCP
```

**Problem 2: Service running but not responding**

```bash
# Check if it's listening
ss -tlnp | grep PORT

# Check firewall
sudo ufw status verbose

# Check if bound to wrong interface
ss -tlnp | grep "0.0.0.0:PORT"  # All interfaces
ss -tlnp | grep "127.0.0.1:PORT" # Localhost only

# Check if address already in use
sudo netstat -tlnp | grep PORT
```

**Problem 3: DHCP not assigning IPs**

```bash
# Check DHCP server status
sudo systemctl status isc-dhcp-server

# Check config
sudo dhcpd -t

# Check leases
cat /var/lib/dhcp/dhcpd.leases | tail -20

# Check if another DHCP server is on the network (rogue DHCP)
sudo tcpdump -i eth0 port 67 or port 68 -n
```

**Problem 4: Apache not serving pages**

```bash
# Check Apache status
sudo systemctl status apache2

# Check error log
sudo tail -50 /var/log/apache2/error.log

# Check access log
sudo tail -50 /var/log/apache2/access.log

# Check if DocumentRoot exists and has proper permissions
ls -la /var/www/html/

# Check Apache can read the files
sudo -u www-data ls -la /var/www/html/

# Check .htaccess isn't blocking
# Temporarily rename .htaccess to test
```

**Problem 5: SSH connection refused**

```bash
# On server:
sudo systemctl status sshd
ss -tlnp | grep 22         # Check if SSH is listening
sudo sshd -t               # Check config
sudo journalctl -u sshd -n 20

# On client:
ssh -vvv user@server       # Verbose debug output
nc -zv server 22           # Check basic connectivity
telnet server 22           # Check raw socket
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### Level 1 Practices: DHCP and HTTP

---

### ✅ Practice 1: Install and Configure DHCP Server (Simulated)

```bash
mkdir -p ~/linux-course/part22
cd ~/linux-course/part22

# Create a simulated DHCP config
cat << 'EOF' > dhcpd_simulated.conf
# Simulated DHCP Server Configuration
# /etc/dhcp/dhcpd.conf

option domain-name "class.local";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option broadcast-address 192.168.1.255;
}

host webserver {
    hardware ethernet aa:bb:cc:dd:ee:01;
    fixed-address 192.168.1.10;
}

host printer {
    hardware ethernet aa:bb:cc:dd:ee:02;
    fixed-address 192.168.1.20;
}
EOF

echo "Simulated DHCP config created"
echo "Range: 192.168.1.100-200"
echo "Static: webserver (.10), printer (.20)"
```

---

### ✅ Practice 2: Set Up a Test HTTP Server

```bash
cd ~/linux-course/part22

# Create a simple Python HTTP server (no root needed)
mkdir -p www_test
echo "<html><body><h1>Linux Course Test Page</h1>
<p>Server time: $(date)</p>
<p>Hostname: $(hostname)</p>
</body></html>" > www_test/index.html

# Start a temporary HTTP server (port 8080 to avoid needing root)
echo "Starting test HTTP server on port 8080..."
echo "Open another terminal and run: curl http://localhost:8080"
python3 -m http.server 8080 --directory www_test &
HTTP_PID=$!
sleep 1

# Test it
echo ""
echo "Testing HTTP server..."
curl -s http://localhost:8080 | head -5

# Cleanup
kill $HTTP_PID 2>/dev/null
echo ""
echo "Test server stopped."
```

---

### ✅ Practice 3: Explore Apache Configuration

```bash
cd ~/linux-course/part22

if command -v apache2 &>/dev/null; then
    echo "=== Apache config test ==="
    sudo apache2ctl configtest 2>&1 || echo "Config test failed"
    
    echo ""
    echo "=== Loaded modules ==="
    apache2ctl -M 2>/dev/null | head -20
    
    echo ""
    echo "=== Document root ==="
    grep -i "documentroot" /etc/apache2/sites-enabled/*.conf 2>/dev/null
elif command -v httpd &>/dev/null; then
    echo "=== Apache (httpd) config test ==="
    sudo httpd -t 2>&1
    
    echo ""
    echo "=== Loaded modules ==="
    httpd -M 2>/dev/null | head -20
else
    echo "Apache not installed — creating reference config"
    mkdir -p reference
    cat << 'EOF' > reference/apache_vhost.conf
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/example
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    echo "Reference virtual host config created"
fi
```

---

### ✅ Practice 5: Verify Apache Web Root

```bash
cd ~/linux-course/part22

if [ -d /var/www/html ]; then
    echo "=== Web root contents ==="
    ls -la /var/www/html/
    
    echo ""
    echo "=== Test default page ==="
    curl -s http://localhost | head -10
else
    echo "Apache default web root not found"
    echo "Expected: /var/www/html"
fi
```

---

### ✅ Practice 7: Create a Virtual Host Config

```bash
cd ~/linux-course/part22

# Create a virtual host configuration file (for learning)
cat << 'EOF' > vhost_example.conf
<VirtualHost *:80>
    ServerName linuxcourse.local
    DocumentRoot /var/www/linuxcourse
    ErrorLog /var/log/apache2/linuxcourse-error.log
    CustomLog /var/log/apache2/linuxcourse-access.log combined
    
    <Directory /var/www/linuxcourse>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

echo "Virtual host config created"
echo "To use this:"
echo "  1. sudo cp vhost_example.conf /etc/apache2/sites-available/"
echo "  2. sudo a2ensite vhost_example"
echo "  3. sudo systemctl reload apache2"
echo ""
echo "Virtual host breakdown:"
echo "  ServerName:  Domain this site responds to"
echo "  DocumentRoot: Where files are stored"
echo "  ErrorLog:     Error log location"
echo "  Directory:    Access permissions for this path"
```

---

### Level 2 Practices: SSH and Service Management

---

### ✅ Practice 4: Explore SSH Server Configuration

```bash
cd ~/linux-course/part22

if [ -f /etc/ssh/sshd_config ]; then
    echo "=== SSH Server Config ==="
    sudo cat /etc/ssh/sshd_config | grep -v "^#" | grep -v "^$"
    
    echo ""
    echo "=== SSH Server Status ==="
    sudo systemctl status sshd | head -10
else
    echo "SSH server not installed"
fi
```

---

### ✅ Practice 6: Generate SSH Key Pair

```bash
cd ~/linux-course/part22

# Generate a test SSH key (in a temp dir, not replacing existing keys)
mkdir -p ssh_key_test
ssh-keygen -t ed25519 -f ssh_key_test/test_key -N "" -C "test@linuxcourse" -q

echo "=== Generated SSH Key Pair ==="
echo "Private key: ssh_key_test/test_key"
echo "Public key:  ssh_key_test/test_key.pub"
echo ""
echo "Public key contents:"
cat ssh_key_test/test_key.pub
echo ""
echo "=== Key details ==="
ssh-keygen -l -f ssh_key_test/test_key

# Cleanup
rm -rf ssh_key_test
```

---

### ✅ Practice 8: Harden SSH Configuration

```bash
cd ~/linux-course/part22

# Create a hardened SSH config for reference
cat << 'EOF' > hardened_sshd_config.txt
# Security-hardened SSH configuration
# /etc/ssh/sshd_config

Port 2222                          # Non-default port
Protocol 2                         # Only protocol 2

PermitRootLogin no                 # Block root direct login
PasswordAuthentication no          # Key-based auth only
PubkeyAuthentication yes           # Enable key auth

AllowUsers alice bob               # User whitelist
MaxAuthTries 3                     # Limit brute force attempts
MaxSessions 2                      # Limit concurrent sessions

LoginGraceTime 60                  # Timeout for login
ClientAliveInterval 300            # Check every 5 min
ClientAliveCountMax 0              # Disconnect when idle

Banner /etc/issue.net              # Legal banner

LogLevel VERBOSE                   # Verbose logging
EOF

echo "Hardened SSH configuration created"
echo "=== Key security changes from defaults ==="
echo "1. Port changed from 22 to 2222 (reduces automated attacks)"
echo "2. Root login disabled (use sudo instead)"
echo "3. Password auth disabled (keys only)"
echo "4. User whitelist (only specific users)"
echo "5. Login grace time reduced to 60s"
```

---

### ✅ Practice 9: Service Management with systemd

```bash
cd ~/linux-course/part22

echo "=== All running services ==="
systemctl list-units --type=service --state=running | head -15

echo ""
echo "=== Network-related services ==="
systemctl list-units --type=service --state=running | grep -E "ssh|apache|http|nginx|dhcp"

echo ""
echo "=== Service dependency example: sshd ==="
if systemctl is-active sshd &>/dev/null; then
    systemctl list-dependencies sshd | head -10
fi

echo ""
echo "=== Listening sockets ==="
ss -tlnp 2>/dev/null | head -10
```

---

### ✅ Practice 10: Firewall Rules Exploration

```bash
cd ~/linux-course/part22

echo "=== ufw status ==="
if command -v ufw &>/dev/null; then
    sudo ufw status verbose 2>/dev/null || echo "ufw inactive or not enabled"
fi

echo ""
echo "=== firewalld status ==="
if command -v firewall-cmd &>/dev/null; then
    sudo firewall-cmd --state 2>/dev/null || echo "firewalld not running"
    sudo firewall-cmd --list-all 2>/dev/null || true
fi

echo ""
echo "=== Common service ports ==="
echo "  SSH:       22/tcp"
echo "  HTTP:      80/tcp"
echo "  HTTPS:     443/tcp"
echo "  DHCP:      67/udp, 68/udp"
echo "  DNS:       53/udp, 53/tcp"
```

---

### ✅ Practice 11: Create a Service Monitoring Script

```bash
cd ~/linux-course/part22

cat > check_services.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "============================================"
echo "  Network Service Check at $(date)"
echo "============================================"

# List of services to check
SERVICES="sshd apache2 httpd nginx isc-dhcp-server"

for service in $SERVICES; do
    if systemctl is-active "$service" &>/dev/null; then
        STATUS="RUNNING"
        PORT_INFO=$(systemctl cat "$service" 2>/dev/null | grep -i "port\|listen" | head -1 || true)
        echo "  ✅ $service: $STATUS"
    else
        echo "  ⬜ $service: not found/inactive"
    fi
done

echo ""
echo "=== Listening Ports ==="
ss -tlnp 2>/dev/null | awk '{print $4, $1}' | sed 's/.*://' | sort -n | uniq

echo ""
echo "============================================"
EOF

chmod +x check_services.sh
./check_services.sh
```

---

### ✅ Practice 13: Secure Copy with SCP

```bash
cd ~/linux-course/part22

# Create a test file
echo "This is a test file for SCP" > scp_test.txt

# Show how SCP works (without actually connecting)
echo "=== SCP Usage Examples ==="
echo ""
echo "# Upload file to server"
echo "scp scp_test.txt user@server:/home/user/"
echo ""
echo "# Download file from server"
echo "scp user@server:/home/user/scp_test.txt ."
echo ""
echo "# Upload directory recursively"
echo "scp -r mydir/ user@server:/home/user/"
echo ""
echo "# Using non-standard port"
echo "scp -P 2222 scp_test.txt user@server:/home/user/"
echo ""
echo "# Using identity file"
echo "scp -i ~/.ssh/id_ed25519 scp_test.txt user@server:/home/user/"

rm scp_test.txt
```

---

### ✅ Practice 14: Test SSH Connection with Verbose Mode

```bash
cd ~/linux-course/part22

echo "=== SSH Verbose Mode ==="
echo "To debug SSH connection issues, use -vvv:"
echo ""
echo "ssh -vvv user@hostname"
echo ""
echo "This shows:"
echo "  1. Which key files are being tried"
echo "  2. Authentication methods attempted"
echo "  3. DNS resolution results"
echo "  4. Connection negotiation details"
echo "  5. Where the connection fails"
echo ""
echo "=== Common SSH Problems and Verbose Output ==="
echo ""
echo "Permission denied (publickey):"
echo "  Server doesn't have your public key"
echo "  Check: ssh-copy-id user@server"
echo ""
echo "Connection refused:"
echo "  Server not running SSH or firewall blocking"
echo "  Check: systemctl status sshd on server"
echo ""
echo "Connection timed out:"
echo "  Network issue or wrong IP address"
echo "  Check: nc -zv server-ip 22"
```

---

### Level 3 Practices: Advanced Troubleshooting

---

### ✅ Practice 12: Diagnose Service Failure — Scenario

```bash
cd ~/linux-course/part22

cat << 'EOF' > troubleshoot_scenario.txt
=== TROUBLESHOOTING SCENARIO ===

A user reports: "I can't access the company website at http://webserver"

Your task: Walk through the diagnosis steps.

Step 1 — Is the service running?
  systemctl status apache2 (or httpd)
  
Step 2 — Is it listening on port 80?
  ss -tlnp | grep :80

Step 3 — Is the firewall allowing HTTP?
  sudo ufw status
  
Step 4 — Can localhost access it?
  curl http://localhost

Step 5 — Can other hosts access it?
  From client: curl http://webserver

Step 6 — What do the logs say?
  sudo journalctl -u apache2 -n 50
  sudo tail /var/log/apache2/error.log

Common solutions:
  a) Start the service: sudo systemctl start apache2
  b) Open firewall: sudo ufw allow http
  c) Fix config: sudo apache2ctl configtest
  d) Restart: sudo systemctl restart apache2
  e) Check DNS: host webserver from client
EOF

echo "Troubleshooting scenario created"
echo "Run through the scenario and identify the issue"

# Apply the scenario interactively
echo ""
echo "=== Testing connectivity to web server ==="
if command -v apache2 &>/dev/null || command -v httpd &>/dev/null; then
    echo "Apache found — testing..."
    curl -sI http://localhost 2>/dev/null | head -3 || echo "No response from Apache"
else
    echo "No web server installed — review the scenario only"
fi
```

---

### ✅ Practice 15: Comprehensive Network Services Audit

```bash
cd ~/linux-course/part22

cat > network_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="network_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  NETWORK SERVICES AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Running services
echo "1. RUNNING SERVICES" >> "$REPORT"
systemctl list-units --type=service --state=running --no-legend | awk '{print $1}' | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: Listening ports
echo "2. LISTENING PORTS" >> "$REPORT"
ss -tlnp 2>/dev/null | awk 'NR>1 {print $4, $1, $7}' | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: Firewall status
echo "3. FIREWALL STATUS" >> "$REPORT"
if command -v ufw &>/dev/null; then
    ufw status verbose 2>/dev/null | sed 's/^/  /' >> "$REPORT" || echo "  ufw inactive" >> "$REPORT"
elif command -v firewall-cmd &>/dev/null; then
    firewall-cmd --list-all 2>/dev/null | sed 's/^/  /' >> "$REPORT" || echo "  firewalld inactive" >> "$REPORT"
else
    echo "  No firewall tool found" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 4: Network config
echo "4. NETWORK CONFIGURATION" >> "$REPORT"
ip addr show | grep "inet " | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"
ip route show default | sed 's/^/  Default: /' >> "$REPORT"
echo "" >> "$REPORT"

# Section 5: DNS
echo "5. DNS CONFIGURATION" >> "$REPORT"
cat /etc/resolv.conf 2>/dev/null | grep -v "^#" | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: Service status of key services
echo "6. KEY SERVICES" >> "$REPORT"
for svc in sshd apache2 httpd nginx isc-dhcp-server; do
    status=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
    printf "  %-20s %s\n" "$svc" "$status" >> "$REPORT"
done
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF AUDIT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x network_audit.sh
./network_audit.sh
```

---

## 🧠 Deep Understanding — Network Services Internals

### How SSH Authentication Works

```
1. Client connects to server
2. Server sends its host key (public)
3. Client checks known_hosts for server's key
4. Key exchange establishes encrypted channel
5. Client authenticates:

   Option A: Password
   - Client sends password (encrypted)
   - Server checks against /etc/shadow

   Option B: Public Key
   - Client proves possession of private key
   - Server checks ~/.ssh/authorized_keys
   
   Option C: Certificate
   - Signed certificate presented
   - Server validates CA signature

6. Session begins (encrypted)
```

### How DHCP Works in Detail

```
DHCP offers more than just an IP address:

Option 1:  Subnet mask (255.255.255.0)
Option 3:  Default gateway (192.168.1.1)
Option 6:  DNS servers (8.8.8.8)
Option 15: Domain name (example.com)
Option 42: NTP servers
Option 66: TFTP server (for PXE boot)
Option 67: Boot file (for PXE boot)
```

### Service Management Best Practices

```
1. Use systemd service files, not init scripts
   - Consistent interface across all services
   - Proper dependency handling
   - Resource control (CPU, memory limits)

2. Enable on boot only for services that need it
   - systemctl enable → Starts at boot
   - Just because it's installed doesn't mean it should run

3. Use relicate instead of restart when possible
   - reload: Re-read config without dropping connections
   - restart: Drop connections, start fresh

4. Logs go to journald, not just files
   - journalctl -u service for service-specific logs
   - journalctl -f for real-time monitoring
```

---

## 📋 Summary — Complete Command Reference for Part 22

### Level 1: Basic Commands — DHCP and HTTP

| Command | Action |
|---------|--------|
| `sudo systemctl start isc-dhcp-server` | Start DHCP server |
| `sudo systemctl start apache2` | Start Apache (Debian) |
| `sudo systemctl start httpd` | Start Apache (RHEL) |
| `curl http://localhost` | Test web server locally |
| `cat /var/lib/dhcp/dhcpd.leases` | View DHCP leases |

### Level 2: Intermediary Commands — SSH and Service Management

| Command | Action |
|---------|--------|
| `ss -tlnp` | List listening TCP ports |
| `sudo sshd -t` | Test SSH config validity |
| `ssh-keygen -t ed25519` | Generate SSH key pair |
| `ssh-copy-id user@host` | Copy public key to server |
| `sudo journalctl -u sshd -f` | Follow SSH logs |
| `sudo ufw allow ssh` | Allow SSH in firewall |

### Level 3: Advanced Commands — Troubleshooting

| Command | Action |
|---------|--------|
| `ssh -vvv user@host` | Verbose SSH debug |
| `nc -zv host port` | Test port connectivity |
| `tcpdump -i eth0 port 67` | Capture DHCP traffic |
| `sudo strace -p PID` | Trace service system calls |

---

## 🚀 What's Coming in Part 23

**Part 23: Virtual Terminals and Console Management**

You will learn:
- Linux virtual terminals (tty)
- Console configuration and management
- Terminal multiplexers (screen, tmux)
- Serial console setup
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What does DHCP stand for and what does it do?
2. What are the four steps of the DORA process?
3. How do you create an Apache virtual host?
4. What is the difference between Apache and Nginx?
5. How do you harden SSH server configuration?
6. What does `PermitRootLogin no` accomplish?
7. How do you generate an SSH key pair?
8. What is the purpose of `ssh-copy-id`?
9. How do you check which ports a service is listening on?
10. What is the difference between `systemctl reload` and `systemctl restart`?
11. How do you allow HTTP through ufw?
12. What does `ssh -L 8080:localhost:80 user@host` do?
13. How do you check the status of a service in systemd?
14. What is the key difference between SSH password and public key auth?
15. How would you troubleshoot a service that won't start?

**Score:** 12/15 correct = ready for Part 23.

---

*Linux SysAdmin Course | Part 22 of ∞ | Reverse Engineering Approach*
*Previous → Part 21: Time Synchronization — NTP and Chrony*
*Next → Part 23: Virtual Terminals and Console Management*

[← Previous](part21.md) | [Next →](part23.md)
