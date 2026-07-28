## The mysql CLI

```bash
# Connect to local socket
mysql -u root -p

# Connect to remote host
mysql -h 192.168.1.100 -P 3306 -u admin -p

# Execute a single command
mysql -u root -p -e "SHOW DATABASES;"

# Source a SQL file
mysql -u root -p < /tmp/backup.sql
```

### Useful CLI Flags

| Flag | Purpose |
|------|---------|
| `-v` | Verbose — show each statement as it executes |
| `-vv` | Very verbose — includes each statement and its result |
| `-e "SQL"` | Execute one statement and exit |
| `--batch` | Tab-separated output (good for scripts) |
| `-A` / `--skip-column-names` | Suppress column headers |

### Example: Scripting with mysql

```bash
# Backup all databases (script-friendly output)
mysql -u root -p --batch -e "SHOW DATABASES;" | grep -v 'Database'

# Export CSV from a query
mysql -u root -p --batch -e "SELECT id, name, email FROM company.users;" | tr '\t' ',' > users.csv
```

### Key Takeaway
The `-e` flag is your best friend for automation. Combine it with `--batch` for clean, scriptable output.


[← Previous](08-test-the-installation.md) | [↑ Index](index.md) | [Next →](10-database-operations.md)
