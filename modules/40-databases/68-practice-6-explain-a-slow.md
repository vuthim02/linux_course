## Practice 6: EXPLAIN a Slow Query

```bash
# 1. Create a large dataset
sudo -u postgres psql -d inventory << 'SQL'
INSERT INTO items (name, quantity, price)
SELECT 'Item_' || generate_series(1, 100000),
       floor(random() * 1000),
       round((random() * 100)::numeric, 2);
SQL

# 2. Enable timing
sudo -u postgres psql -d inventory -c "\timing"

# 3. Run a slow query (no index on quantity)
sudo -u postgres psql -d inventory -c "
EXPLAIN ANALYZE SELECT * FROM items WHERE quantity > 500 ORDER BY price;
"

# 4. Add an index
sudo -u postgres psql -d inventory -c "
CREATE INDEX idx_items_quantity ON items(quantity);
"

# 5. Run the query again — compare the plan
sudo -u postgres psql -d inventory -c "
EXPLAIN ANALYZE SELECT * FROM items WHERE quantity > 500 ORDER BY price;
"
```



---

[← Previous](67-practice-5-pgdumppgrestore.md) | [↑ Index](index.md) | [Next →](69-practice-7-tune-buffer-sizes.md)
