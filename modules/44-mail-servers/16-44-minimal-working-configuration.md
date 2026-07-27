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

---

# 5. SMTP Authentication (SASL)



---

[← Previous](15-43-recipient-delimiter.md) | [↑ Index](index.md) | [Next →](17-51-why-sasl.md)
