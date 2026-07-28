## 💻 PRACTICE SECTION — 15 Hands-On Exercises


### ✅ Practice 1: Install and Configure Apache

```bash
# Install Apache
sudo apt update
sudo apt install apache2 -y

# Verify it's running
sudo systemctl status apache2

# Check what ports it's listening on
sudo ss -tlnp | grep 80

# Create a custom index page
echo "<h1>Apache is working!</h1>" | sudo tee /var/www/html/index.html

# Test with curl
curl -I http://localhost
curl http://localhost
```


### ✅ Practice 2: Create Apache Virtual Hosts

Create two virtual hosts on the same server:

```bash
# Create directories
sudo mkdir -p /var/www/site1.com
sudo mkdir -p /var/www/site2.org

# Create index pages
echo "<h1>Site 1 - example.com</h1>" | sudo tee /var/www/site1.com/index.html
echo "<h1>Site 2 - another.org</h1>" | sudo tee /var/www/site2.org/index.html
```

Create `/etc/apache2/sites-available/site1.com.conf`:

```apache
<VirtualHost *:80>
    ServerName site1.com
    ServerAlias www.site1.com
    DocumentRoot /var/www/site1.com

    <Directory /var/www/site1.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/site1-error.log
    CustomLog ${APACHE_LOG_DIR}/site1-access.log combined
</VirtualHost>
```

Create `/etc/apache2/sites-available/site2.org.conf` similarly.

```bash
# Enable both sites
sudo a2ensite site1.com.conf
sudo a2ensite site2.org.conf

# Disable default site
sudo a2dissite 000-default.conf

# Reload Apache
sudo systemctl reload apache2

# Test (add entries to /etc/hosts for testing)
echo "127.0.0.1 site1.com www.site1.com site2.org" | sudo tee -a /etc/hosts

curl -H "Host: site1.com" http://localhost
curl -H "Host: site2.org" http://localhost
```


### ✅ Practice 3: Enable SSL with Certbot

```bash
# Install Certbot with Apache plugin
sudo apt install certbot python3-certbot-apache -y

# Obtain certificate (requires a real domain pointing to your server)
sudo certbot --apache -d example.com -d www.example.com

# Test auto-renewal
sudo certbot renew --dry-run

# Verify SSL configuration
curl -I https://example.com
```

If you don't have a real domain, create a self-signed certificate for testing:

```bash
sudo mkdir -p /etc/ssl/local
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/local/selfsigned.key \
    -out /etc/ssl/local/selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Enable SSL module
sudo a2enmod ssl
sudo systemctl reload apache2
```

Create a self-signed SSL vhost:

```apache
<VirtualHost *:443>
    ServerName localhost
    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile /etc/ssl/local/selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/local/selfsigned.key
</VirtualHost>
```


### ✅ Practice 4: Configure mod_rewrite Rules

```bash
sudo a2enmod rewrite
sudo systemctl reload apache2
```

Add to `/var/www/site1.com/.htaccess`:

```apache
RewriteEngine On

# Force HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R=301,L]

# Pretty URLs: /user/john → /profile.php?username=john
RewriteRule ^user/([a-zA-Z0-9_-]+)$ profile.php?username=$1 [L]

# Block access to hidden files (starting with .)
RewriteRule (^|/)\. - [F]

# Redirect old URLs to new
RewriteRule ^old-article\.html$ /new-article [R=301,L]
```

Test with curl:

```bash
curl -I http://site1.com/old-article.html  # Should see 301 redirect
curl -I http://site1.com/.git/config        # Should see 403 Forbidden
```


### ✅ Practice 5: Install and Configure Nginx

```bash
# Stop Apache first (they both can't use port 80 simultaneously)
sudo systemctl stop apache2
sudo systemctl disable apache2

# Install Nginx
sudo apt install nginx -y
sudo systemctl enable --now nginx

# Verify
sudo ss -tlnp | grep 80
curl http://localhost
```


### ✅ Practice 6: Create Nginx Server Blocks

```bash
# Create directories
sudo mkdir -p /var/www/app1.example
sudo mkdir -p /var/www/app2.example

# Create index pages
echo "<h1>App 1</h1>" | sudo tee /var/www/app1.example/index.html
echo "<h1>App 2</h1>" | sudo tee /var/www/app2.example/index.html
```

Create `/etc/nginx/sites-available/app1.example`:

```nginx
server {
    listen 80;
    server_name app1.example;

    root /var/www/app1.example;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/app1-access.log;
    error_log /var/log/nginx/app1-error.log;
}
```

Create `/etc/nginx/sites-available/app2.example` similarly.

