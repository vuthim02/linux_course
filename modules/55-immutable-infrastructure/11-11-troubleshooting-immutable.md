## 11. Troubleshooting Immutable

### Debugging Image Builds

```bash
# Debug mode — pauses after each step, allows SSH
packer build -debug template.pkr.hcl

# On failure, Packer keeps the instance running
# SSH into it to inspect:
ssh -i /path/to/packer-key ubuntu@<IP_ADDRESS>

# View build logs
packer build -machine-readable template.pkr.hcl | tee packer.log

# Check the build script output
cat /tmp/script_XXXX.sh  # Packer uploads scripts to /tmp
```

```hcl
# Add breakpoint provisioner to inspect during build
provisioner "breakpoint" {
  disable = false  # set to true in CI
  note = "Inspect the build instance at this stage"
}
```

### Common Build Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `timeout waiting for SSH` | Base AMI doesn't have SSH running | Check `ssh_username` and security group rules |
| `script exited with non-zero code` | Script error | Check script syntax, run with `-debug` |
| `no route to host` | Network ACL blocking SSH | Check subnet filter, VPC config |
| `AMI name already exists` | Duplicate AMI name | Add timestamp to AMI name |
| `disk full` | Too much data in image | Increase disk size in builder config |
| `invalid provisioning state` | Previous instance still running | Wait or clean up failed builds |
| `failed to validate template` | HCL syntax error | Run `packer fmt` and `packer validate` |

### Corrupted Images

```hcl
# Always build from a clean source — never reuse a corrupted base
source "amazon-ebs" "clean-build" {
  source_ami    = data.amazon-ami.ubuntu.id  # always fetch fresh
  # NOT source_ami = "ami-0badc0rrupted123"
}
```

```bash
# List failed/snapshots and clean up
aws ec2 describe-images --owners self --query 'Images[?State!=`available`].[ImageId,Name]'
aws ec2 deregister-image --image-id ami-12345678
aws ec2 delete-snapshot --snapshot-id snap-12345678
```

### Rollback

```bash
# Revert to previous image version
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name webapp-prod \
  --launch-template "LaunchTemplateName=webapp-v1,Version=\$Default"

aws autoscaling start-instance-refresh \
  --auto-scaling-group-name webapp-prod
```

```hcl
# Keep the last N image versions
locals {
  retention_count = 5
}

# Post-processor can output the AMI ID for tracking
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true
}
```

### Immutable + Stateful

Immutable infrastructure works seamlessly with stateless applications. For stateful workloads:

```
State (external to the instance):
  ├── Database → RDS, Aurora, DynamoDB
  ├── File storage → EFS, S3, EBS (with proper lifecycle)
  ├── Cache → ElastiCache (Redis/Memcached)
  ├── Session → DynamoDB, ElastiCache
  └── Logs → CloudWatch, ELK, Loki
```

```hcl
# In userdata: mount EFS at boot
#!/bin/bash
EFS_ID="fs-12345678"
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Mount EFS
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  ${EFS_ID}.efs.${REGION}.amazonaws.com:/ /mnt/efs

# Add to fstab for persistence
echo "${EFS_ID}.efs.${REGION}.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" \
  | sudo tee -a /etc/fstab
```

---



---

[← Previous](10-10-userdata-and-first-boot.md) | [↑ Index](index.md) | [Next →](12-12-hands-on-practices-115.md)
