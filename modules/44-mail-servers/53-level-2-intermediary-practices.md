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



---

[← Previous](52-level-1-basic-practices.md) | [↑ Index](index.md) | [Next →](54-level-3-advanced-practices.md)
