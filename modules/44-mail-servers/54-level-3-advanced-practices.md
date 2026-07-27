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



---

[← Previous](53-level-2-intermediary-practices.md) | [↑ Index](index.md) | [Next →](55-postfixs-process-model-prefork-vs.md)
