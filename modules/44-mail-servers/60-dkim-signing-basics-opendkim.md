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


# Command Reference




[← Previous](59-smtp-protocol-state-machine.md) | [↑ Index](index.md) | [Next →](61-level-1-basic-commands.md)
