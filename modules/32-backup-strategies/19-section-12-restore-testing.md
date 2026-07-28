## 🔍 Section 12: Restore Testing

### Why You MUST Test Restores

Common failures found ONLY during restore testing:
- Corrupted archive (tar header error, truncated)
- Missing dependency (restore tool not on new machine)
- Permission mismatch (UIDs differ between machines)
- Encryption key lost or password forgotten
- Incomplete incremental chain
- Software version incompatibility

### Manual Restore Test

```bash
# 1. Create test environment
mkdir -p /tmp/restore-test/

# 2. Extract
cd /tmp/restore-test
tar xzf /backups/data-2025-01-12.tar.gz

# 3. Verify counts
echo "Expected: $(find /data/ -type f | wc -l)"
echo "Restored: $(find /tmp/restore-test/ -type f | wc -l)"

# 4. Spot-check critical files
diff /data/important.doc /tmp/restore-test/data/important.doc

# 5. Verify database restore
pg_restore -d test_restore /backups/mydatabase.dump
psql -d test_restore -c "SELECT count(*) FROM users;"
```

### Automated Restore Test

```bash
#!/bin/bash
# test-restore.sh
set -e
TEST_DIR="/tmp/restore-test-$$"
BACKUP_FILE="/backups/latest/data.tar.gz"
LOG="/var/log/restore-test-$(date +%F).log"

echo "=== Restore Test $(date) ===" > "$LOG"
mkdir -p "$TEST_DIR"

# Test 1: Extract
tar xzf "$BACKUP_FILE" -C "$TEST_DIR" 2>> "$LOG" \
    && echo "PASS: Extract" || echo "FAIL: Extract"

# Test 2: File count
S=$(find /data/ -type f | wc -l)
R=$(find "$TEST_DIR" -type f | wc -l)
[ "$S" -eq "$R" ] && echo "PASS: $S files" || echo "FAIL: $S vs $R"

# Test 3: Checksum critical files
for f in important.doc config.json; do
    [ "$(md5sum /data/$f | cut -d' ' -f1)" = \
      "$(md5sum $TEST_DIR/data/$f 2>/dev/null | cut -d' ' -f1)" ] \
      && echo "PASS: $f" || echo "FAIL: $f"
done

rm -rf "$TEST_DIR"
echo "=== Test Complete ===" >> "$LOG"
```

### Frequency

| Backup Type | Test Frequency |
|-------------|----------------|
| Daily incremental | Weekly spot check |
| Weekly full | Monthly full restore |
| Monthly archive | Quarterly |
| DR plan | Annually (bare-metal) |





[← Previous](18-section-11-offsite-and-remote.md) | [↑ Index](index.md) | [Next →](20-section-13-disaster-recovery-planning.md)
