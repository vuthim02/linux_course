## Practice 4: PostgreSQL Role and Database

```bash
# 1. Connect as postgres
sudo -u postgres psql << 'SQL'
CREATE ROLE invadmin WITH LOGIN PASSWORD 'securepass';
CREATE DATABASE inventory OWNER invadmin;
\c inventory
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    quantity INTEGER DEFAULT 0,
    price NUMERIC(10,2)
);
INSERT INTO items (name, quantity, price) VALUES
    ('Widget', 100, 9.99),
    ('Gadget', 50, 24.99);
GRANT ALL ON ALL TABLES IN SCHEMA public TO invadmin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO invadmin;
SQL

# 2. Connect as application user
psql -h localhost -U invadmin -d inventory -c "SELECT * FROM items;"
```




[← Previous](65-practice-3-mysqldump-backup-and.md) | [↑ Index](index.md) | [Next →](67-practice-5-pgdumppgrestore.md)
