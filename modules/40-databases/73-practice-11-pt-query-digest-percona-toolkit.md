## Practice 11: pt-query-digest (Percona Toolkit)

```bash
# Install Percona Toolkit
sudo apt install -y percona-toolkit

# Analyze MariaDB slow query log
sudo pt-query-digest /var/log/mysql/slow.log

# Analyze from live (capture 60 seconds)
sudo pt-query-digest --processlist h=localhost,u=root
```

### Reading the Output

The output groups queries by **fingerprint** (parameterized) and ranks them by:

- **Total time** — most impactful queries first
- **Count** — how many times the query ran
- **Rows examined vs rows sent** — indicates scan efficiency
- **Lock time** — contention indicators

### Useful Variations

```bash
# Save report to file
sudo pt-query-digest /var/log/mysql/slow.log > /tmp/digest_report.txt

# Analyze only queries slower than 1 second
sudo pt-query-digest --filter '$event->{Query_time} > 1' /var/log/mysql/slow.log

# Analyze from general log (heavy but thorough)
sudo pt-query-digest /var/log/mysql/general.log

# Analyze binary log for write-heavy workloads
mysqlbinlog /var/lib/mysql/mysql-bin.000001 | pt-query-digest
```

### Key Takeaway
`pt-query-digest` is the single most useful tool for identifying which queries to optimize. Focus on the top 5 queries by total time — they'll account for 80%+ of your database load.


[← Previous](72-practice-10-monitor-connections.md) | [↑ Index](index.md) | [Next →](74-practice-12-troubleshoot-a-stuck.md)
