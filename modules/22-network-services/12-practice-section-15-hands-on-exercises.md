## 💻 PRACTICE SECTION — 15 Hands-On Exercises


### Level 1 Practices: DHCP and HTTP


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


### Level 2 Practices: SSH and Service Management


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


### Level 3 Practices: Advanced Troubleshooting


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





[← Previous](11-section-7-troubleshooting-network-services.md) | [↑ Index](index.md) | [Next →](13-deep-understanding-network-services-internals.md)
