## 🧠 Deep Understanding

### How Nagios Checks Services (Active Check)

```
1. Nagios scheduler determines it's time to check a service
2. Scheduler spawns a child process (fork)
3. Child process:
   a. Drops privileges to the nagios user
   b. Executes the check_command (e.g., check_ping -H 10.0.0.10 -w 100,20% -c 200,50%)
   c. Capture stdout (plugin output)
   d. Capture exit code (0, 1, 2, or 3)
4. Child process exits, parent (Nagios daemon) reads the result
5. Nagios updates the service status:
   a. Compares new state with previous state
   b. If state changed: log event, trigger notifications, run event handler
   c. Update status file for web UI
6. If check was a "hard" state (after max_check_attempts):
   a. Execute notification commands for contacts
   b. Execute event handler command (if configured)
7. Schedule next check based on check_interval

Key distinction — Hard vs Soft states:
  Soft state:  First 1..(max_check_attempts-1) failures
               Nagios rechecks more frequently (retry_interval)
               No notifications sent yet

  Hard state:  After max_check_attempts consecutive failures
               Nagios switches to normal check_interval
               Notifications ARE sent
               Event handlers run
```

### How Prometheus Pull Model Works

```
1. Prometheus server maintains a list of scrape targets
   (from static_configs, service discovery, file_sd, etc.)

2. For each target, at the configured scrape_interval:
   a. HTTP GET request to http://target:port/metrics
   b. Parse the text-based metrics format:

      # HELP node_cpu_seconds_total Seconds the cpus spent in each mode.
      # TYPE node_cpu_seconds_total counter
      node_cpu_seconds_total{cpu="0",mode="idle"} 12345.67

   c. For each metric line:
      - Parse metric name and labels
      - Parse value (float64)
      - Create a sample: {__name__="node_cpu_seconds_total", ...} @timestamp 12345.67

3. Samples are stored in the TSDB

4. Scrape health is recorded:
   - up{job="node", instance="10.0.0.10:9100"} = 1 (success)
   - scrape_duration_seconds = 0.045

Pull model advantages over push:
  - Easier to detect down targets (up == 0)
  - Single source of truth for scrape schedule
  - Targets don't need to know where Prometheus is
  - Simpler security (server needs access to targets, not vice versa)
  - Better for pull-based service discovery (Kubernetes)
```

### Time-Series Database (Prometheus TSDB) Concepts

```
Prometheus TSDB stores every metric as a time series, identified by:
  Metric name + Labels = unique time series

Example:
  node_cpu_seconds_total{cpu="0", mode="idle", instance="web-01", job="node"}
  ─────────────────────  ────────────────────────────────────────────────
      metric name                     labels (key=value pairs)

Each time series contains:
  ┌─────────────────────────────────────────────────────┐
  │  Time Series (series identifier)                     │
  │  ┌────────────┬────────────────────────────────┐    │
  │  │   Labels    │         Samples                │    │
  │  │            │  (timestamp, value) pairs       │    │
  │  │ cpu="0"    │  (t1, v1), (t2, v2), ...       │    │
  │  │ mode="idle"│                                 │    │
  │  │ instance=..│                                 │    │
  │  └────────────┴────────────────────────────────┘    │
  └─────────────────────────────────────────────────────┘

On-disk storage layout (Prometheus TSDB):

  /var/lib/prometheus/
  ├── wal/                    # Write-Ahead Log (recent data)
  │   ├── 000001              # WAL segment files
  │   ├── 000002
  │   └── ...
  ├── chunks_head/            # In-memory chunks being written
  └── 01ABCDEFGHIJ/           # Block directory (2-hour blocks)
      ├── meta.json           # Block metadata (min/max time, stats)
      ├── index               # Inverted index (label → series mapping)
      ├── chunks/             # Compressed sample data
      │   ├── 000001
      │   └── ...
      ├── tombstones          # Deleted series markers
      └── chunks_head/

Block lifecycle:
  1. Data accumulates in memory (2 hours worth)
  2. After 2 hours, the in-memory block is "compacted" to disk
  3. Smaller blocks are periodically merged into larger blocks
     (2h → 10h → 1d → ... up to retention time)
  4. Each compaction reduces size by:
     - Removing deleted series
     - Combining overlapping chunks
     - Applying compression (XOR for floats, delta-of-delta for timestamps)

Compression algorithm:
  Timestamps: delta-of-delta encoding (average 0.64 bytes per sample)
  Values:     XOR with previous value
  Result:     ~1.3 bytes per sample average

Retention:
  Default: 15 days
  Data is deleted by dropping entire blocks when they exceed retention time
```

### How Alertmanager Handles Grouping and Deduplication

```
1. Prometheus sends alerts to Alertmanager via HTTP API:
   POST http://alertmanager:9093/api/v2/alerts

   Alert payload:
   {
     "labels": {
       "alertname": "InstanceDown",
       "instance": "web-01",
       "severity": "critical"
     },
     "annotations": {
       "summary": "Instance web-01 is down"
     },
     "startsAt": "2026-06-24T14:30:00Z"
   }

2. Alertmanager pipeline:

   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
   │  Ingest  │───►│  Inhibit │───►│  Silence │───►│  Group   │───► Send
   │ (receive)│    │ (suppress)│   │ (mute)   │    │ (dedup)  │
   └──────────┘    └──────────┘    └──────────┘    └──────────┘

3. Inhibition:
   - Check all active inhibition rules
   - If SOURCE alert matches (e.g., severity=critical InstanceDown)
   - Suppress TARGET alerts (e.g., severity=warning on same instance)
   - Prevents cascading noise

4. Silencing:
   - Check if alert matches any active silence
   - Silences created manually (maintenance) or via API

5. Grouping:
   - Key defined by route.group_by (e.g., ["alertname"])
   - Alerts with same key collected into a group
   - One notification per group instead of per alert
   - Example: 10 down servers = 1 notification with 10 entries

6. Timer logic:
   group_wait:     30s    # Wait for more alerts before 1st notification
   group_interval: 5m     # Wait before sending updates to same group
   repeat_interval: 4h    # Re-send if nothing changed (reminder)

7. Deduplication:
   - If same alert arrives multiple times, only latest state matters
   - Alert identity = (labels + generatorURL)
   - Resolved alerts removed from active groups

8. Output:
   - For each group, execute the route's receiver
   - Template the message using alert data
```





[← Previous](17-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](19-command-reference.md)
