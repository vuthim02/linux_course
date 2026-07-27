# 🐧 Linux System Administrator — Complete Course
## Part 44 of ∞: Mail Servers — Postfix

---

> **Reverse Engineering Approach:** Instead of memorising config directives, we work **backwards**: start with a working Postfix installation, inspect every running process, trace a message from submission to delivery, and deliberately break things to learn recovery. By the time you finish this part, you will understand Postfix not as a list of parameters but as a **co-operating pipeline of specialised daemons**.

---

## 🎯 What You Will Achieve

| Level | Focus | Key Skills |
|-------|-------|------------|
| **Level 1: Basic** | Email concepts, Postfix architecture | SMTP, MTA/MUA/MDA roles, envelope vs header, queue directories |
| **Level 2: Intermediary** | Installation, config, SASL, TLS, aliases, queues | main.cf, virtual domains, Dovecot, logging, queue management |
| **Level 3: Advanced** | Content filtering, access control, troubleshooting | Amavis, rate limiting, SMTP debugging, DKIM signing |

---

# ⭐ Level 1: Basic — Email Fundamentals and Postfix Architecture

# 1. Email Basics

## 1.1 Vocabulary

| Term | Meaning | Example |
|------|---------|---------|
| **MUA** | Mail User Agent — the client | Thunderbird, mutt, Outlook |
| **MTA** | Mail Transfer Agent — relays mail | Postfix, Exim, Sendmail |
| **MDA** | Mail Delivery Agent — delivers to mailbox | Postfix `local`, Dovecot LMTP, procmail |
| **SMTP** | Simple Mail Transfer Protocol (RFC 5321) | Port 25 (submission: 587, SMTPS: 465) |
| **IMAP** | Internet Message Access Protocol | Port 143 (TLS: 993) — keeps mail on server |
| **POP3** | Post Office Protocol v3 | Port 110 (TLS: 995) — downloads & deletes |

## 1.2 Message Flow

```
MUA ──SMTP──▶ MTA (outbound) ──SMTP──▶ MTA (inbound) ──LMTP/MDA──▶ Mailbox ──IMAP/POP3──▶ MUA
```

Concrete example:

```
Thunderbird ──SMTP:587──▶ Postfix (relay) ──SMTP:25──▶ Postfix (destination)
    │                                                          │
    │                                                     Dovecot IMAP:993
    └───────────────────────────────────────────────────────────┘
```

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

## 1.4 Message Format (RFC 5322)

```
Received: from mail.example.com (…)
  by mx.example.org (Postfix) with ESMTP id ABC123
  for <recipient@example.org>; Wed, 24 Jun 2026 10:00:00 +0000
From: Alice <alice@example.com>
To: Bob <bob@example.org>
Subject: Meeting at 3pm
Date: Wed, 24 Jun 2026 09:55:00 +0000
Message-ID: <20260624095500.ABCD@example.com>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8

Bob,

See you in the conference room.

Best,
Alice
```

Each `Received:` header is added by every MTA that handles the message — invaluable for tracing.

---

# 2. Postfix Architecture

## 2.1 Process Model (Pre-fork)

Postfix does **not** spawn a new process per connection. The `master` daemon pre-forks a pool of children:

```
master (pid 1 for Postfix)
  ├── smtpd      (incoming SMTP connections)
  ├── pickup     (retrieves local submissions from maildrop)
  ├── cleanup    (canonicalises headers, adds Received)
  ├── qmgr       (queue manager — sorts and schedules deliveries)
  ├── trivial-rewrite (address rewriting, transport maps)
  ├── bounce     (generates bounce messages)
  ├── local      (delivery to local UNIX accounts / mailboxes)
  ├── virtual    (delivery to virtual mailbox domains)
  └── pipe       (delivery via external command)
```

The queue manager (`qmgr`) is the **heart**. It reads the queue directories, groups messages by destination, and hands them off to the appropriate delivery agent (`smtp` for remote, `local` for local, `virtual` for virtual domains).

## 2.2 Queue Directories

All queues live under `/var/spool/postfix/`:

| Directory | Purpose |
|-----------|---------|
| `maildrop/` | Local submissions (setuid, world-writable) |
| `incoming/` | Messages received from the network |
| `active/` | Messages being processed right now (limited) |
| `deferred/` | Messages that failed temporarily |
| `hold/` | Messages held by admin (or content filter) |
| `bounce/` | Bounce message templates |
| `corrupt/` | Unreadable messages |

The **active** queue is a view — files are hardlinked from `incoming` or `deferred`. The `qmgr` limits active messages to prevent resource exhaustion (default: 20000).

## 2.3 Message Flow Through Queues