```bash
# Enable sites
sudo ln -s /etc/nginx/sites-available/app1.example /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/app2.example /etc/nginx/sites-enabled/

# Remove default
sudo rm /etc/nginx/sites-enabled/default

# Test config and reload
sudo nginx -t
sudo systemctl reload nginx

# Test
echo "127.0.0.1 app1.example app2.example" | sudo tee -a /etc/hosts
curl -H "Host: app1.example" http://localhost
curl -H "Host: app2.example" http://localhost
```


### ✅ Practice 7: Configure Nginx Reverse Proxy for a Backend App

Start a simple test backend (using Python):

```bash
# Simple Python HTTP server as a "backend" on port 3000
mkdir -p ~/backend && cd ~/backend
cat > app.py << 'EOF'
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(f'Backend response for {self.path}\n'.encode())

HTTPServer(('127.0.0.1', 3000), Handler).serve_forever()
EOF

python3 app.py &
```

Create `/etc/nginx/sites-available/proxy-test`:

```nginx
server {
    listen 80;
    server_name proxy.example;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /status {
        return 200 "Nginx reverse proxy is running\n";
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/proxy-test /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "127.0.0.1 proxy.example" | sudo tee -a /etc/hosts
curl -H "Host: proxy.example" http://localhost/hello
```

Expected: `Backend response for /hello`


### ✅ Practice 8: Load Balancing with upstream

Stop the first backend, start three:

```bash
pkill -f "python3 app.py" || true

# Start 3 backend instances on different ports
for port in 3001 3002 3003; do
    mkdir -p ~/backend-$port
    cat > ~/backend-$port/app.py << EOF
from http.server import HTTPServer, BaseHTTPRequestHandler
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Backend on port $port\n')
HTTPServer(('127.0.0.1', $port), Handler).serve_forever()
EOF
    python3 ~/backend-$port/app.py &
done
```

Create `/etc/nginx/sites-available/loadbalance`:

```nginx
upstream backend_pool {
    least_conn;
    server 127.0.0.1:3001 max_fails=3 fail_timeout=10s;
    server 127.0.0.1:3002 max_fails=3 fail_timeout=10s;
    server 127.0.0.1:3003 max_fails=3 fail_timeout=10s;
}

server {
    listen 80;
    server_name lb.example;

    location / {
        proxy_pass http://backend_pool;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/loadbalance /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
echo "127.0.0.1 lb.example" | sudo tee -a /etc/hosts

# Send multiple requests to see load balancing
for i in $(seq 1 6); do curl -s http://lb.example; done
```

You should see requests distributed across the three backends.


### ✅ Practice 9: Configure Gzip/Brotli Compression

```bash
# Enable gzip in nginx.conf
sudo nano /etc/nginx/nginx.conf
```

Edit the `http` block:

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_min_length 256;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml image/svg+xml;
```

```bash
sudo nginx -t && sudo systemctl reload nginx

# Test gzip
curl -H "Accept-Encoding: gzip" -I http://localhost

# Check Content-Encoding header in response
```

For Apache:

```bash
sudo a2enmod deflate
sudo systemctl reload apache2
```

```apache
# /etc/apache2/mods-available/deflate.conf
AddOutputFilterByType DEFLATE text/html text/plain text/css application/javascript application/json
```


### ✅ Practice 10: Apache MPM Tuning

```bash
# Check which MPM is active
sudo apache2ctl -M | grep mpm

# Switch to event MPM (preferred for production)
sudo a2dismod mpm_prefork
sudo a2enmod mpm_event
sudo systemctl restart apache2

# Verify
sudo apache2ctl -M | grep mpm

# Tune event MPM
sudo nano /etc/apache2/mods-available/mpm_event.conf
```

```apache
<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads         75
    MaxSpareThreads        250
    ThreadLimit             64
    ThreadsPerChild         25
    MaxRequestWorkers      400
    MaxConnectionsPerChild  3000
</IfModule>
```

```bash
sudo systemctl restart apache2

# Monitor performance
curl http://localhost/server-status

# Stress test (install apache2-utils first)
sudo apt install apache2-utils -y
ab -n 10000 -c 100 http://localhost/
```


### ✅ Practice 11: Log Analysis

```bash
# Generate some traffic
for i in $(seq 1 100); do curl -s http://localhost > /dev/null; done

# Analyze Apache/Nginx logs
# Top 10 IPs
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Top requested URLs
awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Status code counts
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Find errors
grep " 404 " /var/log/nginx/access.log

# Watch logs in real-time
sudo tail -f /var/log/nginx/access.log

# Set up log rotation if not already configured
cat /etc/logrotate.d/nginx
```

Configure custom log format:

```nginx
# In nginx.conf http block
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" $request_time';

