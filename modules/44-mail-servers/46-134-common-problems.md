## 13.4 Common Problems

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Connection refused port 25 | `inet_interfaces` wrong | `postconf inet_interfaces` |
| Relay access denied | SASL not set up or not permitted | Check `smtpd_relay_restrictions` |
| Connection timeout | Firewall, DNS, or relayhost down | `telnet relayhost 25` |
| "Helo command rejected: need fully-qualified hostname" | Hostname not FQDN | Fix `myhostname` |
| Queue not draining | DNS resolution failures | `postfix flush` + check `/var/log/mail.log` |
| Certificate warnings | Let's Encrypt expired / permissions | `certbot renew` + check file perms |

**Troubleshooting workflow**:

1. **Check the queue**: `postqueue -p` shows all deferred messages. `postcat -q MESSAGE_ID` shows the full message with headers.
2. **Check logs**: `tail -f /var/log/mail.log` (Debian) or `journalctl -u postfix -f` (RHEL) shows real-time delivery attempts. Look for `status=bounced` or `status=deferred`.
3. **Check DNS**: `dig MX example.com` verifies MX records exist. `dig A mail.example.com` verifies the MX host resolves. No MX = no delivery.
4. **Test connectivity**: `telnet mail.example.com 25` tests SMTP connectivity. `openssl s_client -connect mail.example.com:587 -starttls smtp` tests TLS.
5. **Check authentication**: `postconf | grep SASL` shows SASL configuration. Test with `swaks --to user@example.com --server localhost --port 587 --auth-user user`.


[← Previous](45-133-enable-auth-logging-careful.md) | [↑ Index](index.md) | [Next →](47-135-mail-log-analysis-workflow.md)
