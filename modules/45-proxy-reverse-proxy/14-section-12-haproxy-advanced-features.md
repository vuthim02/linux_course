## 🔍 Section 12: HAProxy Advanced Features

### 12.1 ACLs and Content Switching

```cfg
frontend web_front
    bind *:80
    bind *:443 ssl crt /etc/ssl/haproxy.pem

    # ACLs — define conditions
    acl is_api        path_beg /api/
    acl is_static     path_end .jpg .png .css .js .ico
    acl is_admin      path_beg /admin
    acl is_mobile     hdr_sub(User-Agent) -i mobile
    acl is_websocket  hdr(Upgrade) -i websocket
    acl is_internal   src 10.0.0.0/8
    acl is_secure     ssl_fc  # Connection is over TLS

    # Content switching — route based on ACLs
    use_backend api_servers      if is_api
    use_backend static_servers   if is_static
    use_backend admin_servers    if is_admin is_internal
    use_backend ws_servers       if is_websocket

    # Default backend
    default_backend web_servers
```

### 12.2 SSL Termination

```cfg
global
    # Tune SSL parameters
    tune.ssl.default-dh-param 2048
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM...
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11

frontend https_front
    # Single PEM file (cert + key + CA chain)
    bind *:443 ssl crt /etc/ssl/haproxy.pem

    # Multiple certificates (SNI)
    bind *:443 ssl crt /etc/ssl/certs/ crt-list /etc/ssl/haproxy_crtlist.txt

    # OCSP stapling
    bind *:443 ssl crt /etc/ssl/haproxy.pem ca-file /etc/ssl/ca.crt crt-ignore-err all

    # Redirect HTTP to HTTPS
    redirect scheme https code 301 if !{ ssl_fc }

    default_backend web_servers
```

### 12.3 Stats Page

```cfg
frontend stats_front
    bind *:8404
    stats enable
    stats uri /haproxy-stats
    stats refresh 5s
    stats admin if LOCALHOST
    stats auth admin:SecurePass1!

# Or in a listen section (commonly used)
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats auth admin:changeme
    stats refresh 10s
    stats admin if TRUE

# Access it: http://server:8404/stats
```

### 12.4 Logging

```cfg
global
    log /dev/log local0 info
    log /dev/log local1 notice

defaults
    log global
    option httplog
    log-format "%ci:%cp [%t] %ft %b/%s %Tq/%Tw/%Tc/%Tr/%Ta %ST %B %CC %CS %tsc %ac/%fc/%bc/%sc/%rc %sq/%bq %hr %hs %{+Q}r"

# Syslog setup
# /etc/rsyslog.d/haproxy.conf
# local0.*  /var/log/haproxy.log
# local1.*  /var/log/haproxy-error.log

# Then restart rsyslog
sudo systemctl restart rsyslog
```





[← Previous](13-section-11-haproxy-load-balancing.md) | [↑ Index](index.md) | [Next →](15-section-13-proxy-chaining-and.md)
