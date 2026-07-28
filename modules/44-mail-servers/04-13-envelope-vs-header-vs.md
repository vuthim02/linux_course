## 1.3 Envelope vs Header vs Body

Every email has three distinct parts:

```
Envelope (SMTP-level, not visible in the message):
  MAIL FROM:<bounce-return@example.com>
  RCPT TO:<actual-recipient@example.org>

Header (visible RFC 5322 metadata):
  From:    "Sender" <sender@example.com>
  To:      recipient@example.org
  Subject: Hello
  Date:    Wed, 24 Jun 2026 10:00:00 +0000

Body (empty line + content):
  Hi, this is the message body.
```

**Critical distinction**: the envelope `MAIL FROM` is where bounces go. The `From:` header is cosmetic. Spammers forge headers but the envelope is what MTAs trust.




[← Previous](03-12-message-flow.md) | [↑ Index](index.md) | [Next →](05-14-message-format-rfc-5322.md)