```
pickup ─▶ maildrop/
smtpd ──▶ incoming/ ──▶ cleanup ──▶ qmgr ──▶ active/
                  │                           ├── local delivery
                  │                           ├── smtp delivery
                  │                           └── defer → deferred/
```

---

# 3. Installation

## 3.1 Installing Postfix

```bash
# Debian / Ubuntu
sudo apt update
sudo apt install postfix

# During install you will be prompted for "General type of mail configuration":
#   No Configuration   — no config at all
#   Internet Site      — send/receive directly (recommended for learning)
#   Satellite System   — relay all mail through a smarthost
#   Local Only         — deliver locally only
#
# Choose "Internet Site" and set "System mail name" to your domain.
```

## 3.2 Reconfiguring Postfix

```bash
sudo dpkg-reconfigure postfix
```

This rewrites `/etc/postfix/main.cf` with interactive prompts. Useful for fast prototyping.

## 3.3 Examining Configuration

**Do not** just open `main.cf` — use the `postconf` command:

```bash
# Show non-default parameters only
postconf -n

# Show ALL parameters with their current values
postconf -d

# Show a single parameter
postconf myhostname

# Show a parameter's default
postconf -d myhostname
```

The `-n` flag is your daily driver. It filters out everything that is still at the compiled-in default.

## 3.4 main.cf Structure

```
# This is a comment
parameter = value
parameter = value1, value2    # comma or whitespace separated
parameter = $other_param      # variable expansion
parameter =                   # empty value (resets to default)
```

---

# ⭐ Level 2: Intermediary — Configuration and Daily Management

# 4. Basic Configuration

## 4.1 Identity Parameters

```bash
# /etc/postfix/main.cf

myhostname = mail.example.com
mydomain   = example.com
myorigin   = $myhostname        # or $mydomain — what domain appears in From:
```

- `myhostname` — the FQDN of this mail server
- `mydomain` — the DNS domain
- `myorigin` — domain appended to locally-posted mail (e.g. `myorigin = $mydomain` makes `whoami` → `whoami@example.com`)

## 4.2 Listening and Delivery

```bash
# What interfaces to listen on
inet_interfaces = all            # listen on all (default)
inet_interfaces = loopback-only  # local delivery only

# What domains this server considers "local" (final destination)
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# What networks are trusted to relay mail through us
mynetworks = 127.0.0.0/8, 10.0.0.0/24

# Relaying all outbound mail through a smarthost
relayhost = [smtp.example.com]:587    # bracket = MX lookup disabled, use A/AAAA
```

## 4.3 Recipient Delimiter

```bash
recipient_delimiter = +
```

Allows `user+tag@domain` — useful for filtering. Postfix strips `+tag` before delivery.

## 4.4 Minimal Working Configuration

```bash
myhostname = mail.example.com
mydomain   = example.com
myorigin   = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
mynetworks = 127.0.0.0/8, 10.0.0.0/24
relayhost =
```

---

# 5. SMTP Authentication (SASL)

## 5.1 Why SASL

Without SASL, your server is an open relay or only accepts mail from `mynetworks`. SASL (Simple Authentication and Security Layer) lets remote users **authenticate** before relaying.

## 5.2 Dovecot SASL (Preferred)

Modern setups delegate SASL to Dovecot:

```bash
# /etc/postfix/main.cf
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth          # Dovecot's auth socket
smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = yes
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, defer_unauth_destination
```

On the Dovecot side (`/etc/dovecot/conf.d/10-master.conf`):

```bash
# Dovecot auth socket for Postfix
unix_listener /var/spool/postfix/private/auth {
  mode = 0660
  user = postfix
  group = postfix
}
```

## 5.3 Cyrus SASL (Legacy)

```bash
# /etc/postfix/main.cf
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname
broken_sasl_auth_clients = yes
```

```bash
# /etc/postfix/sasl/smtpd.conf
pwcheck_method: saslauthd
mech_list: PLAIN LOGIN
```

## 5.4 SASL for Outbound Relaying

If you relay through a provider (e.g. Amazon SES, Mailgun, your ISP):

```bash
# /etc/postfix/main.cf
relayhost = [smtp.example.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
```

```bash
# /etc/postfix/sasl_passwd
# Format: destination  username:password
[smtp.example.com]:587    myuser@example.com:MySecretPass
```

```bash
# Build the hash database
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```

---

# 6. TLS/SSL

## 6.1 Server (Inbound) TLS

```bash
# /etc/postfix/main.cf
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem
smtpd_tls_key_file  = /etc/letsencrypt/live/mail.example.com/privkey.pem
smtpd_tls_security_level = may   # opportunistic: STARTTLS offered
# smtpd_tls_security_level = encrypt   # forced TLS (clients MUST use STARTTLS)

smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_eecdh_grade = strong
```

