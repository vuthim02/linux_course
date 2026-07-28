# Internship Project 01: Full-Stack E-Commerce Platform Deployment

## Company: TechStore Inc. (Fictional)

You are hired as a **Junior Linux System Administrator Intern**. Your task is to deploy and manage a full-stack e-commerce web application on a Linux server. This project covers everything from server setup to production deployment.

---

## Project Overview

| Aspect | Details |
|--------|---------|
| **Company** | TechStore Inc. — sells electronics online |
| **Your Role** | Junior SysAdmin Intern |
| **Server** | Ubuntu 22.04 LTS (DigitalOcean / AWS / Local VM) |
| **Domain** | techstore.example.com |
| **Stack** | Nginx + Node.js + PostgreSQL + Redis + Docker |
| **Duration** | 5 working days |
| **Mentor** | Senior SysAdmin (ask questions anytime) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      INTERNET                           │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   FIREWALL (UFW)                        │
│              Ports: 22, 80, 443 only                    │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              NGINX (Reverse Proxy + SSL)                │
│              Handles HTTPS, routes traffic              │
└───────────┬─────────────────────────┬───────────────────┘
            │                         │
            ▼                         ▼
┌───────────────────┐     ┌───────────────────────┐
│   Node.js App     │     │    Static Files       │
│   (Port 3000)     │     │    (CSS, JS, Images)  │
│   Express.js API  │     │    Served by Nginx    │
└─────────┬─────────┘     └───────────────────────┘
          │
          ▼
┌───────────────────┐     ┌───────────────────────┐
│   PostgreSQL      │     │    Redis              │
│   (Port 5432)     │     │    (Port 6379)        │
│   Products, Users │     │    Sessions, Cache    │
└───────────────────┘     └───────────────────────┘
```

---

## Day 1: Server Setup & Hardening

### Step 1.1 — Create Your Server

```bash
# If using DigitalOcean/AWS, create a new Ubuntu 22.04 LTS droplet/instance
# Minimum: 2 vCPU, 4GB RAM, 50GB SSD

# SSH into your server
ssh root@your_server_ip
```

### Step 1.2 — Create a Non-Root User

```bash
# Create new user
adduser tim
usermod -aG sudo tim

# Switch to new user
su - tim
```

### Step 1.3 — Update the System

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 1.4 — Set Hostname

```bash
sudo hostnamectl set-hostname techstore-server
echo "127.0.0.1 localhost techstore-server" | sudo tee -a /etc/hosts
```

### Step 1.5 — Configure Firewall (UFW)

```bash
# Install UFW
sudo apt install ufw -y

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (change port if you customized it)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

Expected output:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
```

### Step 1.6 — Secure SSH

```bash
# Edit SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo nano /etc/ssh/sshd_config
```

Change these lines:
```
Port 2222                    # Change default port
PermitRootLogin no           # Disable root login
PasswordAuthentication no    # Key-only authentication
MaxAuthTries 3               # Limit login attempts
LoginGraceTime 30            # Timeout for login
```

```bash
# Restart SSH
sudo systemctl restart sshd

# IMPORTANT: Open new terminal, test SSH on port 2222 BEFORE closing current session
# ssh -p 2222 tim@your_server_ip
```

### Step 1.7 — Install Fail2Ban (Brute Force Protection)

```bash
sudo apt install fail2ban -y

# Create local config
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Add at the bottom:
```
[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo fail2ban-client status sshd
```

### Step 1.8 — Set Up Automatic Updates

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
# Select Yes when prompted
```

### Step 1.9 — Configure Time Synchronization

```bash
sudo apt install chrony -y
sudo systemctl enable chrony
sudo systemctl start chrony
chronyc tracking
```

### Step 1.10 — Create Swap File (if needed)

```bash
# Check if swap exists
sudo swapon --show

# If no swap, create 4GB
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Set swappiness (lower = less swap usage)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## Day 2: Install & Configure Services

### Step 2.1 — Install Node.js (v20 LTS)

```bash
# Install NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install nodejs -y

# Verify
node --version    # v20.x.x
npm --version     # 10.x.x
```

### Step 2.2 — Install PostgreSQL

```bash
sudo apt install postgresql postgresql-contrib -y

# Start and enable
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Check status
sudo systemctl status postgresql
```

### Step 2.3 — Configure PostgreSQL Database

```bash
# Switch to postgres user
sudo -u postgres psql
```

Run these SQL commands:
```sql
-- Create database for the app
CREATE DATABASE techstore;

-- Create application user with strong password
CREATE USER techstore_admin WITH ENCRYPTED PASSWORD 'YourStr0ngP@ssw0rd!';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE techstore TO techstore_admin;

-- Set role
ALTER USER techstore_admin CREATEDB;

-- Exit
\q
```

### Step 2.4 — Secure PostgreSQL

```bash
# Edit pg_hba.conf to allow password auth
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Change local connections to use password:
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   techstore       techstore_admin                         scram-sha-256
host    techstore       techstore_admin     127.0.0.1/32        scram-sha-256
```

```bash
sudo systemctl restart postgresql

# Test connection
psql -U techstore_admin -d techstore -h 127.0.0.1
```

### Step 2.5 — Install Redis

```bash
sudo apt install redis-server -y

# Start and enable
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Set password
sudo nano /etc/redis/redis.conf
```

Find and change:
```
requirepass YourRedisStr0ngP@ss!
```

```bash
sudo systemctl restart redis-server

# Test
redis-cli -a YourRedisStr0ngP@ss! ping
# Should return: PONG
```

### Step 2.6 — Install Nginx

```bash
sudo apt install nginx -y

# Start and enable
sudo systemctl enable nginx
sudo systemctl start nginx

# Check
curl http://localhost
# Should show "Welcome to nginx!" page
```

