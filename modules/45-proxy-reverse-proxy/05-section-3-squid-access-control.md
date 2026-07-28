## 🔍 Section 3: Squid Access Control

### 3.1 ACL Types

Squid ACLs follow this pattern:

```apache
acl NAME TYPE ARGUMENT
```

| ACL Type | Matches | Example |
|----------|---------|---------|
| `src` | Client source IP | `acl home_network src 192.168.1.0/24` |
| `dst` | Destination IP | `acl corp_server dst 10.0.0.50` |
| `dstdomain` | Domain name in the URL | `acl banned_sites dstdomain .facebook.com` |
| `method` | HTTP method (GET, POST, CONNECT) | `acl connect_method method CONNECT` |
| `port` | Destination port | `acl SSL_ports port 443` |
| `time` | Day and time | `acl work_hours time MTWHF 09:00-17:00` |
| `url_regex` | Regex match against URL | `acl torrent_url url_regex -i torrent` |
| `urlpath_regex` | Regex match URL path only | `acl admin_path urlpath_regex ^/admin` |
| `maxconn` | Max concurrent connections | `acl too_many maxconn 20` |
| `random` | Random probability | `acl test_users random 0.1` |

### 3.2 http_access Rules

Rules are evaluated top-to-bottom. **Last matching rule wins.** If no rule matches, the default is `deny`.

```apache
# Order matters!
acl work_hours time MTWHF 09:00-17:00
acl banned_sites dstdomain .facebook.com .twitter.com .youtube.com
acl localnet src 192.168.0.0/16

# Block banned sites during work hours
http_access deny banned_sites work_hours

# Allow local network always
http_access allow localnet

# Block everything else
http_access deny all
```

### 3.3 Authentication

Squid supports multiple authentication schemes via `auth_param`.

**Basic authentication (plaintext — use only over TLS or in lab):**

```apache
# Generate passwords
sudo apt install apache2-utils -y
sudo htpasswd -c /etc/squid/passwd user1
sudo htpasswd /etc/squid/passwd user2

# In squid.conf
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Proxy Authentication
auth_param basic credentialsttl 2 hours

acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
```

**Digest authentication (more secure):**

```apache
auth_param digest program /usr/lib/squid/digest_file_auth /etc/squid/digest_passwd
auth_param digest children 5
auth_param digest realm Squid Digest Realm
auth_param digest nonce_garbage_interval 5 minutes

acl auth_users proxy_auth REQUIRED
http_access allow auth_users
http_access deny all
```

**NTLM / Negotiate (Kerberos) — Active Directory integration:**

```apache
auth_param ntlm program /usr/lib/squid/negotiate_ntlm_auth -d
auth_param ntlm children 10
auth_param negotiate program /usr/lib/squid/negotiate_kerberos_auth -d
auth_param negotiate children 10

acl ad_users proxy_auth REQUIRED
http_access allow ad_users
http_access deny all
```

### 3.4 Practical ACL Configuration

```apache
# /etc/squid/squid.conf — Comprehensive ACL setup

# Network ACLs
acl all src 0.0.0.0/0
acl management src 10.0.0.100-10.0.0.120
acl guests src 192.168.100.0/24

# Time ACLs
acl work_hours time MTWHF 08:00-18:00
acl weekend time SA 00:00-23:59

# Destination ACLs
acl social_media dstdomain .facebook.com .instagram.com .twitter.com
acl streaming dstdomain .netflix.com .hulu.com .youtube.com
acl malware dstdom_regex (phishing|malware|cryptominer)\.*
acl allowed_ssl_ports port 443 563
acl allowed_ports port 80 443 21 22 8080 8443

# Protocol ACLs
acl CONNECT method CONNECT
acl SSL method GET method POST

# Restrictions
acl max_download maxconn 10

# Block malware regardless of user
http_access deny malware

# Block social media during work hours for everyone
http_access deny social_media work_hours

# Guests: no streaming, no social media (even on weekends)
http_access deny guests streaming
http_access deny guests social_media

# Management: unrestricted
http_access allow management

# Allow CONNECT only to SSL ports
http_access deny CONNECT !allowed_ssl_ports

# Allow only safe ports
http_access deny !allowed_ports

# Default deny
http_access deny all
```





[← Previous](04-section-2-squid-forward-proxy.md) | [↑ Index](index.md) | [Next →](06-section-4-squid-caching.md)