## 6.2 Client (Outbound) TLS

```bash
# /etc/postfix/main.cf
smtp_tls_security_level = may           # opportunistic TLS when connecting to others
# smtp_tls_security_level = encrypt     # force TLS for all outbound
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
```

## 6.3 Let's Encrypt Automation

```bash
# Install certbot
sudo apt install certbot

# Obtain certificate
sudo certbot certonly --standalone -d mail.example.com

# Symlink for easy paths (Postfix runs as postfix user, needs access)
sudo chmod 755 /etc/letsencrypt/{live,archive}
```

Add a renewal hook to restart Postfix:

```bash
# /etc/letsencrypt/renewal-hooks/postfix/systemctl-reload-postfix.sh
#!/bin/bash
systemctl reload postfix
```

```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/postfix/systemctl-reload-postfix.sh
```

---

# 7. Virtual Domains and Aliases

## 7.1 Email Aliases

System-wide aliases redirect mail for local Unix accounts:

```bash
# /etc/aliases
root:           admin@example.com
postmaster:     root
abuse:          root
webmaster:      alice@example.com
```

After editing:

```bash
sudo newaliases      # rebuilds /etc/aliases.db
```

The lookup table is used by the `local` delivery agent.

## 7.2 Virtual Alias Domains

Virtual aliases let you host multiple domains where **all** mail is forwarded elsewhere (no local mailboxes):

```bash
# /etc/postfix/main.cf
virtual_alias_domains = example.org, example.net, example.info
virtual_alias_maps    = hash:/etc/postfix/virtual
```

```bash
# /etc/postfix/virtual
# Forward mail for entire domains
@example.org          alice@example.com
@example.net          bob@example.com

# Per-user forwarding
info@example.info     help@example.com
sales@example.org     alice@example.com
```

```bash
sudo postmap /etc/postfix/virtual
sudo systemctl reload postfix
```

When both `virtual_alias_maps` and `mydestination` match a domain, virtual aliases take precedence.

---

# 8. Virtual Mailbox Domains

## 8.1 Concept

Virtual mailboxes store mail **on disk** without requiring a Unix user account per recipient. This is how hosting providers give everyone their own mailbox under the same domain.

## 8.2 Configuration

```bash
# /etc/postfix/main.cf
virtual_mailbox_domains = example.com, alt-domain.com
virtual_mailbox_maps    = hash:/etc/postfix/vmailbox
virtual_transport       = virtual
virtual_uid_maps        = static:5000
virtual_gid_maps        = static:5000
```

Create a dedicated system user for ownership:

```bash
sudo useradd -r -u 5000 -m -d /var/mail/vhosts -s /usr/sbin/nologin vmail
```

```bash
# /etc/postfix/vmailbox
# Format: user@domain    path/relative/to/home/directory
alice@example.com     example.com/alice/
bob@example.com       example.com/bob/
```

```bash
sudo postmap /etc/postfix/vmailbox
sudo systemctl reload postfix
```

## 8.3 Maildir vs mbox

| Feature | mbox | Maildir |
|---------|------|---------|
| Storage | One file, all messages | One file per message |
| Locking | Required (`fcntl`, `dotlock`) | No locking needed |
| Concurrency | Single-access only | Multiple readers/writers safe |
| Performance | Degrades with size | O(1) per message |
| Corruption | One corrupted message destroys all | Only one message affected |

**Always use Maildir** for virtual mailboxes:

```bash
# /etc/dovecot/conf.d/10-mail.conf
mail_location = maildir:/var/mail/vhosts/%d/%n
```

---

# ⭐ Level 3: Advanced — Content Filtering, Access Control, and Troubleshooting

# 9. Content Filtering

## 9.1 Before-Queue vs After-Queue

| Strategy | Filter runs | Impact |
|----------|-------------|--------|
| Before-queue | During SMTP conversation | Reject at connection time (e.g. Postscreen) |
| After-queue | After message is queued | Accept then scan; bounce if spam |

## 9.2 After-Queue Filtering with Amavis

```bash
# /etc/postfix/main.cf
content_filter = smtp-amavis:[127.0.0.1]:10024
```

```bash
# /etc/postfix/master.cf
# Add at the end:
smtp-amavis unix -    -       y       -       2       smtp
  -o smtp_data_done_timeout=1200
  -o smtp_send_xforward_command=yes
  -o disable_dns_lookups=yes

127.0.0.1:10025 inet n    -       y       -       -       smtpd
  -o content_filter=
  -o local_recipient_maps=
  -o relay_recipient_maps=
  -o smtpd_restriction_classes=
  -o smtpd_client_restrictions=
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks=127.0.0.0/8
  -o strict_rfc821_envelopes=yes
```

