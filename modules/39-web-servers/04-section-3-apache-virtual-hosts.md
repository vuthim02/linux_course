## 🔍 Section 3: Apache Virtual Hosts

### Basic Virtual Host

```apache
# /etc/apache2/sites-available/example.com.conf

<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    ServerAdmin admin@example.com
    DocumentRoot /var/www/example.com

    <Directory /var/www/example.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/example.com-error.log
    CustomLog ${APACHE_LOG_DIR}/example.com-access.log combined
</VirtualHost>
```

### `ServerName` and `ServerAlias`

- `ServerName` — the primary domain name Apache matches against the `Host` header
- `ServerAlias` — additional domain names that should resolve to this site

```apache
ServerName example.com
ServerAlias www.example.com shop.example.com
```

### Directory Directives

Inside `<Directory>` blocks you control access and behavior for filesystem paths:

```apache
<Directory /var/www/example.com>
    # Options: Indexes (show dir listing), FollowSymLinks, MultiViews
    Options Indexes FollowSymLinks MultiViews

    # AllowOverride: what .htaccess files can override
    # All = allow everything, None = ignore .htaccess, Limit = limited directives
    AllowOverride All

    # Access control: who can access this directory
    Require all granted          # Everyone
    # Require ip 192.168.1.0/24  # Only local network
    # Require valid-user         # Requires authentication
</Directory>
```

### `.htaccess` Files

`.htaccess` files allow per-directory configuration changes **without editing the main config**. They are checked on every request — Apache walks up the directory tree looking for `.htaccess` files. This is a **performance cost**.

```apache
# To enable .htaccess parsing:
AllowOverride All
```

A typical `.htaccess`:

```apache
# /var/www/example.com/.htaccess

RewriteEngine On
RewriteRule ^old-page$ /new-page [R=301,L]

# Deny access to sensitive files
<FilesMatch "\.(env|config|sql|md)$">
    Require all denied
</FilesMatch>

# Enable caching for static assets
<FilesMatch "\.(css|js|jpg|png)$">
    Header set Cache-Control "max-age=2592000, public"
</FilesMatch>

# Set default charset
AddDefaultCharset UTF-8
```

> **Nginx does not support .htaccess.** This is one of the biggest differences. Nginx evaluates all config at startup — there is no per-request file lookup overhead. Apache's .htaccess is both a feature (easy for users) and a liability (slow under load).

### Name-based vs IP-based Virtual Hosts

| Type | When Used | Config |
|------|-----------|--------|
| Name-based | Single IP, multiple domains (standard) | `<VirtualHost *:80>` |
| IP-based | Multiple IPs, different sites per IP | `<VirtualHost 192.168.1.10:80>` |

The vast majority of setups are name-based.





[← Previous](03-section-2-apache-installation-and.md) | [↑ Index](index.md) | [Next →](05-section-4-apache-modules.md)
