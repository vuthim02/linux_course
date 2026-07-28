## 📖 Section 16: What's Coming in Part 44

**Part 44: Mail Servers — Postfix** — Email is one of the oldest and most complex internet services. You will learn SMTP fundamentals, Postfix installation and `main.cf` configuration, SMTP authentication (Dovecot SASL), TLS encryption (STARTTLS), Dovecot IMAP/POP3 delivery, virtual mailboxes (multi-domain), SPF/DKIM/DMARC anti-spam, mail queues (`mailq`, `postqueue`, `postcat`), rate limiting, and integration with LDAP/MySQL.

```
Previous → Part 42: DNS Server Administration (BIND)
Next → Part 44: Mail Servers — Postfix
```

### How This Connects
Mail servers depend on DNS (MX records, SPF, DKIM), DHCP (client IP assignment), and network configuration (ports 25, 587, 993). Everything you have learned in Parts 26-43 comes together in email infrastructure. A mail server is one of the most complex services to configure correctly because it touches DNS, TLS, authentication, storage, and anti-spam simultaneously.

> **Key connection**: Postfix uses DNS for routing (MX lookups), Dovecot uses PAM/LDAP for authentication, and TLS certificates come from Let's Encrypt (covered in Part 42). This part integrates knowledge from nearly every preceding module.





[← Previous](19-section-15-command-reference.md) | [↑ Index](index.md) | [Next →](21-section-17-self-test.md)
