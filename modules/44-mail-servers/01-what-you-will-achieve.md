## 🎯 What You Will Achieve

| Level | Focus | Key Skills |
|-------|-------|------------|
| **Level 1: Basic** | Email concepts, Postfix architecture | SMTP, MTA/MUA/MDA roles, envelope vs header, queue directories |
| **Level 2: Intermediary** | Installation, config, SASL, TLS, aliases, queues | main.cf, virtual domains, Dovecot, logging, queue management |
| **Level 3: Advanced** | Content filtering, access control, troubleshooting | Amavis, rate limiting, SMTP debugging, DKIM signing |

### Why This Part Matters
Email remains the backbone of business communication. Every organization needs a mail server — whether for internal notifications, customer communication, or system alerts. Understanding Postfix and SMTP at a deep level ensures reliable, secure email delivery.

> **Real-world perspective**: When a system alert email does not arrive, or a customer reports they never received your invoice, the problem is almost always in your mail server configuration. Understanding mail queues, DNS records (MX, SPF, DKIM), and TLS is essential for diagnosing these issues.


# ⭐ Level 1: Basic — Email Fundamentals and Postfix Architecture

# 1. Email Basics

Email is a store-and-forward system. The sender's MTA (Mail Transfer Agent) connects to the recipient's MTA via SMTP, delivers the message, and the recipient's MDA (Mail Delivery Agent) places it in a mailbox. The recipient's MUA (Mail User Agent) retrieves it via IMAP or POP3.

At this level you will learn:

- **MTA/MUA/MDA**: MTA (Postfix, Sendmail) transfers email between servers. MUA (Thunderbird, mutt) composes and reads email. MDA (Dovecot, procmail) delivers to mailboxes.
- **SMTP basics**: Simple Mail Transfer Protocol on port 25 (server-to-server), 587 (submission with auth), or 465 (SMTPS). The protocol is text-based: `HELO`, `MAIL FROM:`, `RCPT TO:`, `DATA`.
- **Envelope vs header**: The envelope (MAIL FROM/RCPT TO) determines routing. The header (From, To, Subject) is what the user sees. They can differ — this is how BCC works.
- **Queue directories**: Postfix stores mail in `/var/spool/postfix/`. `incoming/` = new mail. `active/` = being delivered. `deferred/` = delivery failed, will retry. `bounce/` = delivery failed permanently.


[↑ Index](index.md) | [Next →](02-11-vocabulary.md)