access_log /var/log/nginx/access.log main;
```


### ✅ Practice 12: Set Up PHP-FPM with Nginx

```bash
sudo apt install php-fpm php-mysql php-curl php-gd php-mbstring php-xml -y

# Check PHP-FPM socket
ls /run/php/php*.sock
```

Create `/etc/nginx/sites-available/php-app`:

```nginx
server {
    listen 80;
    server_name php.example;
    root /var/www/php-app;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# Create PHP test file
sudo mkdir -p /var/www/php-app
echo "<?php phpinfo(); ?>" | sudo tee /var/www/php-app/index.php

sudo ln -s /etc/nginx/sites-available/php-app /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "127.0.0.1 php.example" | sudo tee -a /etc/hosts
curl http://php.example
```


### ✅ Practice 13: Nginx Caching (FastCGI Cache)

```bash
sudo mkdir -p /var/cache/nginx
```

Add to `nginx.conf` `http` block:

```nginx
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=PHP_CACHE:10m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
```

Add to the PHP server block from Practice 12:

```nginx
location ~ \.php$ {
    include fastcgi_params;
    fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

    # Caching
    fastcgi_cache PHP_CACHE;
    fastcgi_cache_valid 200 1m;       # Cache 200 responses for 1 minute
    fastcgi_cache_valid 404 1m;
    fastcgi_cache_use_stale error timeout updating;
    fastcgi_cache_bypass $no_cache;
    fastcgi_no_cache $no_cache;

    # Add header to show cache status
    add_header X-Cache $upstream_cache_status;
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx

# First request (MISS)
curl -I http://php.example/ | grep X-Cache

# Second request (HIT if not bypassed)
curl -I http://php.example/ | grep X-Cache
```


### ✅ Practice 14: Security Hardening

```bash
# Apache security headers
sudo a2enmod headers
```

Add to Apache vhost:

```apache
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "DENY"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
```

For Nginx, add to server block:

```nginx
add_header X-Content-Type-Options nosniff always;
add_header X-Frame-Options DENY always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

```bash
# Hide server version
echo "ServerTokens Prod" | sudo tee -a /etc/apache2/conf-available/security.conf
echo "ServerSignature Off" | sudo tee -a /etc/apache2/conf-available/security.conf
sudo a2enconf security

# Nginx: hide version
sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf

# Restart both
sudo systemctl restart apache2
sudo systemctl restart nginx

# Test
curl -I http://localhost | grep Server
```


### ✅ Practice 15: Real-World Integration — Nginx → Apache Backend

Deploy a full stack with Nginx as reverse proxy, Apache as backend:

```bash
# Stop nginx and start apache on port 8080
sudo systemctl stop nginx
sudo systemctl start apache2
```

Edit `/etc/apache2/ports.conf`:

```apache
Listen 8080
```

Edit Apache default site to listen on 8080:

```apache
<VirtualHost *:8080>
    DocumentRoot /var/www/html
    ...
</VirtualHost>
```

```bash
sudo systemctl restart apache2

# Verify Apache is on 8080
sudo ss -tlnp | grep 8080

# Start Nginx on port 80
sudo systemctl start nginx
```

Create `/etc/nginx/sites-available/full-stack`:

```nginx
upstream apache_backend {
    server 127.0.0.1:8080 max_fails=3 fail_timeout=10s;
}

server {
    listen 80;
    server_name fullstack.example;

    # Static files served directly by Nginx (fast)
    root /var/www/html;
    index index.html index.php;

    location / {
        try_files $uri $uri/ @backend;
    }

    # Static assets with caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Everything else goes to Apache
    location @backend {
        proxy_pass http://apache_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;

        # Timeouts
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
    }

    # Security headers
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header X-XSS-Protection "1; mode=block" always;

    access_log /var/log/nginx/fullstack-access.log;
    error_log /var/log/nginx/fullstack-error.log;
}
```

```bash
sudo ln -s /etc/nginx/sites-available/full-stack /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo "127.0.0.1 fullstack.example" | sudo tee -a /etc/hosts

# Test
curl -I http://fullstack.example
```

What's happening:

```
Client ── HTTP:80 ──► Nginx ── proxy_pass ──► Apache:8080
                         │                          │
                         │ Static files:             │ PHP, dynamic
                         │ served directly           │ content,
                         │ (fast, no Apache          │ .htaccess
                         │ overhead)                 │ processing
```

This architecture gives you the best of both: Nginx's fast static serving and connection handling, with Apache's .htaccess and mod_php compatibility for dynamic content.





[← Previous](14-section-13-static-file-serving.md) | [↑ Index](index.md) | [Next →](16-deep-understanding.md)
