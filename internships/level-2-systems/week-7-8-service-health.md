# Internship — Level 2, Week 7-8
## Service Health Dashboard

### Real-World Scenario

You manage 10 Linux servers running critical services (nginx, postgresql, redis, sshd, cron, rsyslog, docker, prometheus, ntp, fail2ban). There is no centralized view of service health. You currently SSH into each one manually. Build a web-based dashboard.

### Requirements

Build a system that monitors service health across all servers and displays an HTML dashboard.

#### Part A: Health Check Script

Write `/usr/local/bin/service-health.sh` that:

1. Reads a list of servers and services from `/etc/service-health.conf`:
   ```ini
   [servers]
   web01,web02,web03
   db01,db02
   monitor01

   [services]
   sshd,nginx,postgresql,redis,cron,rsyslog,docker,prometheus,ntp,fail2ban
   ```

2. For each server (via SSH key auth):
   - Runs `systemctl is-active <service>` and `systemctl is-enabled <service>`
   - Collects output
   - Times out after 10 seconds per server (use `ssh -o ConnectTimeout=5`)

3. Outputs a JSON report:
   ```json
   {
     "timestamp": "2026-06-24T14:30:00Z",
     "servers": {
       "web01": {
         "nginx": {"active": true, "enabled": true},
         "sshd": {"active": true, "enabled": true},
         "postgresql": {"active": false, "enabled": true}
       }
     },
     "summary": {
       "total": 30,
       "running": 28,
       "stopped": 2,
       "failed": 0
     }
   }
   ```

#### Part B: Auto-Remediation

When a critical service (sshd, nginx, postgresql) is down:
- Attempt restart: `ssh server sudo systemctl restart <service>`
- Log the action: `/var/log/service-health.log`
- If restart fails twice, flag for human intervention

#### Part C: HTML Dashboard

Write/usr/local/bin/service-dashboard.sh that:

1. Reads the JSON report
2. Generates an HTML page at `/var/www/html/status.html`
3. Layout:
   ```
   ┌────────────────────────────────────────────┐
   │  System Health Dashboard                   │
   │  Last updated: 2026-06-24 14:30 UTC        │
   │  Green: 28  Red: 2  Gray: 0               │
   ├────────┬────────┬────────┬────────┬────────┤
   │ Server │ Status │ Uptime │ Load   │ Alerts │
   ├────────┼────────┼────────┼────────┼────────┤
   │ web01  │  🟢    │ 45d     │ 0.5    │ 0     │
   │ db01   │  🔴    │ 12d     │ 2.1    │ 1     │
   └────────┴────────┴────────┴────────┴────────┘
   ```
4. Serve via nginx (install and configure)

### Validation

```bash
# Test locally (check services on localhost)
./service-health.sh
cat /var/www/html/status.html
# Open in browser: http://localhost/status.html

# Auto-refresh (add meta refresh tag in HTML)
# Or run in cron:
* * * * * root /usr/local/bin/service-health.sh && /usr/local/bin/service-dashboard.sh
```

### Deliverables

- `~/internship/service-health.sh`
- `~/internship/service-dashboard.sh`
- `~/internship/service-health.conf`
- `~/internship/nginx-status-site.conf` — nginx site config
- `~/internship/sample-dashboard.html` — generated output from test run

### Hints

- `systemctl is-active nginx && echo "active" || echo "inactive"`
- `ssh -o BatchMode=yes -o ConnectTimeout=5 "$server" "systemctl is-active $service"`
- `jq` for JSON parsing (install it)
- `uptime | awk '{print $3}' | tr -d ','` for server uptime
- HTML can use inline CSS; no frameworks required
