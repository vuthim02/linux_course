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


# 13. Troubleshooting




[← Previous](41-122-interpreting-log-entries.md) | [↑ Index](index.md) | [Next →](43-131-configuration-verification.md)
