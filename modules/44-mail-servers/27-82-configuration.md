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



---

[← Previous](26-81-concept.md) | [↑ Index](index.md) | [Next →](28-83-maildir-vs-mbox.md)
