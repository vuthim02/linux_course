# Internship — Level 2, Week 11-12
## SSH Hardening Audit

### Real-World Scenario

Security team ran a vulnerability scan and found that 6 out of 10 servers allow root SSH login with password authentication. This is a PCI compliance violation. Your job: audit all servers, report the findings, and harden them automatically.

### Requirements

Write `/usr/local/bin/ssh-audit.sh` that performs a complete SSH security audit across your server fleet.

#### Configuration

`/etc/ssh-audit.conf`:
```ini
SERVERS="web01,web02,web03,db01,db02,monitor01"
ALERT_EMAIL=security@company.com
AUTOREMEDIATE=true
BACKUP_DIR=/backups/ssh-audit
SCORE_PASS=80
```

#### Checks (each worth points, total 100)

| # | Check | Points | What to look for |
|---|-------|--------|-----------------|
| 1 | Root login disabled | 15 | `PermitRootLogin no` |
| 2 | Password auth disabled | 15 | `PasswordAuthentication no` |
| 3 | Key-only authentication | 10 | `PubkeyAuthentication yes`, `ChallengeResponseAuthentication no` |
| 4 | Protocol 2 only | 5 | `Protocol 2` |
| 5 | Max auth tries ≤ 3 | 10 | `MaxAuthTries 3` or less |
| 6 | Client alive interval ≤ 300 | 5 | `ClientAliveInterval 300` or less |
| 7 | Client alive count max ≤ 3 | 5 | `ClientAliveCountMax 3` or less |
| 8 | Permit empty passwords off | 10 | `PermitEmptyPasswords no` |
| 9 | Strong ciphers | 10 | Ciphers should include `chacha20-poly1305`, `aes256-gcm` |
| 10 | Strong MACs | 5 | MACs should include `hmac-sha2-512`, `umac-128-etm` |
| 11 | Login grace time ≤ 60 | 5 | `LoginGraceTime 60` or less |
| 12 | AllowUsers or AllowGroups set | 5 | At least one restriction is configured |

#### Audit Output

Generate a report file:

```
SSH Security Audit Report — 2026-06-24
========================================
Server: web01 (192.168.1.10)
  [PASS] PermitRootLogin no                     +15
  [FAIL] PasswordAuthentication yes             +0
  [PASS] PubkeyAuthentication yes               +10
  [FAIL] MaxAuthTries 6                         +0
  ...
  Score: 65/100 — FAIL (threshold: 80)

Server: db01 (192.168.1.20)
  [PASS] PermitRootLogin no                     +15
  ...
  Score: 90/100 — PASS

Summary:
  3/6 servers PASS
  3/6 servers FAIL
  Overall compliance: 50%
  Critical failures: RootLogin (2), PasswordAuth (3)
```

#### Auto-Remediation

If `AUTOREMEDIATE=true`:

1. Backup current sshd_config: `cp /etc/ssh/sshd_config $BACKUP_DIR/sshd_config.web01.2026-06-24`
2. Apply hardening using `sed`:
   ```bash
   sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
   sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
   ```
3. If ciphers are weak, set:
   ```
   Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
   ```
4. Test config: `sshd -t`
5. Reload: `systemctl reload sshd`
6. Log ALL changes: `/var/log/ssh-audit.log`

#### Validation

```bash
# Run against localhost first
sudo ./ssh-audit.sh --server localhost

# Run against a test server
sudo ./ssh-audit.sh --server test-server

# Run against all servers
sudo ./ssh-audit.sh --all

# Rollback from backup if needed
sudo cp /backups/ssh-audit/sshd_config.localhost.2026-06-24 /etc/ssh/sshd_config
sudo systemctl reload sshd
```

### Deliverables

- `~/internship/ssh-audit.sh`
- `~/internship/ssh-audit.conf`
- `~/internship/sample-audit-report.txt` — test run output
- `~/internship/hardening-summary.md` — one-page summary of what was changed and why

### Hints

- `sshd -T` dumps the effective configuration (respects all config files)
- `ssh -o BatchMode=yes $server "sshd -T | grep -i permitroot"`
- `grep -c` for counting passes
- Use `ssh -n` to avoid reading from stdin in loops
- `awk -F' ' '{print $2}'` to extract values from sshd -T output
- `/etc/ssh/sshd_config.d/*.conf` may override main config on newer systems
