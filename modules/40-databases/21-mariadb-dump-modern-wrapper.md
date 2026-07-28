## mariadb-dump (Modern Wrapper)

MariaDB 10.5+ provides `mariadb-dump` as a drop-in replacement:

```bash
mariadb-dump --all-databases > backup.sql
mariadb-dump --help
```

### Key Features Over mysqldump

- **Parallel compression** support built-in (no need for `| gzip`)
- **Progress reporting** for large databases
- **`--dump-slave`** and **`--master-data`** for replication setups
- Better handling of views and triggers

```bash
# Compressed backup with progress
mariadb-dump --all-databases --routines --triggers | gzip > backup_$(date +%F).sql.gz

# Single database with schema only
mariadb-dump --no-data company > company_schema.sql

# Dump specific tables
mariadb-dump company users orders > company_tables.sql
```


# 6. MariaDB Performance


[← Previous](20-binary-log-backup-point-in-time-recovery.md) | [↑ Index](index.md) | [Next →](22-explain-query-execution-plan.md)
