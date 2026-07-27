## 12.2 Interpreting Log Entries

```
Jun 24 10:00:00 mail postfix/smtpd[12345]: ABCDEF1234: client=unknown[10.0.0.1]
Jun 24 10:00:01 mail postfix/cleanup[12346]: ABCDEF1234: message-id=<20260624.1000@example.com>
Jun 24 10:00:01 mail postfix/qmgr[12347]: ABCDEF1234: from=<sender@example.com>, size=2500, nrcpt=1
Jun 24 10:00:02 mail postfix/smtp[12348]: ABCDEF1234: to=<recipient@example.org>, relay=mx.example.org[203.0.113.5]:25, delay=0.5, status=sent (250 OK)
```

Fields: `timestamp host process[pid]: queueid: event details`



---

[← Previous](40-121-log-locations.md) | [↑ Index](index.md) | [Next →](42-123-log-summaries-with-pflogsumm.md)
