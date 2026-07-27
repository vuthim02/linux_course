## 13.4 Common Problems

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Connection refused port 25 | `inet_interfaces` wrong | `postconf inet_interfaces` |
| Relay access denied | SASL not set up or not permitted | Check `smtpd_relay_restrictions` |
| Connection timeout | Firewall, DNS, or relayhost down | `telnet relayhost 25` |
| "Helo command rejected: need fully-qualified hostname" | Hostname not FQDN | Fix `myhostname` |
| Queue not draining | DNS resolution failures | `postfix flush` + check `/var/log/mail.log` |
| Certificate warnings | Let's Encrypt expired / permissions | `certbot renew` + check file perms |



---

[← Previous](45-133-enable-auth-logging-careful.md) | [↑ Index](index.md) | [Next →](47-135-mail-log-analysis-workflow.md)
