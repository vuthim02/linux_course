## ⭐ Level 3: Advanced Commands

| Command | Purpose |
|---------|---------|
| `postfix check` | Validate configuration |
| `postfix flush` | Force delivery attempt of all queued mail |


# What's Coming in Part 45

**Part 45: Proxy and Reverse Proxy** — We will cover the theory and implementation of forward proxies, reverse proxies, and load balancers using Nginx, HAProxy, and Squid. Topics include: proxy protocols (HTTP CONNECT, SOCKS5), caching reverse proxies, TLS termination, load-balancing algorithms (round-robin, least connections, IP hash), health checks, WebSocket proxying, gRPC proxying, and ACL configuration. We will also discuss proxy chaining and transparent proxying with iptables.


# Self-Test

Answer these 15 questions. **Score:** 12/15 correct = ready for Part 45.

### Question 1
What is the difference between MTA and MDA?

<details>
<summary>Answer</summary>
MTA (Mail Transfer Agent) relays mail between servers using SMTP. MDA (Mail Delivery Agent) delivers mail to the recipient's mailbox on disk. In Postfix, the `local` and `virtual` delivery agents are MDAs.
</details>

### Question 2
Which Postfix daemon canonicalises message headers and adds Received: headers?

<details>
<summary>Answer</summary>
`cleanup` — it runs between `pickup`/`smtpd` and `qmgr`.
</details>

### Question 3
What does the command `postconf -n` show?

<details>
<summary>Answer</summary>
Only parameters whose current value differs from the compiled-in default (non-default parameters).
</details>

### Question 4
Explain the difference between `smtpd_use_tls` and `smtpd_tls_security_level = may`.

<details>
<summary>Answer</summary>
`smtpd_use_tls = yes` is the older (legacy) way to enable STARTTLS. `smtpd_tls_security_level = may` is the modern equivalent — it offers TLS but does not require it. `smtpd_tls_security_level = encrypt` forces TLS (client MUST use STARTTLS). The `_security_level` parameter is preferred.
</details>

### Question 5
What file must be updated after editing `/etc/postfix/virtual`?

<details>
<summary>Answer</summary>
You must run `sudo postmap /etc/postfix/virtual` to rebuild the indexed database `/etc/postfix/virtual.db`.
</details>

### Question 6
What is the difference between `virtual_alias_domains` and `virtual_mailbox_domains`?

<details>
<summary>Answer</summary>
`virtual_alias_domains` — all mail is forwarded to external addresses (no local storage). `virtual_mailbox_domains` — mail is stored locally in virtual mailboxes using the `virtual` delivery agent or LMTP to Dovecot.
</details>

### Question 7
How do you delete all messages in the deferred queue?

<details>
<summary>Answer</summary>
`sudo postsuper -d ALL deferred`
</details>

### Question 8
What is the purpose of `smtpd_relay_restrictions`?

<details>
<summary>Answer</summary>
It controls who is allowed to relay mail through the server. Evaluated after client/helo/sender restrictions and before recipient restrictions. Typical rule: `permit_mynetworks, permit_sasl_authenticated, defer_unauth_destination`.
</details>

### Question 9
What port does LMTP use, and why is it preferred for Postfix → Dovecot delivery?

<details>
<summary>Answer</summary>
LMTP is usually done over a Unix socket (`private/dovecot-lmtp`) rather than a TCP port. It is preferred because it avoids a second network stack pass and gives Dovecot direct control over mailbox delivery and quota enforcement.
</details>

### Question 10
What command generates a daily Postfix summary from log files?

<details>
<summary>Answer</summary>
`sudo pflogsumm -d yesterday /var/log/mail.log` or `sudo pflogsumm -d today /var/log/mail.log`.
</details>

### Question 11
What is the SMTP envelope, and how does it differ from the message headers?

<details>
<summary>Answer</summary>
The envelope is the SMTP-level addressing used during transit: `MAIL FROM` (return path for bounces) and `RCPT TO` (actual recipient). Headers are visible metadata inside the message body (RFC 5322). Envelope and headers can differ (e.g., Bcc recipients appear only in the envelope).
</details>

### Question 12
What does the `postsuper -r ALL` command do?

<details>
<summary>Answer</summary>
It rotates the queue IDs of all deferred messages and moves them back to the incoming queue, forcing the queue manager to attempt immediate delivery as if they were new messages.
</details>

### Question 13
How does Postfix implement rate limiting for incoming SMTP connections?

<details>
<summary>Answer</summary>
Through the built-in `anvil` service which tracks per-IP connection counts and rates. Parameters: `smtpd_client_connection_count_limit`, `smtpd_client_connection_rate_limit`, `smtpd_client_error_rate_limit`.
</details>

### Question 14
What is the purpose of the `check_policy_service` restriction?

<details>
<summary>Answer</summary>
It delegates access control decisions to an external policy daemon (e.g., postgrey for greylisting, postfwd for complex policies). The daemon listens on a socket (Unix or TCP) and returns `DUNNO`, `OK`, or `REJECT` actions.
</details>

### Question 15
What is the purpose of DKIM, and what DNS record must be published to support it?

<details>
<summary>Answer</summary>
DKIM (DomainKeys Identified Mail) allows the sending domain to cryptographically sign outgoing mail. Receiving MTAs verify the signature using the public key published in DNS at `{selector}._domainkey.{domain}` as a TXT record containing the DKIM key data (`v=DKIM1; p=...`).
</details>


### Scoring

```
12–15 correct → 🟢 Ready for Part 45
 8–11 correct → 🟡 Review Sections 2, 4, 11, 13
  0–7 correct → 🔴 Re-read this part, do the hands-on practices
```


*Previous → Part 43: DHCP Server*
*Next → Part 45: Proxy and Reverse Proxy*

[← Previous](part43.md) | [Next →](part45.md)



[← Previous](62-level-2-intermediary-commands.md) | [↑ Index](index.md)