Install Amavis, SpamAssassin, ClamAV:

```bash
sudo apt install amavisd-new spamassassin clamav-daemon
sudo systemctl enable --now amavisd
```

## 9.3 Postscreen (Before-Queue, Built-in)

```bash
# /etc/postfix/main.cf
postscreen_access_list = permit_mynetworks
postscreen_dnsbl_sites = zen.spamhaus.org, bl.mailspike.net
postscreen_greet_action = drop
postscreen_blacklist_action = drop
```

Postscreen checks clients **before** they speak SMTP — reduces load by 80% on busy servers.

---

# 10. Rate Limiting and Access Control

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

## 10.2 Access Table

```bash
# /etc/postfix/access
# Format: pattern  action
spammer@example.org    REJECT
example.com            OK
192.168.1.             OK
```

```bash
sudo postmap /etc/postfix/access
sudo systemctl reload postfix
```

## 10.3 Anvil Rate Limiting (Built-in)

```bash
# /etc/postfix/main.cf
# Max concurrent connections from one IP
smtpd_client_connection_count_limit = 10

# Max connections per 60s from one IP
smtpd_client_connection_rate_limit = 30

# Max error rate before dropping
smtpd_client_error_rate_limit = 5

# Max recipients per SMTP session
smtpd_recipient_limit = 100
```

## 10.4 Policy Daemon (postfwd / postgrey)

```bash
# Example with postgrey (greylisting)
smtpd_recipient_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unauth_destination,
  check_policy_service inet:127.0.0.1:10023,
  permit
```

```bash
sudo apt install postgrey
```

---

# 11. Queue Management

## 11.1 Viewing the Queue

```bash
# Show queue
mailq
# Alternative
postqueue -p

# Count messages per queue
mailq | tail -n +2 | grep -c '^'

# Show deferred queue only
mailq | grep -A 1 '^[0-9A-F]'
```

## 11.2 Flushing the Queue

```bash
# Attempt immediate delivery of all queued mail
postqueue -f

# Flush only one destination
postqueue -s example.com
```

## 11.3 Postsuper (Queue Surgery)

```bash
# Delete a message
postsuper -d ABCDEF1234

# Delete ALL messages in deferred
postsuper -d ALL deferred

# Re-queue a message (schedule for immediate delivery)
postsuper -r ABCDEF1234

# Re-queue ALL deferred
postsuper -r ALL deferred

# Hold a message
postsuper -h ABCDEF1234

# Release a held message
postsuper -H ABCDEF1234
```

## 11.4 Queue Lifecycle Monitoring

```bash
# Count by queue
for q in incoming active deferred hold maildrop; do
  count=$(sudo find /var/spool/postfix/$q -type f 2>/dev/null | wc -l)
  echo "$q: $count"
done
```

---

# 12. Logging

## 12.1 Log Locations

```bash
# Primary log
/var/log/mail.log

# Errors only
/var/log/mail.err

# Follow in real time
sudo tail -f /var/log/mail.log
```

## 12.2 Interpreting Log Entries

```
Jun 24 10:00:00 mail postfix/smtpd[12345]: ABCDEF1234: client=unknown[10.0.0.1]
Jun 24 10:00:01 mail postfix/cleanup[12346]: ABCDEF1234: message-id=<20260624.1000@example.com>
Jun 24 10:00:01 mail postfix/qmgr[12347]: ABCDEF1234: from=<sender@example.com>, size=2500, nrcpt=1
Jun 24 10:00:02 mail postfix/smtp[12348]: ABCDEF1234: to=<recipient@example.org>, relay=mx.example.org[203.0.113.5]:25, delay=0.5, status=sent (250 OK)
```

Fields: `timestamp host process[pid]: queueid: event details`

## 12.3 Log Summaries with pflogsumm

```bash
sudo apt install pflogsumm

# Daily summary
sudo pflogsumm -d today /var/log/mail.log

# Full report
sudo pflogsumm /var/log/mail.log | less

# Email the summary
sudo pflogsumm -d yesterday /var/log/mail.log | \
  mail -s "Postfix Stats $(date +%F)" admin@example.com
```

---

# 13. Troubleshooting

## 13.1 Configuration Verification

```bash
# Check for syntax errors
postfix check

# Show effective non-default config
postconf -n
```

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

## 13.3 Enable Auth Logging (Careful!)

```bash
# /etc/postfix/main.cf — DO NOT leave on in production (logs passwords!)
smtpd_sasl_authenticated_header = yes
```

This shows the SASL username in `Received:` headers and logs.

