## 13.5 Mail Log Analysis Workflow

```bash
# 1. Find all mail from a specific sender
grep "from=<spammer@spam.com>" /var/log/mail.log

# 2. Trace a queue ID through the entire pipeline
grep "ABCDEF1234" /var/log/mail.log

# 3. Find delivery failures
grep "status=sent" /var/log/mail.log    # successful
grep "status=bounced" /var/log/mail.log # bounced
grep "status=deferred" /var/log/mail.log # temporary failure

# 4. Top sending IPs
grep "client=" /var/log/mail.log | sed 's/.*client=//' | sort | uniq -c | sort -rn | head -20

# 5. Count by relay
grep "relay=" /var/log/mail.log | sed 's/.*relay=//' | cut -d'[' -f1 | sort | uniq -c | sort -rn
```

---

# 14. Dovecot Integration



---

[← Previous](46-134-common-problems.md) | [↑ Index](index.md) | [Next →](48-141-installing-dovecot.md)
