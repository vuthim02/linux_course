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



---

[← Previous](27-82-configuration.md) | [↑ Index](index.md) | [Next →](29-91-before-queue-vs-after-queue.md)
