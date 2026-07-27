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



---

[← Previous](03-section-1-dhcp-server.md) | [↑ Index](index.md) | [Next →](05-level-2-intermediary-ssh-and.md)
