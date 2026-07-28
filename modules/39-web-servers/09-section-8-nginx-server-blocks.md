## 🔍 Section 8: Nginx Server Blocks

### Basic Server Block

```nginx
# /etc/nginx/sites-available/example.com

server {
    listen 80;
    listen [::]:80;                        # IPv6
    server_name example.com www.example.com;

    root /var/www/example.com;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/example.com-access.log;
    error_log /var/log/nginx/example.com-error.log;
}
```

### `server_name` Directive

Nginx matches `server_name` against the `Host` header. Multiple names are space-separated.

```nginx
server_name example.com www.example.com *.example.com ~^(www\.)?(?<domain>.+)$;
```

Wildcard: `*.example.com` matches `shop.example.com` but not `example.com`.
Regex: prefix with `~`.

When no server block matches, Nginx uses the **default server** (the first one defined, or the one with `default_server`):

```nginx
listen 80 default_server;
```

### `location` Directive Types

```nginx
location / {                    # Prefix match (matches everything starting with /)
    ...
}

location = /exact {             # Exact match (highest priority)
    ...
}

location ~ \.php$ {             # Regex match (case-sensitive)
    ...
}

location ~* \.(jpg|png)$ {      # Regex match (case-insensitive)
    ...
}

location ^~ /static/ {          # Prefix match, stop regex checking
    ...
}
```

**Nginx location matching order:**
1. `=` exact matches (highest priority)
2. `^~` prefix matches (stop regex search)
3. `~` and `~*` regex matches (in order in config file)
4. Regular prefix matches (longest match wins)

### `try_files`

The most powerful Nginx directive for static file serving:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

This tries:
1. `$uri` — the exact file path (e.g., `/about.html`)
2. `$uri/` — the path as a directory (e.g., `/about/`)
3. `/index.html` — fallback to the index file

This enables SPA (Single Page Application) routing — all paths serve `index.html`:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### Serving PHP with PHP-FPM

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/example.com;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```





[← Previous](08-section-7-nginx-installation-and.md) | [↑ Index](index.md) | [Next →](10-section-9-nginx-as-reverse.md)
