## 🔍 Section 15: Security

### 15.1 Hiding Server Version

**Squid:**

```apache
# Hide Squid version in HTTP headers
httpd_suppress_version_string on

# Custom error pages
error_directory /usr/share/squid/errors/Custom
```

**Nginx:**

```nginx
# /etc/nginx/nginx.conf
http {
    server_tokens off;
    proxy_hide_header X-Powered-By;
    proxy_hide_header Server;
}
```

**HAProxy:**

```cfg
defaults
    # Remove server header from backend responses
    option httpchk
    rspidel ^Server:.*
    rspadd Server:\ HAProxy\ (custom)
```

### 15.2 Rate Limiting with HAProxy

```cfg
frontend web_front
    bind *:80

    # Define stick table for rate limiting
    stick-table type ip size 200k expire 1m store http_req_rate(10s)

    # Track requests per client
    http-request track-sc0 src

    # Block clients exceeding 100 requests in 10 seconds
    http-request deny deny_status 429 if { sc_http_req_rate(0) gt 100 }

    default_backend web_servers
```

### 15.3 ACL Whitelist/Blacklist

**Squid:**

```apache
# Blacklist
acl bad_sites dstdomain .example.com .badplace.com
http_access deny bad_sites

# Whitelist (deny all except whitelisted)
acl allowed_sites dstdomain .work.com .internal.tools
http_access allow allowed_sites
http_access deny all
```

**HAProxy:**

```cfg
frontend web_front
    bind *:80

    # Country-based blocking (requires GeoIP database)
    acl blocked_country src 1.2.3.0/24 4.5.6.0/24
    http-request deny if blocked_country

    # IP whitelist for admin
    acl admin_network src 10.0.0.0/8 192.168.0.0/16
    acl admin_path path_beg /admin
    http-request allow if admin_path admin_network
    http-request deny if admin_path
```

### 15.4 X-Forwarded-For Spoofing Prevention

```nginx
# Nginx — trust only known proxy IPs
set_real_ip_from 10.0.0.0/8;
set_real_ip_from 172.16.0.0/12;
set_real_ip_from 192.168.0.0/16;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

```cfg
# HAProxy
option forwardfor header X-Forwarded-For

# Only if the connecting IP is trusted
# (not built-in HAProxy; use accept-proxy with proxy protocol instead)
```





[← Previous](16-section-14-proxy-protocol.md) | [↑ Index](index.md) | [Next →](18-15-hands-on-practices.md)
