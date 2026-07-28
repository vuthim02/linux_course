## Role (User) Operations

```sql
-- Create role (user)
CREATE ROLE appuser WITH LOGIN PASSWORD 'strong_password';

-- Create role with privileges
CREATE ROLE admin WITH LOGIN PASSWORD 'admin123' SUPERUSER;

-- List roles
\du

-- Alter role
ALTER ROLE appuser WITH PASSWORD 'new_password';
ALTER ROLE appuser WITH LOGIN;
ALTER ROLE appuser WITH NOLOGIN;        -- prevent login

-- Grant database access
GRANT ALL PRIVILEGES ON DATABASE company TO appuser;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO appuser;

-- Grant table privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO appuser;

-- Grant default privileges (for future tables)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;

-- Drop role
DROP ROLE appuser;

-- Show role attributes
\du+
```




[← Previous](35-table-operations.md) | [↑ Index](index.md) | [Next →](37-groups-and-membership.md)
