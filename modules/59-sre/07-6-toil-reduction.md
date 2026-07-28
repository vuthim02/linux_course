## 6. Toil Reduction

Toil is **manual, repetitive, automatable, tactical work with no enduring value**. SREs must spend < 50% on toil.

### What Is Toil?

| Work | Toil? | Reason |
|---|---|---|
| Rebooting a server | Yes | Manual, repetitive |
| Responding to same alert daily | Yes | Should be auto-remediated |
| Writing deployment pipeline | No | Enduring value |
| Incident response | No | Necessary |

### Measuring Toil

```yaml
toil_tags:
  - manual_restart
  - manual_deploy
  - alert_noise
  - config_drift
  - permission_fix
  - data_patch
  - disk_fill_cleanup
```

```promql
sum(toil_hours_total[7d]) / sum(work_hours_total[7d])
```

### Toil Budget

- **50% cap** on toil
- Track weekly in 1:1s
- When toil exceeds 50%, the team **pauses project work** to automate

### Automation Strategies

| Level | Method | Example |
|---|---|---|
| 1. Script | One-off bash/Python | `./reboot-all.sh` |
| 2. Tool | Reusable CLI | `sre-tool cert renew --all` |
| 3. Platform | Self-service UI/API | Jenkins with one click |
| 4. Product | Fully automated | Auto-scaling, auto-healing |

### Example: Automating Cert Renewal

**Before (toil):**
```bash
ssh bastion.example.com
sudo certbot renew
scp fullchain.pem lb-01: && scp privkey.pem lb-01:
ssh lb-01 sudo service haproxy reload
```

**After (automated):**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cert-renewal
  namespace: cert-manager
spec:
  schedule: "0 3 1 * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: cert-manager
          containers:
            - name: cert-renew
              image: cert-manager-controller:v1.15.0
              args: ["renew", "--all-namespaces"]
          restartPolicy: OnFailure
```





[← Previous](06-5-four-golden-signals.md) | [↑ Index](index.md) | [Next →](08-7-incident-management.md)
