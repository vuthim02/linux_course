## 🔍 Section 4: Apache Modules

Apache is **modular** — almost every feature is a module you can enable/disable.

### `mod_rewrite` — URL Rewriting

The most commonly used module. It transforms URLs before Apache serves them.

```bash
sudo a2enmod rewrite
```

```apache
RewriteEngine On

# Redirect all HTTP to HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R=301,L]

# Pretty URLs: /product/123 → /product.php?id=123
RewriteRule ^product/([0-9]+)$ product.php?id=$1 [QSA,L]

# Block hotlinking of images
RewriteCond %{HTTP_REFERER} !^$
RewriteCond %{HTTP_REFERER} !^https://example\.com/.*$ [NC]
RewriteRule \.(jpg|png|gif)$ - [F,L]
```

### `mod_ssl` — TLS/SSL

```bash
sudo a2enmod ssl
```

```apache
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot /var/www/example.com

    SSLEngine on
    SSLCertificateFile      /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile   /etc/letsencrypt/live/example.com/privkey.pem

    # Modern TLS config
    SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    SSLHonorCipherOrder     off
    SSLSessionTickets       off
</VirtualHost>
```

### `mod_proxy` — Reverse Proxy

```bash
sudo a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests
```

```apache
<VirtualHost *:80>
    ServerName app.example.com

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/

    # Load balancing across multiple backends
    <Proxy balancer://mycluster>
        BalancerMember http://127.0.0.1:8080
        BalancerMember http://127.0.0.1:8081
        BalancerMember http://127.0.0.1:8082
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass / balancer://mycluster/
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>
```

### `mod_headers` — HTTP Header Manipulation

```bash
sudo a2enmod headers
```

```apache
# Add security headers globally
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "DENY"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"

# Enable HSTS (only on HTTPS vhost)
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
```

### `mod_expires` — Cache Control

```bash
sudo a2enmod expires
```

```apache
ExpiresActive On

# Images: cache for 1 month
ExpiresByType image/jpeg "access plus 1 month"
ExpiresByType image/png "access plus 1 month"
ExpiresByType image/webp "access plus 1 month"
ExpiresByType image/svg+xml "access plus 1 month"

# CSS and JS: cache for 1 year with versioning
ExpiresByType text/css "access plus 1 year"
ExpiresByType application/javascript "access plus 1 year"

# HTML: cache for 10 minutes
ExpiresByType text/html "access plus 10 minutes"
```

### `mod_security` (ModSecurity) — Web Application Firewall

```bash
sudo apt install libapache2-mod-security2 -y
sudo a2enmod security2
```

ModSecurity provides a WAF (Web Application Firewall) with OWASP Core Rule Set (CRS). It inspects every request for SQL injection, XSS, path traversal, etc.

```apache
# /etc/modsecurity/modsecurity.conf
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml
```

### `mod_evasive` — Anti-DoS

```bash
sudo apt install libapache2-mod-evasive -y
sudo a2enmod evasive
```

```apache
# /etc/apache2/mods-available/evasive.conf
<IfModule mod_evasive20.c>
    DOSHashTableSize    3097
    DOSPageCount        5           # Max requests per page per interval
    DOSSiteCount        100         # Max requests per site per interval
    DOSPageInterval     2           # Interval in seconds
    DOSSiteInterval     2
    DOSBlockingPeriod   10          # Seconds to block
</IfModule>
```





[← Previous](04-section-3-apache-virtual-hosts.md) | [↑ Index](index.md) | [Next →](06-section-5-apache-performance-mpm.md)
