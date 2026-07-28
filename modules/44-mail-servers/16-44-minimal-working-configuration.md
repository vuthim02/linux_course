## 4.4 Minimal Working Configuration

```bash
myhostname = mail.example.com
mydomain   = example.com
myorigin   = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
mynetworks = 127.0.0.0/8, 10.0.0.0/24
relayhost =
```

### Parameter Explanation

| Parameter | What It Does |
|-----------|-------------|
| `myhostname` | Server's FQDN |
| `mydomain` | The domain this server handles |
| `myorigin` | Domain appended to local mail From: headers |
| `inet_interfaces` | What IPs to listen on (`all` = everything) |
| `mydestination` | Domains this server accepts mail **for** (final delivery) |
| `mynetworks` | Trusted networks (can relay without auth) |
| `relayhost` | Smarthost (empty = send directly to MX) |

### After Editing

```bash
postfix check      # verify syntax
sudo postfix reload # apply changes
```


# 5. SMTP Authentication (SASL)


[← Previous](15-43-recipient-delimiter.md) | [↑ Index](index.md) | [Next →](17-51-why-sasl.md)
