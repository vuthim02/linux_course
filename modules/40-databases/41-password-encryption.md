## Password Encryption

PostgreSQL 10+ defaults to `scram-sha-256` (much stronger than `md5`):

```sql
-- Check password encryption
SHOW password_encryption;

-- Set encryption type
SET password_encryption = 'scram-sha-256';

-- Create user with specific encryption
CREATE ROLE appuser LOGIN PASSWORD 'mypass';
-- (uses current password_encryption setting)

-- Verify
SELECT rolname, rolpassword ~ 'SCRAM-SHA-256' AS is_scram
FROM pg_authid;
```

---

# 10. PostgreSQL Backup



---

[← Previous](40-pgidentconf-user-mapping.md) | [↑ Index](index.md) | [Next →](42-pgdump-single-database-backup.md)
