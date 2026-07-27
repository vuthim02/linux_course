## 🔍 Section 11: TLS/SSL — Let's Encrypt and Certbot

### Installation

```bash
sudo apt install certbot python3-certbot-nginx   # For Nginx
sudo apt install certbot python3-certbot-apache  # For Apache
```

### Obtaining a Certificate

```bash
# For Nginx (automatically modifies server blocks)
sudo certbot --nginx -d example.com -d www.example.com

# For Apache
sudo certbot --apache -d example.com -d www.example.com

# Certificate-only mode (no config modification)
sudo certbot certonly --nginx -d example.com

# Standalone mode (stops your web server temporarily)
sudo certbot certonly --standalone -d example.com
```

### Certificate Locations

```
/etc/letsencrypt/live/example.com/
├── cert.pem          # Domain certificate
├── chain.pem         # Intermediate certificate
├── fullchain.pem     # cert.pem + chain.pem (most common to use)
└── privkey.pem       # Private key (keep secret!)
```

### Nginx SSL Configuration

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Modern TLS configuration (Mozilla Intermediate)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    resolver 1.1.1.1 8.8.8.8 valid=300s;
    resolver_timeout 5s;

    # HSTS (HTTP Strict Transport Security)
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Other security headers
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-XSS-Protection "1; mode=block" always;

    root /var/www/example.com;
    index index.html;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}
```

### Apache SSL Configuration

```apache
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot /var/www/example.com

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem

    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off

    # OCSP Stapling
    SSLUseStapling on
    SSLStaplingResponderTimeout 5
    SSLStaplingReturnResponderErrors off

    # HSTS
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
</VirtualHost>
```

### Auto-Renewal

Certbot installs a systemd timer by default:

```bash
sudo systemctl status certbot.timer
sudo certbot renew --dry-run           # Test renewal
```

To manually renew:

```bash
sudo certbot renew
sudo systemctl reload nginx            # Or: sudo systemctl reload apache2
```

### OCSP Stapling

OCSP (Online Certificate Status Protocol) lets the browser check if a certificate is revoked. With **OCSP stapling**, the server fetches the OCSP response and "staples" it to the TLS handshake — the browser doesn't need to contact the CA separately.

- Without stapling: `Browser → CA (OCSP request)` + extra latency
- With stapling: `Server → CA (OCSP request, cached)` → `Browser receives stapled response in handshake` — zero extra latency

### HSTS (HTTP Strict Transport Security)

Tells browsers to **always** use HTTPS for your domain, even if the user types `http://`:

```nginx
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

- `max-age` — seconds to remember (2 years = 63072000)
- `includeSubDomains` — applies to all subdomains
- `preload` — allows submission to browser preload lists (hardcoded HSTS)

> **Warning:** Once you set HSTS with a long `max-age`, browsers will refuse HTTP connections to your domain for that duration. Test with short values first (e.g., 300 seconds).

---



---

[← Previous](11-section-10-nginx-as-load.md) | [↑ Index](index.md) | [Next →](13-section-12-comparison-apache-vs.md)
