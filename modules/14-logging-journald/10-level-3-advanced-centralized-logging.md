## ⭐ Level 3: Advanced — Centralized Logging and Security

> **Level 3 Goal:** Set up a centralized logging server with rsyslog, master advanced log analysis and troubleshooting patterns, and implement log security measures including integrity protection and compliance.

### What You'll Cover
- Setting up an rsyslog central log server (TCP/UDP reception)
- Forwarding client logs with `omfwd` and encrypted relay
- Log analysis patterns: grepping, `logwatch`, and `awstats`
- Log integrity with `aide` and log signing
- Compliance requirements: log retention, tamper protection, and audit trails

### Why This Level Matters

In a production environment, logs on individual servers are only useful if you can SSH into that server. Centralized logging lets you search, correlate, and alert across your entire fleet from one place. When a breach happens at 3 AM, you do not want to be logging into 15 servers one by one.

Log integrity is not optional in regulated industries. PCI-DSS, HIPAA, and SOC 2 all require tamper-evident logs. An attacker who can delete or modify your logs can hide their tracks. Tools like `aide` and rsyslog's TLS relay prevent this.

### What You'll Practice

- Configuring rsyslog as a central receiver with TCP and TLS
- Setting up `omfwd` on clients to forward logs securely
- Building `logwatch` reports for daily summaries
- Using `aide` to detect unauthorized log modifications
- Writing log retention policies that meet compliance standards

> 💡 Start with a simple rsyslog setup before adding TLS. Get the basics working, then layer on security. Trying to do everything at once is how configs break at 3 AM.





[← Previous](09-section-6-log-rotation-with.md) | [↑ Index](index.md) | [Next →](11-section-7-centralized-logging.md)