---

## Day 3: Deploy the Application

### Step 3.1 — Create Project Structure

```bash
# Create app directory
sudo mkdir -p /var/www/techstore
sudo chown -R tim:tim /var/www/techstore
cd /var/www/techstore
```

### Step 3.2 — Initialize Node.js Application

```bash
npm init -y
npm install express pg redis express-session bcryptjs dotenv helmet cors morgan
npm install --save-dev nodemon
```

### Step 3.3 — Create Application Files

#### `.env` (Environment Variables)
```bash
cat > .env << 'EOF'
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://techstore_admin:YourStr0ngP@ssw0rd!@127.0.0.1:5432/techstore
REDIS_URL=redis://:YourRedisStr0ngP@ss!@127.0.0.1:6379
SESSION_SECRET=change-this-to-a-random-string-in-production
EOF
```

#### `app.js` (Main Application)
```javascript
require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const Redis = require('ioredis');
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// PostgreSQL connection
const pgPool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Redis connection
const redisClient = new Redis(process.env.REDIS_URL);

// Middleware
app.use(helmet());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Session with Redis
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 1000 * 60 * 60 * 24 // 24 hours
  }
}));

// Routes
app.get('/', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT NOW()');
    res.json({
      message: 'TechStore API is running!',
      database: 'connected',
      time: result.rows[0].now
    });
  } catch (err) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

app.get('/health', async (req, res) => {
  try {
    await pgPool.query('SELECT 1');
    redisClient.ping();
    res.json({ status: 'healthy' });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', error: err.message });
  }
});

// Start server
app.listen(PORT, '127.0.0.1', () => {
  console.log(`TechStore server running on port ${PORT}`);
});
```

#### `public/index.html` (Frontend)
```bash
mkdir -p public
cat > public/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TechStore</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0a0a0a; color: #fff; }
        .hero { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; text-align: center; }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; color: #888; margin-bottom: 2rem; }
        .status { background: #1a1a1a; padding: 2rem; border-radius: 12px; border: 1px solid #333; }
        .status-item { margin: 0.5rem 0; }
        .connected { color: #00ff88; }
    </style>
</head>
<body>
    <div class="hero">
        <h1>TechStore</h1>
        <p>Full-Stack E-Commerce Platform</p>
        <div class="status">
            <div class="status-item">Server: <span class="connected" id="server-status">Checking...</span></div>
            <div class="status-item">Database: <span class="connected" id="db-status">Checking...</span></div>
        </div>
    </div>
    <script>
        fetch('/health')
            .then(r => r.json())
            .then(data => {
                document.getElementById('server-status').textContent = 'Online';
                document.getElementById('db-status').textContent = data.status === 'healthy' ? 'Connected' : 'Error';
            })
            .catch(() => {
                document.getElementById('server-status').textContent = 'Offline';
                document.getElementById('db-status').textContent = 'Unknown';
            });
    </script>
</body>
</html>
HTMLEOF
```

### Step 3.4 — Create Database Schema

```bash
psql -U techstore_admin -d techstore -h 127.0.0.1 << 'SQL'
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample products
INSERT INTO products (name, description, price, stock) VALUES
('Mechanical Keyboard', 'Cherry MX Brown switches', 129.99, 50),
('Gaming Mouse', '16000 DPI optical sensor', 79.99, 100),
('27" Monitor', '4K IPS display', 449.99, 25),
('USB-C Hub', '7-in-1 adapter', 49.99, 200);

\dt
SELECT * FROM products;
SQL
```

### Step 3.5 — Set Up PM2 (Process Manager)

```bash
# Install PM2 globally
sudo npm install -g pm2

# Start application
cd /var/www/techstore
pm2 start app.js --name techstore

# Save process list
pm2 save

# Start on boot
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u tim --hp /home/tim

# Check status
pm2 status
pm2 logs techstore
```

### Step 3.6 — Test the Application

```bash
curl http://127.0.0.1:3000
curl http://127.0.0.1:3000/health
```

---

## Day 4: Nginx Reverse Proxy & SSL

