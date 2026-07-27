## 10.1 SMTP Restriction System

Postfix evaluates restrictions as a list — **first match wins**:

```bash
smtpd_client_restrictions =
  permit_mynetworks,
  check_client_access hash:/etc/postfix/access,
  reject_rbl_client zen.spamhaus.org,
  permit

smtpd_helo_restrictions =
  permit_mynetworks,
  reject_invalid_helo_hostname,
  reject_non_fqdn_helo_hostname,
  permit

smtpd_sender_restrictions =
  permit_mynetworks,
  reject_non_fqdn_sender,
  reject_unknown_sender_domain,
  permit

smtpd_recipient_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unauth_destination,
  reject_unknown_recipient_domain,
  permit
```



---

[← Previous](31-93-postscreen-before-queue-built-in.md) | [↑ Index](index.md) | [Next →](33-102-access-table.md)
