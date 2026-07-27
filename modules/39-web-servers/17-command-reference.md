## 📋 Command Reference

### Apache Commands

| Command | Purpose |
|---------|---------|
| `sudo systemctl status apache2` | Check if Apache is running |
| `sudo systemctl start/stop/restart apache2` | Control Apache service |
| `sudo systemctl reload apache2` | Reload config without dropping connections |
| `apache2 -v` | Show version |
| `apache2ctl -M` | List loaded modules |
| `apache2ctl -S` | Show virtual host configuration |
| `apache2ctl configtest` | Test config syntax (`-t`) |
| `sudo a2ensite site.conf` | Enable a site |
| `sudo a2dissite site.conf` | Disable a site |
| `sudo a2enmod module` | Enable a module |
| `sudo a2dismod module` | Disable a module |
| `sudo a2enconf conf` | Enable a config snippet |
| `sudo a2disconf conf` | Disable a config snippet |
| `sudo tail -f /var/log/apache2/access.log` | Watch access log in real-time |
| `sudo tail -f /var/log/apache2/error.log` | Watch error log in real-time |
| `ab -n 1000 -c 50 http://localhost/` | Benchmark (apache2-utils) |
| `htpasswd -c /etc/apache2/.htpasswd user` | Create htpasswd file |

### Apache Config Directives

| Directive | Purpose |
|-----------|---------|
| `<VirtualHost *:80>` | Define a virtual host |
| `ServerName example.com` | Primary domain name |
| `ServerAlias www.example.com` | Additional domain names |
| `DocumentRoot /var/www/html` | Root directory for files |
| `<Directory /path>...</Directory>` | Directory-level configuration |
| `AllowOverride All/None` | Enable/disable .htaccess |
| `Options Indexes FollowSymLinks` | Directory options |
| `Require all granted/denied` | Access control |
| `ErrorLog /path/to/log` | Error log location |
| `CustomLog /path/to/log format` | Access log location and format |
| `LogFormat "format" name` | Define log format |
| `SSLEngine on` | Enable TLS |
| `SSLCertificateFile /path` | TLS certificate |
| `SSLCertificateKeyFile /path` | TLS private key |
| `ProxyPass / http://backend/` | Reverse proxy |
| `ProxyPassReverse / http://backend/` | Rewrite redirect headers |
| `RewriteRule pattern target [flags]` | URL rewriting |
| `RewriteCond test pattern` | Rewrite condition |
| `Header set name value` | Set HTTP response header |
| `ExpiresActive On` | Enable expiration caching |
| `ExpiresByType type time` | Set cache duration by MIME type |
| `AddOutputFilterByType DEFLATE type` | Enable compression |
| `KeepAlive On/Off` | Enable persistent connections |
| `MaxRequestWorkers number` | Max concurrent requests |

### Nginx Commands

| Command | Purpose |
|---------|---------|
| `sudo systemctl status nginx` | Check if Nginx is running |
| `sudo systemctl start/stop/restart nginx` | Control Nginx service |
| `sudo systemctl reload nginx` | Reload config without dropping connections |
| `nginx -v` | Show version |
| `nginx -V` | Show version + compile flags |
| `nginx -t` | Test config syntax |
| `nginx -T` | Test and print full config |
| `sudo tail -f /var/log/nginx/access.log` | Watch access log |
| `sudo tail -f /var/log/nginx/error.log` | Watch error log |
| `sudo ln -s /etc/nginx/sites-available/X /etc/nginx/sites-enabled/` | Enable a site |
| `sudo rm /etc/nginx/sites-enabled/X` | Disable a site |

### Nginx Config Directives

| Directive | Purpose |
|-----------|---------|
| `server { ... }` | Define a server block (virtual host) |
| `listen 80;` | Port to listen on |
| `server_name example.com;` | Domain name matching |
| `root /var/www/html;` | Document root |
| `index index.html index.php;` | Default index files |
| `location / { ... }` | URL path matching block |
| `try_files $uri $uri/ =404;` | Try paths in order |
| `proxy_pass http://backend;` | Reverse proxy target |
| `proxy_set_header Header value;` | Set proxy request headers |
| `upstream name { ... }` | Define backend server group |
| `server address weight=N;` | Backend server in upstream |
| `fastcgi_pass unix:/path.sock;` | Pass to PHP-FPM |
| `fastcgi_param NAME value;` | FastCGI parameter |
| `sendfile on/off;` | Enable zero-copy file serving |
| `gzip on/off;` | Enable compression |
| `gzip_types text/plain ...;` | Compress these MIME types |
| `expires 30d;` | Set Cache-Control max age |
| `add_header Name value;` | Add HTTP response header |
| `ssl_certificate /path;` | TLS certificate |
| `ssl_certificate_key /path;` | TLS private key |
| `ssl_protocols TLSv1.2 TLSv1.3;` | Allowed TLS versions |
| `return 301 https://$host$request_uri;` | Redirect |
| `rewrite ^/old$ /new permanent;` | URL rewrite |
| `error_page 404 /404.html;` | Custom error pages |
| `client_max_body_size 10m;` | Max upload size |
| `keepalive_timeout 65;` | Keep-alive timeout |
| `worker_processes auto;` | Number of worker processes |
| `worker_connections 1024;` | Max connections per worker |

### Certbot Commands

| Command | Purpose |
|---------|---------|
| `sudo certbot --nginx -d example.com` | Get cert and configure Nginx |
| `sudo certbot --apache -d example.com` | Get cert and configure Apache |
| `sudo certbot certonly --nginx -d example.com` | Get cert only, no config |
| `sudo certbot renew` | Renew all certificates |
| `sudo certbot renew --dry-run` | Test renewal process |
| `sudo certbot certificates` | List all certificates |
| `sudo certbot delete --cert-name example.com` | Delete a certificate |
| `sudo systemctl status certbot.timer` | Check auto-renewal timer |

---



---

[← Previous](16-deep-understanding.md) | [↑ Index](index.md) | [Next →](18-whats-coming-in-part-40.md)
