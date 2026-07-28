## 🔍 Section 2: Apache — Installation and Basics

### Installation

```bash
sudo apt update
sudo apt install apache2 -y

# Verify it's running
sudo systemctl status apache2

# Check the version
apache2 -v
```

### Directory Layout

```
/etc/apache2/
├── apache2.conf              # Main config file
├── ports.conf                # Ports to listen on (80, 443)
├── conf-available/           # Optional config snippets
├── conf-enabled/             # Enabled config snippets (symlinks)
├── mods-available/           # Available modules (.load + .conf files)
├── mods-enabled/             # Enabled modules (symlinks)
├── sites-available/          # Available virtual host configs
└── sites-enabled/            # Enabled virtual hosts (symlinks)
```

### The `a2` Tools

These are symlink managers for sites and modules:

| Command | What It Does |
|---------|--------------|
| `a2ensite site.conf` | Enable a site (create symlink in sites-enabled) |
| `a2dissite site.conf` | Disable a site (remove symlink) |
| `a2enmod module` | Enable a module (create symlink in mods-enabled) |
| `a2dismod module` | Disable a module (remove symlink) |
| `a2enconf config` | Enable a config file |
| `a2disconf config` | Disable a config file |

```bash
# Enable SSL module
sudo a2enmod ssl

# Enable rewrite module
sudo a2enmod rewrite

# Enable a site
sudo a2ensite my-site.conf

# Reload Apache to apply changes
sudo systemctl reload apache2
```

### Default Site

```bash
# The default site config
cat /etc/apache2/sites-available/000-default.conf
```

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

The default document root is `/var/www/html/`. Replace the `index.html` there to see your own page.





[← Previous](02-section-1-web-server-basics.md) | [↑ Index](index.md) | [Next →](04-section-3-apache-virtual-hosts.md)
