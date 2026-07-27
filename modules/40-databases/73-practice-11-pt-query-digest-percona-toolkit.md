## Practice 11: pt-query-digest (Percona Toolkit)

```bash
# Install Percona Toolkit
sudo apt install -y percona-toolkit

# Analyze MariaDB slow query log
sudo pt-query-digest /var/log/mysql/slow.log

# Analyze from live (capture 60 seconds)
sudo pt-query-digest --processlist h=localhost,u=root
```



---

[← Previous](72-practice-10-monitor-connections.md) | [↑ Index](index.md) | [Next →](74-practice-12-troubleshoot-a-stuck.md)