## 13.4 Common Problems

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Connection refused port 25 | `inet_interfaces` wrong | `postconf inet_interfaces` |
| Relay access denied | SASL not set up or not permitted | Check `smtpd_relay_restrictions` |
| Connection timeout | Firewall, DNS, or relayhost down | `telnet relayhost 25` |
| "Helo command rejected: need fully-qualified hostname" | Hostname not FQDN | Fix `myhostname` |
| Queue not draining | DNS resolution failures | `postfix flush` + check `/var/log/mail.log` |
| Certificate warnings | Let's Encrypt expired / permissions | `certbot renew` + check file perms |

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

## 14.1 Installing Dovecot

```bash
sudo apt install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd
```

## 14.2 Basic Dovecot Configuration

```bash
# /etc/dovecot/dovecot.conf
!include_try /usr/share/dovecot/protocols.d/*.protocol
listen = *
```

```bash
# /etc/dovecot/conf.d/10-auth.conf
disable_plaintext_auth = yes
auth_username_format = %Ln
auth_mechanisms = plain login
```

```bash
# /etc/dovecot/conf.d/10-mail.conf
mail_location = maildir:/var/mail/vhosts/%d/%n
mail_privileged_group = mail
```

```bash
# /etc/dovecot/conf.d/10-master.conf
service imap-login {
  inet_listener imap {
    port = 0            # disable plain IMAP, force TLS
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    user = postfix
    group = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

```bash
# /etc/dovecot/conf.d/10-ssl.conf
ssl = required
ssl_cert = </etc/letsencrypt/live/mail.example.com/fullchain.pem
ssl_key  = </etc/letsencrypt/live/mail.example.com/privkey.pem
```

## 14.3 Postfix → Dovecot LMTP Delivery

Instead of the `virtual` delivery agent, tell Postfix to deliver via LMTP to Dovecot:

```bash
# /etc/postfix/main.cf
virtual_transport = lmtp:unix:private/dovecot-lmtp
```

This means Dovecot handles **both** authentication (SASL) and delivery (MDA) — the cleanest architecture.

## 14.4 Dovecot SASL for Postfix

```bash
# /etc/dovecot/conf.d/10-master.conf (already shown above for auth socket)

# /etc/postfix/main.cf
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
```

---

# 15. Hands-On Practices

## ⭐ Level 1: Basic Practices

### Practice 1: Install Postfix as a Satellite

**Goal**: Install Postfix configured to relay all mail through a smarthost.

```bash
sudo apt install postfix
# At the prompt, choose "Satellite system"
# Set smarthost: [smtp.example.com]:587
```

Or reconfigure:

```bash
sudo dpkg-reconfigure postfix