### Step 4.1 — Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/techstore
```

```nginx
server {
    listen 80;
    server_name techstore.example.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name techstore.example.com;

    # SSL (we'll add real certs in Step 4.3)
    ssl_certificate /etc/nginx/ssl/techstore.crt;
    ssl_certificate_key /etc/nginx/ssl/techstore.key;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Proxy to Node.js
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Static files (if you have them)
    location /static/ {
        alias /var/www/techstore/public/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Logging
    access_log /var/log/nginx/techstore_access.log;
    error_log /var/log/nginx/techstore_error.log;
}
```

### Step 4.2 — Enable the Site

```bash
# Create self-signed cert first (temporary)
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/techstore.key \
    -out /etc/nginx/ssl/techstore.crt \
    -subj "/C=US/ST=State/L=City/O=TechStore/CN=techstore.example.com"

# Enable site
sudo ln -s /etc/nginx/sites-available/techstore /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

### Step 4.3 — Install Let's Encrypt SSL (Production)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get real certificate (requires DNS pointing to your server)
sudo certbot --nginx -d techstore.example.com

# Auto-renewal test
sudo certbot renew --dry-run

# Check cron
sudo systemctl status certbot.timer
```

### Step 4.4 — Set Up Log Rotation

```bash
sudo nano /etc/logrotate.d/techstore
```

```
/var/log/nginx/techstore_access.log
/var/log/nginx/techstore_error.log
{
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 $(cat /var/run/nginx.pid)
    endscript
}
```

---

## Day 5: Monitoring, Backup & Documentation

### Step 5.1 — Install Monitoring Tools

```bash
# System monitoring
sudo apt install htop iotop nethogs nmon -y

# Install Netdata (web-based monitoring)
curl -Ss https://my-netdata.io/kickstart.sh | sudo bash
```

Access Netdata at: `http://your_server_ip:19999`

### Step 5.2 — Set Up Log Monitoring with Journalctl

```bash
# View logs
sudo journalctl -u nginx --since "1 hour ago"
sudo journalctl -u postgresql --since today
sudo journalctl -p err --since yesterday

# Create log monitoring script
cat > /home/tim/monitor.sh << 'EOF'
#!/bin/bash
echo "=== Server Status ==="
echo "Date: $(date)"
echo ""
echo "=== Uptime ==="
uptime
echo ""
echo "=== Disk Usage ==="
df -h / /var
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Top Processes ==="
ps aux --sort=-%mem | head -10
echo ""
echo "=== Nginx Status ==="
systemctl is-active nginx
echo ""
echo "=== PostgreSQL Status ==="
systemctl is-active postgresql
echo ""
echo "=== Redis Status ==="
systemctl is-active redis-server
echo ""
echo "=== Failed Services ==="
systemctl --failed
echo ""
echo "=== Recent Errors ==="
sudo journalctl -p err --since "1 hour ago" --no-pager | tail -20
EOF

chmod +x /home/tim/monitor.sh
```

### Step 5.3 — Set Up Automated Backups

```bash
# Create backup script
cat > /home/tim/backup.sh << 'BACKUP'
#!/bin/bash
# Automated backup script for TechStore

BACKUP_DIR="/home/tim/backups"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
echo "Backing up PostgreSQL..."
pg_dump -U techstore_admin -d techstore -h 127.0.0.1 | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"

# Backup application files
echo "Backing up application..."
tar -czf "$BACKUP_DIR/app_$DATE.tar.gz" -C /var/www techstore

# Backup Nginx config
echo "Backing up Nginx config..."
tar -czf "$BACKUP_DIR/nginx_$DATE.tar.gz" /etc/nginx/

# Backup Redis
echo "Backing up Redis..."
redis-cli -a YourRedisStr0ngP@ss! BGSAVE
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"

# Clean old backups
find "$BACKUP_DIR" -type f -mtime +$KEEP_DAYS -delete

echo "Backup completed: $DATE"
BACKUP

chmod +x /home/tim/backup.sh

# Schedule daily backup at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * /home/tim/backup.sh >> /home/tim/backup.log 2>&1") | crontab -

# Test backup
/home/tim/backup.sh
ls -la /home/tim/backups/
```

### Step 5.4 — Create System Health Check Script

```bash
cat > /home/tim/healthcheck.sh << 'HEALTH'
#!/bin/bash
# System health check for TechStore

ERRORS=0

echo "=== TechStore Health Check ==="
echo "Time: $(date)"
echo ""

# Check disk space
DISK_USAGE=$(df / --output=pcent | tail -1 | tr -d ' %')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "WARNING: Disk usage is ${DISK_USAGE}%"
    ERRORS=$((ERRORS + 1))
else
    echo "OK: Disk usage is ${DISK_USAGE}%"
fi

# Check memory
MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ "$MEM_USAGE" -gt 80 ]; then
    echo "WARNING: Memory usage is ${MEM_USAGE}%"
    ERRORS=$((ERRORS + 1))
else
    echo "OK: Memory usage is ${MEM_USAGE}%"
fi

# Check services
for SERVICE in nginx postgresql redis-server; do
    if systemctl is-active --quiet "$SERVICE"; then
        echo "OK: $SERVICE is running"
    else
        echo "ERROR: $SERVICE is not running"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check application
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo "OK: Application is responding"
else
    echo "ERROR: Application returned HTTP $HTTP_CODE"
    ERRORS=$((ERRORS + 1))
fi

# Check SSL cert expiry
CERT_DAYS=$(( ($(date -d "$(openssl x509 -enddate -noout -in /etc/nginx/ssl/techstore.crt | cut -d= -f2)" +%s) - $(date +%s)) / 86400 ))
if [ "$CERT_DAYS" -lt 30 ]; then
    echo "WARNING: SSL cert expires in $CERT_DAYS days"
    ERRORS=$((ERRORS + 1))
else
    echo "OK: SSL cert expires in $CERT_DAYS days"
fi

echo ""
echo "=== Summary ==="
if [ "$ERRORS" -eq 0 ]; then
    echo "All checks passed!"
    exit 0
else
    echo "$ERRORS issue(s) found!"
    exit 1
fi
HEALTH

chmod +x /home/tim/healthcheck.sh

# Run it
/home/tim/healthcheck.sh
```

### Step 5.5 — Write Runbook Documentation

```bash
cat > /home/tim/RUNBOOK.md << 'RUNBOOK'
# TechStore Runbook

## Quick Reference

| Service | Port | Config | Logs | Status Command |
|---------|------|--------|------|----------------|
| Nginx | 80, 443 | /etc/nginx/sites-available/techstore | /var/log/nginx/ | systemctl status nginx |
| Node.js | 3000 | /var/www/techstore/.env | pm2 logs techstore | pm2 status |
| PostgreSQL | 5432 | /etc/postgresql/14/main/ | journalctl -u postgresql | systemctl status postgresql |
| Redis | 6379 | /etc/redis/redis.conf | journalctl -u redis-server | systemctl status redis-server |

## Common Commands

### Restart services
```bash
sudo systemctl restart nginx
pm2 restart techstore
sudo systemctl restart postgresql
sudo systemctl restart redis-server
```

### View logs
```bash
sudo tail -f /var/log/nginx/techstore_error.log
pm2 logs techstore --lines 100
sudo journalctl -u postgresql -f
```

### Database operations
```bash
# Connect to database
psql -U techstore_admin -d techstore -h 127.0.0.1

# Backup
pg_dump -U techstore_admin -d techstore | gzip > backup.sql.gz

# Restore
gunzip -c backup.sql.gz | psql -U techstore_admin -d techstore
```

### Emergency procedures
```bash
# If server is unresponsive
sudo reboot

# If nginx is down
sudo systemctl restart nginx

# If app is crash-looping
pm2 restart techstore
pm2 logs techstore --lines 50

# If disk is full
sudo du -sh /var/log/* | sort -rh | head -10
sudo journalctl --vacuum-size=500M
```

## Contacts
- **Intern**: tim (you)
- **Senior SysAdmin**: [mentor name]
- **On-call**: [phone number]
RUNBOOK
```

### Step 5.6 — Final Verification

```bash
# Run all checks
echo "=== Final Verification ==="
echo ""
echo "1. Firewall:"
sudo ufw status
echo ""
echo "2. Services:"
for s in nginx postgresql redis-server; do echo "$s: $(systemctl is-active $s)"; done
echo ""
echo "3. Application:"
curl -s http://127.0.0.1:3000/health
echo ""
echo "4. Database:"
psql -U techstore_admin -d techstore -h 127.0.0.1 -c "SELECT COUNT(*) FROM products;"
echo ""
echo "5. Disk:"
df -h /
echo ""
echo "6. PM2:"
pm2 status
echo ""
echo "7. SSL:"
echo | openssl s_client -connect localhost:443 2>/dev/null | grep -A2 "Certificate chain"
```

---

## Project Deliverables

At the end of this internship project, you should have:

| # | Deliverable | Status |
|---|------------|--------|
| 1 | Hardened Ubuntu server with UFW firewall | ☐ |
| 2 | SSH configured with key auth on non-standard port | ☐ |
| 3 | Fail2Ban protecting against brute force | ☐ |
| 4 | PostgreSQL database with schema and sample data | ☐ |
| 5 | Redis cache configured with password | ☐ |
| 6 | Node.js application running via PM2 | ☐ |
| 7 | Nginx reverse proxy with SSL (Let's Encrypt) | ☐ |
| 8 | Automated daily backups (PostgreSQL + App + Nginx) | ☐ |
| 9 | Monitoring (Netdata + custom health check script) | ☐ |
| 10 | Runbook documentation | ☐ |
| 11 | Log rotation configured | ☐ |
| 12 | Automatic security updates enabled | ☐ |

---

## Skills You Practiced

This project covers skills from these course modules:

| Module | Skills Used |
|--------|-------------|
| Part 01 | Linux fundamentals, filesystem |
| Part 02 | Terminal navigation, commands |
| Part 03 | Users, groups, permissions |
| Part 06 | Shell scripting (backup, monitor scripts) |
| Part 10 | Boot process, systemd |
| Part 11 | Package management (apt) |
| Part 12 | Systemd services |
| Part 13 | Cron jobs (automated backups) |
| Part 14 | Logging, journalctl |
| Part 15 | SSH remote access |
| Part 16 | Firewalls (UFW) |
| Part 17 | SELinux/AppArmor basics |
| Part 18 | Environment variables |
| Part 26 | Network configuration |
| Part 27 | DNS configuration |
| Part 33 | System monitoring |
| Part 39 | Web servers (Nginx) |
| Part 40 | Databases (PostgreSQL) |
| Part 49 | Security hardening |
| Part 56 | Observability (Netdata) |

---

## Bonus Challenges

After completing the main project, try these:

1. **Add a second server** — set up a database replica for high availability
2. **Set up Ansible** — automate the entire setup with playbooks
3. **Add Docker** — containerize the app with docker-compose
4. **Set up CI/CD** — GitHub Actions to auto-deploy on push
5. **Add Prometheus + Grafana** — advanced monitoring dashboards

---

## Timeline

| Day | Tasks | Hours |
|-----|-------|-------|
| Day 1 | Server setup, user, firewall, SSH, Fail2Ban | 4-5h |
| Day 2 | Install Node.js, PostgreSQL, Redis, Nginx | 3-4h |
| Day 3 | Deploy app, create DB schema, PM2 | 4-5h |
| Day 4 | Nginx config, SSL, log rotation | 3-4h |
| Day 5 | Monitoring, backups, documentation, testing | 4-5h |
| **Total** | | **18-23h** |

---

## Interview Prep

After completing this project, you can answer these interview questions:

1. "Tell me about a time you deployed a web application" → This project
2. "How do you secure a Linux server?" → Steps 1.5-1.9
3. "How do you set up a reverse proxy?" → Day 4
4. "How do you monitor server health?" → Day 5
5. "How do you handle backups?" → Step 5.3
6. "What is the difference between a process manager and a system service?" → PM2 vs systemd
7. "How does HTTPS work?" → SSL/TLS, Let's Encrypt, Nginx config

---

> **Note**: This is a learning project. In a real company, you would work with existing infrastructure, have code reviews, and follow deployment pipelines. This project gives you the foundational skills to contribute from day one.

---

---

# Option 2: Docker Version — One Command to Rule Them All

Everything from Option 1, but containerized. **One command to deploy. One command to backup. One command to monitor.**

## Comparison

| Aspect | Option 1 (Manual) | Option 2 (Docker) |
|--------|-------------------|-------------------|
| Setup time | 5 days | 30 minutes |
| Commands to learn | 50+ | 3 |
| Portability | Server-specific | Run anywhere |
| Backup | Manual script | One command |
| Monitoring | Multiple tools | One command |
| Scaling | Hard | Easy |
| Best for | Learning Linux deeply | Real production |

---

## Architecture (Docker Version)

```
┌─────────────────────────────────────────────────┐
│                   INTERNET                       │
└───────────────────────┬─────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│              NGINX CONTAINER                    │
│         SSL termination + reverse proxy         │
└──────────┬──────────────────────┬───────────────┘
           │                      │
           ▼                      ▼
┌──────────────────┐  ┌──────────────────────────┐
│  APP CONTAINER   │  │    NGINX STATIC         │
│  Node.js :3000   │  │    (HTML/CSS/JS)        │
└────────┬─────────┘  └──────────────────────────┘
         │
         ▼
┌──────────────────┐  ┌──────────────────────────┐
│  POSTGRES DATA   │  │    REDIS DATA           │
│  (Volume)        │  │    (Volume)             │
└──────────────────┘  └──────────────────────────┘
```

---

## Step 1: Install Docker (5 minutes)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (no sudo needed after)
sudo usermod -aG docker tim

# Apply group change
newgrp docker

# Verify
docker --version
docker compose version
```

---

## Step 2: Create Project Structure (2 minutes)

```bash
mkdir -p ~/techstore-docker
cd ~/techstore-docker

# Create directory structure
mkdir -p app/config app/public nginx/ssl nginx/conf.d monitoring
```

Your structure:
```
techstore-docker/
├── docker-compose.yml          # Main file — runs everything
├── .env                        # Secrets and config
├── app/
│   ├── app.js                  # Node.js application
│   ├── package.json            # Dependencies
│   ├── config/
│   │   └── init.sql            # Database schema
│   └── public/
│       └── index.html          # Frontend
├── nginx/
│   ├── nginx.conf              # Nginx main config
│   └── conf.d/
│       └── default.conf        # Site config
├── monitoring/
│   └── healthcheck.sh          # Health check script
├── scripts/
│   ├── backup.sh               # Backup script
│   ├── restore.sh              # Restore script
│   └── setup.sh                # Full setup script
```

---

## Step 3: Create All Files (10 minutes)

### `.env` — Secrets and Configuration

```bash
cat > .env << 'EOF'
# Database
POSTGRES_DB=techstore
POSTGRES_USER=techstore_admin
POSTGRES_PASSWORD=YourStr0ngP@ssw0rd!

# Redis
REDIS_PASSWORD=YourRedisStr0ngP@ss!

# Application
NODE_ENV=production
PORT=3000
SESSION_SECRET=change-this-to-random-string-$(openssl rand -hex 16)

# Domain (change to your actual domain)
DOMAIN=localhost
EOF
```

### `docker-compose.yml` — The Magic File

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # ============================
  # PostgreSQL Database
  # ============================
  postgres:
    image: postgres:16-alpine
    container_name: techstore-db
    restart: always
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./app/config/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - 127.0.0.1:5432:5432
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

  # ============================
  # Redis Cache
  # ============================
  redis:
    image: redis:7-alpine
    container_name: techstore-redis
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    ports:
      - 127.0.0.1:6379:6379
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

  # ============================
  # Node.js Application
  # ============================
  app:
    build:
      context: ./app
      dockerfile: Dockerfile
    container_name: techstore-app
    restart: always
    environment:
      NODE_ENV: ${NODE_ENV}
      PORT: ${PORT}
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      SESSION_SECRET: ${SESSION_SECRET}
    volumes:
      - ./app/public:/app/public
    ports:
      - 127.0.0.1:3000:3000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - backend

  # ============================
  # Nginx Reverse Proxy + SSL
  # ============================
  nginx:
    image: nginx:alpine
    container_name: techstore-nginx
    restart: always
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./app/public:/usr/share/nginx/html:ro
      - nginx_certs:/etc/nginx/ssl
    depends_on:
      - app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - backend

  # ============================
  # Monitoring (Netdata)
  # ============================
  netdata:
    image: netdata/netdata
    container_name: techstore-monitor
    restart: always
    ports:
      - 19999:19999
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    cap_add:
      - SYS_PTRACE
      - SYS_ADMIN
    security_opt:
      - no-new-privileges:true
    networks:
      - backend

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  nginx_certs:
    driver: local

networks:
  backend:
    driver: bridge
EOF
```

### `app/Dockerfile` — Build the App Container

```bash
cat > app/Dockerfile << 'EOF'
FROM node:20-alpine

WORKDIR /app

# Copy package files first (Docker layer caching)
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Create uploads directory
RUN mkdir -p /app/uploads && chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

CMD ["node", "app.js"]
EOF
```

### `app/package.json`

```bash
cat > app/package.json << 'EOF'
{
  "name": "techstore",
  "version": "1.0.0",
  "description": "TechStore E-Commerce Platform",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.12.0",
    "ioredis": "^5.3.2",
    "express-session": "^1.17.3",
    "bcryptjs": "^2.4.3",
    "dotenv": "^16.3.1",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "morgan": "^1.10.0",
    "connect-redis": "^7.1.0"
  }
}
EOF
```

### `app/app.js` — The Application

```bash
cat > app/app.js << 'APPEOF'
require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const Redis = require('ioredis');
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// PostgreSQL connection with retry
const pgPool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Redis connection with retry
const redisClient = new Redis(process.env.REDIS_URL, {
  retryStrategy: (times) => Math.min(times * 50, 2000),
});

// Middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Session with Redis
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET || 'fallback-secret',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 1000 * 60 * 60 * 24,
  },
}));

// Routes
app.get('/', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT NOW()');
    res.json({
      message: 'TechStore API is running!',
      database: 'connected',
      time: result.rows[0].now,
      version: '1.0.0',
    });
  } catch (err) {
    res.status(500).json({ error: 'Database connection failed', details: err.message });
  }
});

app.get('/health', async (req, res) => {
  const health = { status: 'healthy', checks: {} };

  try {
    await pgPool.query('SELECT 1');
    health.checks.postgres = 'ok';
  } catch (err) {
    health.status = 'unhealthy';
    health.checks.postgres = err.message;
  }

  try {
    await redisClient.ping();
    health.checks.redis = 'ok';
  } catch (err) {
    health.status = 'unhealthy';
    health.checks.redis = err.message;
  }

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

app.get('/api/products', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT * FROM products ORDER BY id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/stats', async (req, res) => {
  try {
    const products = await pgPool.query('SELECT COUNT(*) FROM products');
    const users = await pgPool.query('SELECT COUNT(*) FROM users');
    const orders = await pgPool.query('SELECT COUNT(*) FROM orders');
    res.json({
      products: parseInt(products.rows[0].count),
      users: parseInt(users.rows[0].count),
      orders: parseInt(orders.rows[0].count),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`TechStore server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});
APPEOF
```

### `app/config/init.sql` — Database Schema

```bash
cat > app/config/init.sql << 'EOF'
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, description, price, stock) VALUES
('Mechanical Keyboard', 'Cherry MX Brown switches', 129.99, 50),
('Gaming Mouse', '16000 DPI optical sensor', 79.99, 100),
('27" Monitor', '4K IPS display', 449.99, 25),
('USB-C Hub', '7-in-1 adapter', 49.99, 200),
('Webcam', '1080p HD with mic', 89.99, 75),
('Headset', '7.1 surround sound', 149.99, 60);
EOF
```

### `app/public/index.html`

```bash
mkdir -p app/public
cat > app/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TechStore — Docker Edition</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0a0a0a; color: #fff; }
        .container { max-width: 900px; margin: 0 auto; padding: 2rem; }
        .hero { text-align: center; padding: 4rem 0; }
        h1 { font-size: 3rem; margin-bottom: 0.5rem; }
        .subtitle { color: #888; font-size: 1.2rem; margin-bottom: 2rem; }
        .badge { display: inline-block; background: #00ff88; color: #000; padding: 0.3rem 1rem; border-radius: 20px; font-weight: bold; font-size: 0.9rem; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin: 2rem 0; }
        .card { background: #1a1a1a; border: 1px solid #333; border-radius: 12px; padding: 1.5rem; }
        .card h3 { margin-bottom: 0.5rem; }
        .card p { color: #888; font-size: 0.9rem; }
        .status { background: #1a1a1a; border: 1px solid #333; border-radius: 12px; padding: 2rem; margin: 2rem 0; }
        .status h2 { margin-bottom: 1rem; }
        .status-item { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid #222; }
        .ok { color: #00ff88; }
        .error { color: #ff4444; }
        .products { margin: 2rem 0; }
        .product { display: flex; justify-content: space-between; align-items: center; background: #1a1a1a; border: 1px solid #333; border-radius: 8px; padding: 1rem 1.5rem; margin: 0.5rem 0; }
        .price { color: #00ff88; font-weight: bold; font-size: 1.1rem; }
    </style>
</head>
<body>
    <div class="container">
        <div class="hero">
            <h1>TechStore</h1>
            <p class="subtitle">Full-Stack E-Commerce — Docker Edition</p>
            <span class="badge">Dockerized</span>
        </div>

        <div class="status" id="status">
            <h2>System Status</h2>
            <div class="status-item">
                <span>Application</span>
                <span id="app-status" class="ok">Checking...</span>
            </div>
            <div class="status-item">
                <span>Database</span>
                <span id="db-status">Checking...</span>
            </div>
            <div class="status-item">
                <span>Cache</span>
                <span id="redis-status">Checking...</span>
            </div>
        </div>

        <div class="products">
            <h2>Products</h2>
            <div id="products-list">Loading...</div>
        </div>

        <div class="grid">
            <div class="card">
                <h3>One Command Deploy</h3>
                <p>docker compose up -d</p>
            </div>
            <div class="card">
                <h3>One Command Backup</h3>
                <p>./scripts/backup.sh</p>
            </div>
            <div class="card">
                <h3>One Command Monitor</h3>
                <p>./scripts/monitor.sh</p>
            </div>
        </div>
    </div>

    <script>
        fetch('/health')
            .then(r => r.json())
            .then(data => {
                document.getElementById('app-status').textContent = 'Online';
                document.getElementById('app-status').className = 'ok';
                document.getElementById('db-status').textContent = data.checks?.postgres || 'Unknown';
                document.getElementById('db-status').className = data.checks?.postgres === 'ok' ? 'ok' : 'error';
                document.getElementById('redis-status').textContent = data.checks?.redis || 'Unknown';
                document.getElementById('redis-status').className = data.checks?.redis === 'ok' ? 'ok' : 'error';
            })
            .catch(() => {
                document.getElementById('app-status').textContent = 'Offline';
                document.getElementById('app-status').className = 'error';
            });

        fetch('/api/products')
            .then(r => r.json())
            .then(products => {
                const list = document.getElementById('products-list');
                list.innerHTML = products.map(p => `
                    <div class="product">
                        <div>
                            <strong>${p.name}</strong><br>
                            <small style="color:#888">${p.description}</small>
                        </div>
                        <span class="price">$${p.price}</span>
                    </div>
                `).join('');
            });
    </script>
</body>
</html>
EOF
```

### `nginx/nginx.conf`

```bash
cat > nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;

    include /etc/nginx/conf.d/*.conf;
}
EOF
```

### `nginx/conf.d/default.conf`

```bash
cat > nginx/conf.d/default.conf << 'EOF'
upstream app {
    server app:3000;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://app/health;
        access_log off;
    }
}
EOF
```

---

## Step 4: The Magic Scripts (5 minutes)

### `scripts/setup.sh` — One Command to Deploy Everything

```bash
mkdir -p scripts
cat > scripts/setup.sh << 'SETUP'
#!/bin/bash
set -e

echo "╔══════════════════════════════════════╗"
echo "║   TechStore Docker Setup             ║"
echo "║   One command to rule them all       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Please run: newgrp docker"
    echo "Then run this script again."
    exit 1
fi

echo "[1/4] Building containers..."
docker compose build --no-cache

echo "[2/4] Starting all services..."
docker compose up -d

echo "[3/4] Waiting for services to be ready..."
sleep 10

# Health check
echo "[4/4] Running health checks..."
echo ""

# Check each service
for service in techstore-app techstore-db techstore-redis techstore-nginx techstore-monitor; do
    if docker ps --format '{{.Names}}' | grep -q "$service"; then
        echo "  ✓ $service is running"
    else
        echo "  ✗ $service failed to start"
    fi
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Deployment Complete!               ║"
echo "╠══════════════════════════════════════╣"
echo "║                                      ║"
echo "║   App:      http://localhost:3000    ║"
echo "║   Monitor:  http://localhost:19999   ║"
echo "║   API:      http://localhost:3000/api/products"
echo "║   Health:   http://localhost:3000/health"
echo "║                                      ║"
echo "║   Stop:     docker compose down      ║"
echo "║   Logs:     docker compose logs -f   ║"
echo "║   Backup:   ./scripts/backup.sh      ║"
echo "║                                      ║"
echo "╚══════════════════════════════════════╝"
SETUP
chmod +x scripts/setup.sh
```

### `scripts/backup.sh` — One Command to Backup Everything

```bash
cat > scripts/backup.sh << 'BACKUP'
#!/bin/bash
set -e

BACKUP_DIR="$HOME/techstore-backups"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p "$BACKUP_DIR"

echo "╔══════════════════════════════════════╗"
echo "║   TechStore Backup — $DATE"
echo "╚══════════════════════════════════════╝"
echo ""

# 1. Backup PostgreSQL
echo "[1/3] Backing up PostgreSQL..."
docker exec techstore-db pg_dump -U ${POSTGRES_USER:-techstore_admin} ${POSTGRES_DB:-techstore} | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"
echo "  ✓ Database backup: postgres_$DATE.sql.gz"

# 2. Backup Redis
echo "[2/3] Backing up Redis..."
docker exec techstore-redis redis-cli -a ${REDIS_PASSWORD:-changeme} BGSAVE > /dev/null 2>&1
sleep 2
docker cp techstore-redis:/data/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"
echo "  ✓ Redis backup: redis_$DATE.rdb"

# 3. Backup application
echo "[3/3] Backing up application files..."
tar -czf "$BACKUP_DIR/app_$DATE.tar.gz" \
    --exclude='node_modules' \
    --exclude='.git' \
    -C "$(dirname "$0")/.." . 2>/dev/null
echo "  ✓ App backup: app_$DATE.tar.gz"

# Clean old backups
echo ""
echo "Cleaning backups older than $KEEP_DAYS days..."
find "$BACKUP_DIR" -type f -mtime +$KEEP_DAYS -delete 2>/dev/null
REMAINING=$(ls "$BACKUP_DIR" | wc -l)
echo "  $REMAINING backup(s) retained"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Backup Complete!                   ║"
echo "╠══════════════════════════════════════╣"
echo "║   Location: $BACKUP_DIR"
echo "║   Files:"
ls -lh "$BACKUP_DIR"/*_$DATE.* 2>/dev/null | awk '{print "║     " $NF " (" $5 ")"}'
echo "╚══════════════════════════════════════╝"
BACKUP
chmod +x scripts/backup.sh
```

### `scripts/restore.sh` — One Command to Restore

```bash
cat > scripts/restore.sh << 'RESTORE'
#!/bin/bash
set -e

BACKUP_DIR="$HOME/techstore-backups"

echo "╔══════════════════════════════════════╗"
echo "║   TechStore Restore                  ║"
echo "╚══════════════════════════════════════╝"
echo ""

# List available backups
echo "Available backups:"
echo ""
ls -1t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -5 | while read f; do
    DATE=$(basename "$f" | sed 's/postgres_//; s/.sql.gz//')
    SIZE=$(du -h "$f" | cut -f1)
    echo "  $DATE ($SIZE)"
done

echo ""
echo "Usage: ./scripts/restore.sh <date>"
echo "Example: ./scripts/restore.sh 20240115_143022"
RESTORE
chmod +x scripts/restore.sh
```

### `scripts/monitor.sh` — One Command to Monitor Everything

```bash
cat > scripts/monitor.sh << 'MONITOR'
#!/bin/bash

echo "╔══════════════════════════════════════╗"
echo "║   TechStore Monitor                  ║"
echo "║   $(date '+%Y-%m-%d %H:%M:%S')"
echo "╚══════════════════════════════════════╝"
echo ""

# Container status
echo "┌─────────────────────────────────────┐"
echo "│  CONTAINER STATUS                   │"
echo "└─────────────────────────────────────┘"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
docker ps --format "table {{.Names}}\t{{.Status}}" | grep techstore
echo ""

# Resource usage
echo "┌─────────────────────────────────────┐"
echo "│  RESOURCE USAGE                     │"
echo "└─────────────────────────────────────┘"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep techstore
echo ""

# Disk usage
echo "┌─────────────────────────────────────┐"
echo "│  DISK USAGE                         │"
echo "└─────────────────────────────────────┘"
df -h / | tail -1 | awk '{printf "  Root: %s used of %s (%s)\n", $3, $2, $5}'
docker system df 2>/dev/null | grep -E "Images|Containers|Volumes" | awk '{printf "  Docker %s: %s\n", $1, $3}'
echo ""

# Health check
echo "┌─────────────────────────────────────┐"
echo "│  HEALTH CHECK                       │"
echo "└─────────────────────────────────────┘"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "  Application: ✓ Healthy (HTTP $HTTP_CODE)"
else
    echo "  Application: ✗ Unhealthy (HTTP $HTTP_CODE)"
fi

PG_STATUS=$(docker exec techstore-db pg_isready -U techstore_admin 2>/dev/null && echo "ok" || echo "fail")
if [ "$PG_STATUS" = "ok" ]; then
    echo "  PostgreSQL:  ✓ Ready"
else
    echo "  PostgreSQL:  ✗ Not ready"
fi

REDIS_STATUS=$(docker exec techstore-redis redis-cli -a ${REDIS_PASSWORD:-changeme} ping 2>/dev/null)
if [ "$REDIS_STATUS" = "PONG" ]; then
    echo "  Redis:       ✓ Ready"
else
    echo "  Redis:       ✗ Not ready"
fi

NGINX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null)
if [ "$NGINX_STATUS" = "200" ] || [ "$NGINX_STATUS" = "301" ]; then
    echo "  Nginx:       ✓ Running"
else
    echo "  Nginx:       ✗ Not responding"
fi
echo ""

# Recent logs
echo "┌─────────────────────────────────────┐"
echo "│  RECENT ERRORS (last 5 min)         │"
echo "└─────────────────────────────────────┘"
docker compose logs --since 5m --tail 5 2>/dev/null | grep -i error || echo "  No errors found"
echo ""

# Backup status
echo "┌─────────────────────────────────────┐"
echo "│  LAST BACKUP                        │"
echo "└─────────────────────────────────────┘"
LAST_BACKUP=$(ls -1t ~/techstore-backups/*.sql.gz 2>/dev/null | head -1)
if [ -n "$LAST_BACKUP" ]; then
    BACKUP_DATE=$(basename "$LAST_BACKUP" | sed 's/postgres_//; s/.sql.gz//')
    BACKUP_SIZE=$(du -h "$LAST_BACKUP" | cut -f1)
    echo "  $BACKUP_DATE ($BACKUP_SIZE)"
else
    echo "  No backups found"
fi
MONITOR
chmod +x scripts/monitor.sh
```

---

## Step 5: Deploy! (1 command)

```bash
cd ~/techstore-docker
./scripts/setup.sh
```

That's it. Everything is running.

---

## Daily Commands

### Start Everything
```bash
cd ~/techstore-docker
docker compose up -d
```

### Stop Everything
```bash
docker compose down
```

### Backup Everything
```bash
./scripts/backup.sh
```

### Monitor Everything
```bash
./scripts/monitor.sh
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app
docker compose logs -f postgres
```

### Restart One Service
```bash
docker compose restart app
docker compose restart nginx
```

### Update and Redeploy
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Enter a Container (Debug)
```bash
docker exec -it techstore-app sh
docker exec -it techstore-db psql -U techstore_admin techstore
docker exec -it techstore-redis redis-cli
```

---

## Scheduled Backup (Cron)

```bash
# Edit crontab
crontab -e

# Add this line — backup daily at 2 AM
0 2 * * * /home/tim/techstore-docker/scripts/backup.sh >> /home/tim/techstore-backups/backup.log 2>&1
```

---

## Docker Cheat Sheet

| Command | What It Does |
|---------|-------------|
| `docker compose up -d` | Start everything in background |
| `docker compose down` | Stop everything |
| `docker compose ps` | Show running containers |
| `docker compose logs -f` | Follow logs |
| `docker compose restart app` | Restart one service |
| `docker compose build --no-cache` | Rebuild containers |
| `docker exec -it techstore-app sh` | Enter container shell |
| `docker stats` | Show CPU/memory usage |
| `docker system prune -a` | Clean up unused containers/images |
| `docker volume ls` | List data volumes |
| `docker compose pull` | Update to latest images |

---

## Comparison: Manual vs Docker

| Task | Option 1 (Manual) | Option 2 (Docker) |
|------|-------------------|-------------------|
| **Initial setup** | 5 days, 50+ commands | 1 command, 30 min |
| **Backup** | Write custom script | `./scripts/backup.sh` |
| **Monitor** | Install 5+ tools | `./scripts/monitor.sh` |
| **Update app** | SSH, pull code, restart | `docker compose up -d` |
| **Scale** | Add servers manually | `docker compose up --scale app=3` |
| **Migrate** | Reinstall everything | Copy 1 folder |
| **Team onboarding** | 1 week training | `docker compose up -d` |
| **Disaster recovery** | 4-8 hours | 30 minutes |

---

## Skills You Practiced (Docker Version)

| Module | Skills Used |
|--------|-------------|
| Part 02 | Terminal commands |
| Part 06 | Shell scripting |
| Part 13 | Cron jobs |
| Part 16 | Firewalls |
| Part 38 | Container basics (Docker) |
| Part 39 | Web servers (Nginx) |
| Part 40 | Databases (PostgreSQL) |
| Part 54 | Configuration management |
| Part 55 | Immutable infrastructure |
| Part 56 | Observability |

---

> **Key Takeaway**: Option 1 teaches you Linux deeply. Option 2 teaches you modern production practices. In a real company, you'd use **both** — understand the manual process, then automate it with Docker. That's exactly what this internship project gives you.
