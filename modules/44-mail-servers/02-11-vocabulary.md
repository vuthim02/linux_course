## 1.1 Vocabulary

| Term | Meaning | Example |
|------|---------|---------|
| **MUA** | Mail User Agent — the client | Thunderbird, mutt, Outlook |
| **MTA** | Mail Transfer Agent — relays mail | Postfix, Exim, Sendmail |
| **MDA** | Mail Delivery Agent — delivers to mailbox | Postfix `local`, Dovecot LMTP, procmail |
| **SMTP** | Simple Mail Transfer Protocol (RFC 5321) | Port 25 (submission: 587, SMTPS: 465) |
| **IMAP** | Internet Message Access Protocol | Port 143 (TLS: 993) — keeps mail on server |
| **POP3** | Post Office Protocol v3 | Port 110 (TLS: 995) — downloads & deletes |

### Additional Terms

| Term | Meaning |
|------|---------|
| **DKIM** | DomainKeys Identified Mail — cryptographic signature proving origin |
| **SPF** | Sender Policy Framework — DNS record listing authorized senders |
| **DMARC** | Domain-based Message Authentication — policy for SPF/DKIM failures |
| **SASL** | Simple Authentication and Security Layer — auth framework for SMTP |
| **LMTP** | Local Mail Transfer Protocol — simplified SMTP for local delivery |
| **Bayesian filter** | Statistical spam classifier trained on ham/spam corpus |


[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-12-message-flow.md)
