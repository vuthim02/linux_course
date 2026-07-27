## 4. sed Admin Patterns

### 4.1 Config File Editing

```bash
# Uncomment a line
sed -i 's/^#\s*Port\s\+22/Port 22/' /etc/ssh/sshd_config

# Change a value
sed -i 's/^MAX_CONNECTIONS=.*/MAX_CONNECTIONS=500/' .env

# Add line after a match
sed -i '/^\[mysqld\]/a\bind-address = 0.0.0.0' /etc/mysql/my.cnf

# Add line before a match
sed -i '/^server {/i\    listen 443 ssl;' /etc/nginx/sites-available/default

# Remove a line
sed -i '/^# insecure/d' /etc/nginx/nginx.conf

# Ensure a line exists (idempotent)
grep -q '^Color=always' config.ini || sed -i '$a\Color=always' config.ini
```

### 4.2 Log Anonymization

```bash
# Anonymize IPs (replace last octet with .0)
sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/\1**0/g' access.log

# Anonymize email addresses
sed -E 's/([a-zA-Z0-9._%+-]+)@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/\1@redacted.com/g'

# Anonymize credit cards (show last 4)
sed -E 's/[0-9]{4}-[0-9]{4}-[0-9]{4}-([0-9]{4})/****-****-****-\1/g'

# Remove sensitive headers
sed -i '/^Authorization:/d' request.log
```

### 4.3 File Templating

```bash
# Template substitution
sed -e "s/{{HOSTNAME}}/$(hostname)/g" \
    -e "s/{{DATE}}/$(date)/g" \
    -e "s/{{IP}}/$(hostname -I | awk '{print $1}')/g" \
    template.conf > output.conf

# With environment variables
sed "s/{{DB_HOST}}/${DB_HOST:-localhost}/g" template.cfg

# Heredoc with sed
bash -c "$(sed 's/{{USER}}/'"$USER"'/g' script.template)"
```

### 4.4 In-Place Changes in Scripts

```bash
#!/bin/bash
# safe_sed.sh — safe in-place editing

SED_SCRIPT="/etc/nginx/nginx.conf"
BACKUP="${SED_SCRIPT}.bak.$(date +%Y%m%d%H%M%S)"

cp "$SED_SCRIPT" "$BACKUP"
sed -i 's/worker_connections\s\+[0-9]\+/worker_connections 2048/' "$SED_SCRIPT"

if nginx -t; then
    systemctl reload nginx
    echo "Config applied. Backup at $BACKUP"
else
    cp "$BACKUP" "$SED_SCRIPT"
    echo "Config invalid! Restored backup."
    exit 1
fi
```

### 4.5 sed One-Liners

```bash
# Strip HTML tags
sed -e 's/<[^>]*>//g' file.html

# Remove trailing whitespace
sed -i 's/[[:space:]]\+$//' file.txt

# Squeeze blank lines (keep at most one)
sed '/^$/{N;/^\n$/d}' file.txt

# Print every 2nd line
sed -n '1~2p' file.txt

# Line numbering (like cat -n)
sed = file.txt | sed 'N;s/\n/ /'

# Remove lines 2-5
sed '2,5d' file.txt

# Add a blank line after each line
sed G file.txt

# Extract text between markers (non-greedy)
sed -n '/START/{:a;n;/END/{p;d};H;ba};${g;p}' file.txt
```

---



---

[← Previous](07-3-sed-stream-editor.md) | [↑ Index](index.md) | [Next →](09-5-awk-text-processing-language.md)
