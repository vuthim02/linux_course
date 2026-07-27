## 6. fail2ban — Automated Intrusion Prevention

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      fail2ban ARCHITECTURE                    │
│                                                               │
│  Log Files                                                   │
│  /var/log/auth.log ◄──┐                                     │
│  /var/log/nginx/      │    ┌──────────────┐                  │
│  access.log    ───────┼───►│  fail2ban    │                  │
│  /var/log/apache2/    │    │  Server      │                  │
│  access.log    ───────┘    │              │                  │
│                            │  ┌────────┐  │                  │
│                            │  │ Filter │  │  Match patterns  │
│                            │  │ Engine │  │  in logs         │
│                            │  └────────┘  │                  │
│                            │  ┌────────┐  │                  │
│                            │  │  Jail  │  │  Ban rules       │
│                            │  │ Manager│  │                  │
│                            │  └────────┘  │                  │
│                            │  ┌────────┐  │                  │
│                            │  │ Action │  │  iptables/nft    │
│                            │  │ Engine │  │  + email + more  │
│                            │  └────────┘  │                  │
│                            └──────┬───────┘                  │
│                                   │                           │
│                            iptables/nftables                  │
│                            BAN <IP> for N seconds             │
└─────────────────────────────────────────────────────────────┘
```

### Installation

```bash
# Debian/Ubuntu
apt install fail2ban -y

# RHEL/CentOS (EPEL)
yum install epel-release -y
yum install fail2ban fail2ban-systemd -y

# Start (do NOT enable on RHEL — firewall conflict)
systemctl enable --now fail2ban

# Verify
fail2ban-client status
```

### Core Configuration

```bash
# NEVER edit /etc/fail2ban/jail.conf — it gets overwritten
# Create local overrides in /etc/fail2ban/jail.local

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban for 1 hour
bantime = 3600

# Detection window: 10 minutes
findtime = 600

# Ban after 5 failures
maxretry = 5

# Use systemd (modern) or syslog
backend = systemd

# Action: ban + email
banaction = iptables-multiport
action = %(action_mwl)s

# Whitelist local network and trusted IPs
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 10.0.0.0/8

# SSH jail (enabled by default)
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
```

### Custom Jail: Nginx Brute Force

```bash
# Filter: /etc/fail2ban/filter.d/nginx-bruteforce.conf
cat > /etc/fail2ban/filter.d/nginx-bruteforce.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "(GET|POST|HEAD) .* HTTP/.*" (401|403) .*$
ignoreregex =
EOF

# Jail: add to /etc/fail2ban/jail.local
cat >> /etc/fail2ban/jail.local << 'EOF'
[nginx-bruteforce]
enabled  = true
port     = http,https
filter   = nginx-bruteforce
logpath  = /var/log/nginx/access.log
maxretry = 10
findtime = 300
bantime  = 3600
EOF

# Reload
fail2ban-client reload
```

### Custom Jail: WordPress Login

```bash
# /etc/fail2ban/filter.d/wordpress-login.conf
cat > /etc/fail2ban/filter.d/wordpress-login.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST /wp-login.php.*" 200 .*$
ignoreregex =
EOF

# Add jail
cat >> /etc/fail2ban/jail.local << 'EOF'
[wordpress-login]
enabled  = true
port     = http,https
filter   = wordpress-login
logpath  = /var/log/nginx/access.log
maxretry = 5
findtime = 600
bantime  = 7200
EOF
```

### Custom Action Script

```bash
# /etc/fail2ban/action.d/custom-alert.action
cat > /etc/fail2ban/action.d/custom-alert.action << 'ACTION'
[Definition]

actionstart =
actionstop =
actioncheck =

actionban = echo "<hostname> banned <ip> for <failures> failures at $(date)" >> /var/log/fail2ban-custom.log
            curl -s -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
              -d '{"text":"Banned <ip> on <hostname> (<failures> failures)"}'

actionunban = echo "<hostname> unbanned <ip> at $(date)" >> /var/log/fail2ban-custom.log
ACTION

# Reference in jail
# [sshd]
# action = %(action_)s custom-alert
```

### Managing fail2ban

```bash
# Status of all jails
fail2ban-client status

# Status of specific jail
fail2ban-client status sshd

# Manually unban an IP
fail2ban-client set sshd unbanip 192.168.1.100

# Manually ban an IP
fail2ban-client set sshd banip 10.0.0.50

# Check banned IPs
iptables -L f2b-sshd -n --line-numbers

# Test a filter against a log
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# View fail2ban logs
journalctl -u fail2ban -f
```

---



---

[← Previous](07-cis-hardening-audit-rules.md) | [↑ Index](index.md) | [Next →](09-7-lynis-security-auditing-and.md)
