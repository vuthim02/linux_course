## ✅ Self-Test
Answer these 15 questions. **Score:** 12/15 correct = ready for Part 47.
### Question 1
Which Nagios plugin return code indicates a critical failure?
```
A) 0
B) 1
C) 2
D) 3
```
### Question 2
What is the primary difference between Nagios NRPE and Prometheus node_exporter?
```
A) NRPE uses push; node_exporter uses pull
B) NRPE uses pull; node_exporter uses push
C) NRPE is for databases; node_exporter is for web servers
D) They are identical in architecture
```
### Question 3
In Prometheus, which metric type is used for request latency percentiles?
```
A) Counter
B) Gauge
C) Histogram
D) Timer
```
### Question 4
What does the `rate()` function do in PromQL?
```
A) Calculates the instantaneous value of a gauge
B) Calculates the per-second average rate of increase of a counter
C) Calculates the total number of samples in a time range
D) Calculates the maximum value over a time range
```
### Question 5
Which Zabbix component reduces load on the central server for remote site monitoring?
```
A) Zabbix agent
B) Zabbix proxy
C) Zabbix frontend
D) Zabbix template
```
### Question 6
In Alertmanager, what is the purpose of `group_wait`?
```
A) How long to wait before sending the first notification for a new group
B) How long to wait before sending repeated notifications
C) How long to wait for a target to come back online
D) How long to wait before marking an alert as resolved
```
### Question 7
Which Grafana panel type is best for displaying a single metric value like "current disk usage"?
```
A) Time series
B) Table
C) Stat
D) Heatmap
```
### Question 8
What is the purpose of the Prometheus textfile collector?
```
A) To collect text files from remote servers
B) To expose custom metrics from scripts/cron jobs via node_exporter
C) To read configuration from text files
D) To store Prometheus configuration in a text file
```
### Question 9
In Zabbix, what is a "trigger"?
```
A) A command that runs on the agent
B) A condition that generates an event when met
C) A notification method
D) A type of media
```
### Question 10
What does the `up` metric represent in Prometheus?
```
A) System uptime in seconds
B) Whether the last scrape of a target was successful (1) or not (0)
C) The version of the Prometheus server
D) The number of CPU cores available
```
### Question 11
How does Loki differ from Elasticsearch in log storage?
```
A) Loki indexes only labels/metadata, not full-text content
B) Loki requires more disk space
C) Loki does not support queries
D) Loki cannot receive logs from agents
```
### Question 12
What is the purpose of `inhibit_rules` in Alertmanager?
```
A) To prevent certain receivers from triggering
B) To suppress less important alerts when critical ones fire
C) To block all alerts during maintenance
D) To prevent duplicate alerts from entering the pipeline
```
### Question 13
In Nagios, what distinguishes a "hard" state from a "soft" state?
```
A) Soft states send notifications; hard states do not
B) Hard states occur after max_check_attempts failures; notifications are sent
C) Hard states only occur for hosts, not services
D) Soft states are permanent; hard states are temporary
```
### Question 14
Which Prometheus exporter would you use to monitor whether an external website returns HTTP 200?
```
A) node_exporter
B) blackbox_exporter
C) mysqld_exporter
D) nginx_exporter
```
### Question 15
What is the default Prometheus data retention period?
```
A) 7 days
B) 15 days
C) 30 days
D) 90 days
```
**Score:** 12/15 correct = ready for Part 47.
**Answers:** 1-C, 2-A, 3-C, 4-B, 5-B, 6-A, 7-C, 8-B, 9-B, 10-B, 11-A, 12-B, 13-B, 14-B, 15-B
*Previous → Part 45: Proxy and Reverse Proxy — Squid, Nginx, HAProxy*
*Next → Part 47: Performance Tuning and Optimization*
[← Previous](20-whats-coming-in-part-47.md) | [↑ Index](index.md)
