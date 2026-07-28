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


# 7. Virtual Domains and Aliases




[← Previous](22-62-client-outbound-tls.md) | [↑ Index](index.md) | [Next →](24-71-email-aliases.md)
