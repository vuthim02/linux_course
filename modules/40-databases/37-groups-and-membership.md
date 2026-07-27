## Groups and Membership

```sql
-- Create a group role (no LOGIN)
CREATE ROLE developers;

-- Grant privileges to the group
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO developers;

-- Add users to the group
GRANT developers TO alice;
GRANT developers TO bob;

-- Check members
\du+
```

---

# 9. PostgreSQL User Management — Deep Dive



---

[← Previous](36-role-user-operations.md) | [↑ Index](index.md) | [Next →](38-role-attributes.md)