# Verify
postconf -n | grep relayhost
```

---

## ⭐ Level 2: Intermediary Practices

### Practice 2: Configure a Smarthost Relay with SASL Auth

**Goal**: Relay all outbound mail through an authenticated SMTP relay.

```bash
# /etc/postfix/main.cf
relayhost = [email-smtp.us-east-1.amazonaws.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
```

```bash
# /etc/postfix/sasl_passwd
[email-smtp.us-east-1.amazonaws.com]:587 AKIAXXXXXXX:BBBBB
```

```bash
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd*
sudo systemctl reload postfix
```

Test:

```bash
echo "Test from satellite" | mail -s "Test" admin@example.com
tail -f /var/log/mail.log
```

---

### Practice 3: Set Up Virtual Aliases

**Goal**: Host `example.org` and `example.info` on your server, forwarding all mail to your main inbox.

```bash
# /etc/postfix/main.cf
virtual_alias_domains = example.org, example.info
virtual_alias_maps = hash:/etc/postfix/virtual
```

```bash
# /etc/postfix/virtual
@example.org       admin@example.com
@example.info      admin@example.com
info@example.info  help@example.com
```

```bash
sudo postmap /etc/postfix/virtual
sudo systemctl reload postfix
```

Test by sending to `anyone@example.org` and checking `admin@example.com`'s mailbox.

---

### Practice 4: Install Dovecot for IMAP

**Goal**: Install Dovecot, serve mailboxes over IMAPS (port 993).

```bash
sudo apt install dovecot-core dovecot-imapd dovecot-lmtpd
```

Configure as shown in Section 14. Then:

```bash
sudo systemctl enable --now dovecot
sudo netstat -tlnp | grep 993
```

Test with Thunderbird or `openssl s_client`:

```bash
openssl s_client -connect localhost:993 -crlf
```

---

### Practice 5: Enable TLS with Let's Encrypt

**Goal**: Obtain and configure Let's Encrypt certificate for Postfix and Dovecot.

```bash
# Stop services that bind port 80 if needed
sudo systemctl stop nginx

# Obtain cert
sudo certbot certonly --standalone -d mail.example.com

# Set permissions
sudo chmod 755 /etc/letsencrypt/{live,archive}

# Configure Postfix and Dovecot to use these certs (Sections 6, 14)

# Add renewal hook
sudo mkdir -p /etc/letsencrypt/renewal-hooks/postfix
echo -e '#!/bin/bash\nsystemctl reload postfix dovecot' | \
  sudo tee /etc/letsencrypt/renewal-hooks/postfix/reload.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/postfix/reload.sh
```

---

### Practice 6: SASL Auth for Relaying

**Goal**: Allow authenticated users to relay mail through your server.

Ensure Dovecot SASL is configured (Section 14.4). Test with `swaks`:

```bash
sudo apt install swaks

swaks --to recipient@example.com \
      --server mail.example.com \
      --auth LOGIN \
      --auth-user alice@example.com \
      --auth-password secret
```

Check `/var/log/mail.log` for successful auth and delivery.

---

### Practice 7: Queue Management Commands

**Goal**: Practice every queue management command.

```bash
# Fill the queue by disconnecting from the internet, then sending mail
sudo systemctl stop postfix    # ensure nothing is delivering
echo "test1" | mail -s "test1" user@remote.org
echo "test2" | mail -s "test2" user@remote.org

# View queue
mailq
postqueue -p

# Delete all
sudo postsuper -d ALL

# Fill again, then re-queue
sudo postsuper -r ALL deferred
```

---

### Practice 8: Analyze Mail Logs

**Goal**: Extract meaningful statistics from your mail logs.

```bash
# Install pflogsumm
sudo apt install pflogsumm

# Generate report
sudo pflogsumm -d today /var/log/mail.log

# Custom analysis
grep "status=sent" /var/log/mail.log | wc -l
grep "status=bounced" /var/log/mail.log | wc -l
grep "status=deferred" /var/log/mail.log | wc -l
```

---

### Practice 9: Virtual Mailbox Domains

**Goal**: Set up `vmail` user and host virtual mailboxes.

```bash
sudo useradd -r -u 5000 -m -d /var/mail/vhosts -s /usr/sbin/nologin vmail
sudo mkdir -p /var/mail/vhosts/example.com
sudo chown -R vmail:vmail /var/mail/vhosts
```

Configure as in Section 8. Send test mail and verify mailbox files appear under `/var/mail/vhosts/`.

---

### Practice 10: SMTP Protocol Debugging

**Goal**: Manually send an email via telnet and observe every response.

```bash
telnet localhost 25
```

Walk through the state machine:

```
HELO myclient
MAIL FROM:<test@example.com>
RCPT TO:<alice@example.com>
DATA
Subject: Manual SMTP

Body content here.
.
QUIT
```

---

## ⭐ Level 3: Advanced Practices

### Practice 11: Content Filtering with SpamAssassin

**Goal**: Filter incoming mail through SpamAssassin.

```bash
sudo apt install spamassassin
sudo systemctl enable --now spamassassin
```

Add to Postfix master.cf a content filter pipe through SpamAssassin, or use Amavis for the full suite:

```bash
sudo apt install amavisd-new
# Amavis integrates SpamAssassin and ClamAV automatically
```

---

### Practice 12: Rate Limit Outbound Mail

**Goal**: Protect your server from being used as a spam relay by rate-limiting.

```bash
# /etc/postfix/main.cf
smtpd_client_connection_count_limit = 5
smtpd_client_connection_rate_limit = 10
smtpd_recipient_limit = 50
```

Test by connecting multiple times from one IP and observing rejections.

---

### Practice 13: Greylisting

**Goal**: Install and configure postgrey to greylist unknown senders.

```bash
sudo apt install postgrey
sudo systemctl enable --now postgrey

# /etc/postfix/main.cf
smtpd_recipient_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unauth_destination,
  check_policy_service inet:127.0.0.1:10023,
  permit
```

Test: First send from a new sender — message is deferred with "greylisted" in the log. Second send (after 5+ minutes) is accepted.

---

### Practice 14: DKIM Signing

**Goal**: Sign outgoing mail with OpenDKIM.

```bash
sudo apt install opendkim opendkim-tools
```

```bash
# /etc/opendkim.conf
Domain                  example.com
KeyFile                 /etc/opendkim/keys/example.com/mail.private
Selector                mail
Socket                  inet:8891@localhost
```

```bash
# /etc/postfix/main.cf
milter_default_action = accept
milter_protocol = 6
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
```

Test: send mail and verify `DKIM-Signature:` header appears.

---

### Practice 15: Real-World Integration — Full Mail Server

**Goal**: Build a complete mail server with Postfix + Dovecot + TLS + Virtual Mailboxes + SpamAssassin.

### Step-by-Step

```bash
# 1. Install packages
sudo apt update
sudo apt install postfix dovecot-core dovecot-imapd dovecot-pop3d \
  dovecot-lmtpd amavisd-new spamassassin clamav-daemon opendkim

# 2. Create virtual mail user
sudo useradd -r -u 5000 -m -d /var/mail/vhosts -s /usr/sbin/nologin vmail

# 3. Configure Postfix (main.cf)
#  myhostname = mail.example.com
#  mydomain = example.com
#  myorigin = $mydomain
#  inet_interfaces = all
#  mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
#  mynetworks = 127.0.0.0/8
#  virtual_mailbox_domains = example.com
#  virtual_mailbox_maps = hash:/etc/postfix/vmailbox
#  virtual_transport = lmtp:unix:private/dovecot-lmtp
#  virtual_uid_maps = static:5000
#  virtual_gid_maps = static:5000
#  smtpd_sasl_type = dovecot
#  smtpd_sasl_path = private/auth
#  smtpd_sasl_auth_enable = yes
#  smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem
#  smtpd_tls_key_file = /etc/letsencrypt/live/mail.example.com/privkey.pem
#  smtpd_tls_security_level = may
#  smtp_tls_security_level = may
#  content_filter = smtp-amavis:[127.0.0.1]:10024

# 4. Configure Dovecot (as in Section 14)

# 5. Configure virtual mailbox map
echo 'alice@example.com  example.com/alice/' | sudo tee -a /etc/postfix/vmailbox
echo 'bob@example.com    example.com/bob/' | sudo tee -a /etc/postfix/vmailbox
sudo postmap /etc/postfix/vmailbox

# 6. Create mailbox directories
sudo mkdir -p /var/mail/vhosts/example.com/{alice,bob}
sudo chown -R vmail:vmail /var/mail/vhosts

# 7. Enable and start everything
sudo systemctl enable --now postfix dovecot amavisd clamav-daemon opendkim

# 8. Test
echo "Welcome to your new mailbox" | mail -s "Hello" alice@example.com
sudo tail -f /var/log/mail.log
```

This is a production-ready setup for a small domain.

---

# Deep Understanding

## Postfix's Process Model: Prefork vs Pipelining

Postfix uses a **prefork** model: the `master` daemon starts a configurable number of child processes for each service:

```bash
# /etc/postfix/master.cf
smtp      inet  n  -  y  -  -     smtpd
#                       ^  ^
#                       |  maxproc (blank = default 100)
#                       reserved (always - for smtpd)
```

Key points:
- Children are created at startup and reused for many connections
- Unlike Apache's prefork (one process per connection), Postfix's children handle **one connection at a time** but are reused
- `default_process_limit` (100) governs children per service
- `smtpd_client_connection_count_limit` governs per-IP limits

Postfix also supports **pipelining** at the SMTP level (RFC 2920): clients can send multiple commands without waiting for responses. Enable with:

```bash
smtp_pix_workarounds = *
```

## How QMQP Works

Quick Mail Queue Protocol — a proprietary Postfix protocol for **queue sharing** across multiple machines:

```
Server A (smtpd) ──QMQP──▶ Server B (qmgr)
```

Used in multi-tier setups where front-end MTAs accept mail and a back-end QMGR handles delivery. Configure with:

```bash
# /etc/postfix/master.cf
qmgr      unix  n  -  n  -  1  qmgr
# QMQP on the front-end:
qmqpd     unix  n  -  n  -  1  qmqpd
```

QMQP is rarely used today because modern load balancers handle SMTP traffic directly.

## How the Queue Manager Sorts by Destination

The `qmgr` groups messages by destination **domain** (not by recipient). For each destination:

1. Look up transport maps → determine delivery agent (`smtp`, `relay`, `lmtp`, etc.)
2. Check `nexthop` → the actual target host/port
3. Build an **ordered transport pool** — one pool per (transport, nexthop) combo
4. Process messages concurrently, respecting `transport_destination_concurrency_limit` (default 20)

This prevents one slow destination from blocking others. If `mx.example.com` is slow, only that pool is delayed.

## How Cleanup Canonicalises Addresses

The `cleanup` daemon applies these transformations **before** queuing:

1. Adds `Received:` header with client info, protocol, timestamp
2. Applies canonical mappings (`canonical_maps`) — rewrite local parts
3. Applies sender/recipient canonical maps
4. Applies `masquerade_domains` — strip subdomains from sender addresses
5. Inserts `Message-ID:` if missing
6. Converts 8-bit MIME to 7-bit if needed
7. Adds `From`, `To`, `Date`, `Subject` if missing (from envelope)

## SMTP Protocol State Machine

```
         ┌──────────────────────────────┐
         │      WAITING FOR CONNECTION   │
         │        220 greeting           │
         └──────────────┬───────────────┘
                        │
                   HELO / EHLO
                        │
         ┌──────────────▼───────────────┐
         │          GOT HELO             │
         │        250 greeting           │
         └──────────────┬───────────────┘
                        │
                   MAIL FROM
                        │
         ┌──────────────▼───────────────┐
         │       GOT MAIL FROM           │
         │        250 sender ok          │
         └──────────────┬───────────────┘
                        │
                   RCPT TO (one or more)
                        │
         ┌──────────────▼───────────────┐
         │       GOT RCPT TO(s)          │
         │        250 recipient ok       │
         └──────────────┬───────────────┘
                        │
                       DATA
                        │
         ┌──────────────▼───────────────┐
         │          GOT DATA             │
         │   354 start mail input        │
         └──────────────┬───────────────┘
                        │
                   Body + "."
                        │
         ┌──────────────▼───────────────┐
         │        MESSAGE ACCEPTED       │
         │      250 queued as <id>       │
         └──────────────┬───────────────┘
                        │
                 QUIT / RSET
                        │
         ┌──────────────▼───────────────┐
         │        221 Bye / start over   │
         └──────────────────────────────┘
```

Each state enforces specific checks (HELO hostname validity, sender domain, recipient access). The `smtpd` child process resets to the GOT HELO state after `RSET`.

## DKIM Signing Basics (OpenDKIM)

DKIM (DomainKeys Identified Mail) lets the server cryptographically sign outgoing mail so receiving MTAs can verify it wasn't forged.

### Setup

```bash
# 1. Generate keys
sudo mkdir -p /etc/opendkim/keys/example.com
sudo opendkim-genkey -D /etc/opendkim/keys/example.com/ -d example.com -s mail
```

This creates `mail.private` (private key) and `mail.txt` (DNS record).

### DNS Record

```bash
# From mail.txt
mail._domainkey.example.com IN TXT "v=DKIM1; h=sha256; k=rsa; p=MIGfMA0GCSqGSIb4...
```

### Postfix Integration

```bash
# /etc/postfix/main.cf
milter_default_action = accept
milter_protocol = 6
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
```

### Verification

Send a signed email and check headers:

```
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/simple; d=example.com;
  s=mail; t=1719230400; bh=...; h=From:To:Subject:Date;
  b=...
```

---

# Command Reference

## ⭐ Level 1: Basic Commands

| Command | Purpose |
|---------|---------|
| `postfix start` | Start Postfix |
| `postfix stop` | Stop Postfix |
| `postfix reload` | Reload configuration |
| `postconf -n` | Show non-default parameters |
| `postconf -d` | Show all default parameters |
| `postconf <param>` | Show value of a specific parameter |
| `mailq` | List messages in queue |

## ⭐ Level 2: Intermediary Commands

| Command | Purpose |
|---------|---------|
| `postmap <file>` | Build indexed database (.db) from flat file |
| `postalias <file>` | Build alias database |
| `newaliases` | Rebuild `/etc/aliases.db` |
| `postqueue -p` | List queue (same as mailq) |
| `postqueue -f` | Flush queue |
| `postqueue -s <domain>` | Flush mail for a specific domain |
| `postsuper -d <id>` | Delete message |
| `postsuper -d ALL <queue>` | Delete all messages in queue |
| `postsuper -r <id>` | Re-queue message (schedule retry) |
| `postsuper -r ALL` | Re-queue all deferred |
| `postsuper -h <id>` | Hold message |
| `postsuper -H <id>` | Release message |
| `postsuper -s` | Structure check (fixes queue directory symlinks) |
| `postlog -p <priority> <message>` | Write to syslog |

## ⭐ Level 3: Advanced Commands

| Command | Purpose |
|---------|---------|
| `postfix check` | Validate configuration |
| `postfix flush` | Force delivery attempt of all queued mail |

---

# What's Coming in Part 45

**Part 45: Proxy and Reverse Proxy** — We will cover the theory and implementation of forward proxies, reverse proxies, and load balancers using Nginx, HAProxy, and Squid. Topics include: proxy protocols (HTTP CONNECT, SOCKS5), caching reverse proxies, TLS termination, load-balancing algorithms (round-robin, least connections, IP hash), health checks, WebSocket proxying, gRPC proxying, and ACL configuration. We will also discuss proxy chaining and transparent proxying with iptables.

---

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

---

### Scoring

```
12–15 correct → 🟢 Ready for Part 45
 8–11 correct → 🟡 Review Sections 2, 4, 11, 13
  0–7 correct → 🔴 Re-read this part, do the hands-on practices
```

---

*Previous → Part 43: DHCP Server*
*Next → Part 45: Proxy and Reverse Proxy*

[← Previous](part43.md) | [Next →](part45.md)
