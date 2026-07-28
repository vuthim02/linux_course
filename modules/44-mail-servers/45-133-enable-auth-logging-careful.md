## 13.3 Enable Auth Logging (Careful!)

```bash
# /etc/postfix/main.cf — DO NOT leave on in production (logs passwords!)
smtpd_sasl_authenticated_header = yes
```

This shows the SASL username in `Received:` headers and logs.

### Why It's Dangerous

When enabled, the SASL username appears in mail headers:

```
Received: from client.example.com (client.example.com [10.0.0.5])
    (authenticated bits=0)
    by mail.example.com with ESMTPSA id ABC123
```

The `authenticated bits=0` line reveals the username. If this mail is forwarded or stored insecurely, the username is exposed.

### Safe Usage

```bash
# Enable temporarily for debugging authentication issues
postconf -e "smtpd_sasl_authenticated_header = yes"
# Debug the issue...
postconf -e "smtpd_sasl_authenticated_header = no"
```

### Key Takeaway
Only enable this for short debugging sessions. Remove it before closing your troubleshooting ticket.


[← Previous](44-132-smtp-protocol-debugging.md) | [↑ Index](index.md) | [Next →](46-134-common-problems.md)
