# Linux System Administration — Internship Program

**Real-world assignments mapped to the 60-part course.**

- **Duration:** 6 months (4 levels, ~6 weeks each)
- **Goal:** From zero to production-ready infrastructure engineer
- **Deliverables:** Each level produces real artifacts for your portfolio

---

## Level 1 — Junior Linux Intern (Weeks 1-6)
*Course: Parts 1-10*

You are the newest member of the IT team. Your job: keep the office Linux workstations running, set up user accounts, and learn the fundamentals by doing real tasks.

### Week 1-2: User Onboarding & Access

**Task:** Create a new employee onboarding script for Linux workstations.

- Write a bash script that creates a user, sets up home directory, copies default dotfiles, sets SSH key, and sends a welcome email
- Must handle: duplicate usernames, weak passwords, missing home directory template
- Bonus: log every action to `/var/log/user-onboarding.log`

**Deliverable:** `~/internship/onboard.sh` + documentation

### Week 3-4: Backup Rotation System

**Task:** The office file server has no backup rotation. Build one.

- Write a script that tars `/home`, `/etc`, and `/var/log` daily
- Keep 7 daily, 4 weekly, 3 monthly backups
- Compress with gzip, verify integrity with `md5sum`
- Email a report on success/failure

**Deliverable:** `~/internship/backup-rotate.sh` + cron configuration

### Week 5-6: Disk Usage Alerting

**Task:** Users keep filling up `/home`. Build an early warning system.

- Script checks disk usage on all mounted partitions
- Warning at 80%, critical at 90%, email alert at 95%
- Find top 10 largest files/directories in `/home`
- Generate a weekly report emailed to the team

**Deliverable:** `~/internship/disk-alert.sh` + weekly cron job

---

## Level 2 — Systems Intern (Weeks 7-12)
*Course: Parts 11-25*

You now manage a small fleet of servers (web, database, monitoring). You handle services, logs, SSH, and basic security.

### Week 7-8: Service Health Dashboard

**Task:** Build a systemd service health monitor.

- Script checks status of 10 critical services (ssh, nginx, postgresql, cron, rsyslog, etc.)
- Reports: running, stopped, failed, enabled/disabled
- If a critical service is down, restart it and log the event
- Generate HTML report served via a simple nginx page

**Deliverable:** `~/internship/service-health.sh` + nginx config for status page

### Week 9-10: Centralized Log Server

**Task:** Set up a centralized rsyslog server for the fleet.

- Configure one server as `log-collector` (rsyslog listening on TCP 514)
- Configure all other servers to forward logs to it
- Set up log rotation (weekly, keep 4 weeks)
- Build a simple log search script using `grep` and `journalctl`
- Test by generating sshd logs from each server

**Deliverable:** `~/internship/log-server/` — configs, rotation rules, search script

### Week 11-12: SSH Hardening Audit

**Task:** Audit and harden SSH across all 10 servers.

- Write an audit script that checks sshd_config on each server
- Checks: PermitRootLogin, PasswordAuthentication, Protocol, Port, MaxAuthTries, ClientAliveInterval
- Score each server (pass/fail per check)
- Auto-remediate: backup config, apply hardening, restart sshd
- Report: which servers passed, which failed, what was changed

**Deliverable:** `~/internship/ssh-audit.sh` + hardening report

---

## Level 3 — Infrastructure Intern (Weeks 13-18)
*Course: Parts 26-40*

You now own the infrastructure. You build RAID arrays, manage LVM, write automation scripts, deploy containers.

### Week 13-14: Storage Provisioning Toolkit

**Task:** Build a script that automates disk provisioning for new servers.

- Detects available disks (exclude system disk)
- Interactive menu: create RAID 1 or RAID 10, add hot spare
- Create LVM on top: VG, LV (choose size), filesystem (ext4 or xfs)
- Mount to a specified path, add to /etc/fstab
- Report: disk layout before/after, mount status, RAID health

**Deliverable:** `~/internship/storage-provision.sh` + README

### Week 15-16: System Health Report Generator

**Task:** Management wants a daily health report for all servers.

- Collect: CPU (load avg, top 5 processes), memory (total/used/available, swap), disk (usage per mount, inode usage), network (listening ports, connections per state)
- Generate a formatted report (plain text and HTML)
- Highlight warnings (CPU > 80%, memory > 85%, disk > 80%)
- Email report to the team daily

**Deliverable:** `~/internship/health-report.sh` + HTML template + cron job

### Week 17-18: Dockerized Web App Deployment

**Task:** Deploy a LAMP stack application using Docker Compose.

- Write Dockerfile for a PHP/Flask app
- Write docker-compose.yml: app + nginx + mariadb + redis
- Configure persistent volumes for database
- Set up healthchecks for each service
- Write a deploy script that: pulls latest code, rebuilds, runs migrations, restarts
- Bonus: add Prometheus exporter sidecar

**Deliverable:** `~/internship/docker-deploy/` — Dockerfile, compose, deploy script

---

## Level 4 — DevOps Intern (Weeks 19-24)
*Course: Parts 41-60*

You now operate at the cloud/infrastructure level. You build pipelines, manage Kubernetes, and implement SRE practices.

### Week 19-20: Infrastructure as Code Project

**Task:** Provision a complete environment on AWS using Terraform.

- VPC with public/private subnets across 2 AZs
- EC2 instance (bastion host), RDS PostgreSQL, S3 bucket
- Security groups, IAM roles with least privilege
- Output: public IPs, connection strings, bucket names
- Use remote state (S3 + DynamoDB)
- Modularize: network, compute, database, storage modules

**Deliverable:** `~/internship/terraform/` — modules, state config, README

### Week 21-22: CI/CD Pipeline + Kubernetes Deployment

**Task:** Build a complete CI/CD pipeline that deploys to Kubernetes.

- GitHub Actions workflow: lint → test → build Docker image → scan → push to registry → deploy to staging K8s → integration test → promote to production
- Kubernetes manifests: Deployment, Service, Ingress, HPA, PDB
- Helm chart for the application
- Use kube-prometheus-stack for monitoring
- Set up Grafana dashboard for: requests/sec, latency p99, error rate, pod count

**Deliverable:** `~/internship/cicd/` — .github/workflows, Helm chart, K8s manifests

### Week 23-24: SLO Implementation + Chaos Engineering

**Task:** Implement SRE practices on the deployed application.

- Define SLIs: availability (200 rate), latency (p99 < 500ms), error rate (< 1%)
- Set SLO: 99.9% availability over 30 days
- Implement Prometheus recording rules for SLO compliance
- Set up multi-window multi-burn-rate alerts in Alertmanager
- Run chaos experiment: kill 2 out of 5 pods, measure SLO impact
- Write a blameless postmortem for the chaos experiment
- Build a Grafana dashboard showing: error budget remaining, burn rate, SLO compliance

**Deliverable:** `~/internship/sre/` — SLO definitions, alert rules, chaos experiment results, postmortem

---

## Evaluation Criteria

| Level | Must Complete | Portfolio Artifacts |
|-------|--------------|-------------------|
| 1 | 3 scripts working | `onboard.sh`, `backup-rotate.sh`, `disk-alert.sh` |
| 2 | Service monitor + log server + SSH audit | HTML dashboard, log configs, audit report |
| 3 | Storage toolkit + health reports + Docker deployment | Provisioning script, report generator, compose project |
| 4 | Terraform modules + CI/CD pipeline + SRE implementation | IaC repo, pipeline config, SLO dashboards |

Each level builds on the previous. An intern who completes all 4 levels has **production-ready skills equivalent to 1-2 years of professional experience**.
