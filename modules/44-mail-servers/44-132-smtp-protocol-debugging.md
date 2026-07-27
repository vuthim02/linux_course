## 13.2 SMTP Protocol Debugging

```bash
# Manual SMTP conversation (like a restricted telnet)
telnet mail.example.com 25

Trying 203.0.113.5...
Connected to mail.example.com.
Escape character is '^]'.
220 mail.example.com ESMTP Postfix (Debian/GNU)
EHLO test
250-mail.example.com
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-STARTTLS
250-AUTH PLAIN LOGIN
250-ENHANCEDSTATUSCODES
250-8BITMIME
250-DSN
250-SMTPUTF8
250 CHUNKING
MAIL FROM:<test@example.com>
250 2.1.0 Ok
RCPT TO:<alice@example.com>
250 2.1.5 Ok
DATA
354 End data with <CR><LF>.<CR><LF>
Subject: Test

Hello from telnet.
.
250 2.0.0 Ok: queued as ABCDEF1234
QUIT
221 2.0.0 Bye
```



---

[← Previous](43-131-configuration-verification.md) | [↑ Index](index.md) | [Next →](45-133-enable-auth-logging-careful.md)
