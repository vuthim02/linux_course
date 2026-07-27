## 🔍 Section 4: Heredocs and Herestrings — Redirecting Multi-line Input

### Heredoc — Send Multiple Lines to stdin

```bash
# Syntax: command << DELIMITER
#         ...lines...
#         DELIMITER

cat << EOF
This is a multi-line
block of text
that goes to cat's stdin
EOF
```

### Real Heredoc Uses

```bash
# Create a file with multi-line content
cat > ~/deploy.sh << 'EOF'
#!/bin/bash
echo "Starting deployment..."
rsync -avz ./dist/ user@server:/var/www/
echo "Deployment complete."
EOF

# Send SQL query to database (without heredoc would be painful)
mysql -u root -p << SQL
CREATE DATABASE myapp;
USE myapp;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);
SQL

# Write a config file programmatically
sudo tee /etc/nginx/sites-available/myapp << EOF
server {
    listen 80;
    server_name example.com;
    root /var/www/myapp;
    index index.html;
}
EOF
```

### Quoted vs Unquoted Delimiter

```bash
# WITH quotes: variables are NOT expanded
cat << 'EOF'
$HOME is not expanded
$(date) stays as-is
EOF

# WITHOUT quotes: variables ARE expanded
cat << EOF
$HOME is expanded
$(date) shows current date
EOF
```

### Herestring — Single Line to stdin

```bash
# Syntax: command <<< "string"

# Count words in a string
wc -w <<< "Hello world from herestring"

# Search a string with grep
grep "error" <<< "Everything is fine, no error here"

# Pass string to a command that reads stdin
tr '[:lower:]' '[:upper:]' <<< "make this uppercase"
```

---



---

[← Previous](10-section-3-named-pipes-fifos.md) | [↑ Index](index.md) | [Next →](12-more-pipe-patterns.md)
