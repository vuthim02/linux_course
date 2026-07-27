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



---

[← Previous](29-91-before-queue-vs-after-queue.md) | [↑ Index](index.md) | [Next →](31-93-postscreen-before-queue-built-in.md)
