## 13. Deep Understanding

### How Packer Works Internally

1. **Init**: Packer reads the `.pkr.hcl` template, validates syntax, downloads required plugins
2. **Source creation**: The builder creates a source instance on the target platform (AWS EC2, GCE VM, Azure VM, Docker container, QEMU VM)
3. **SSH/WinRM connection**: Packer connects to the instance via SSH (Linux) or WinRM (Windows)
4. **Provisioning**: Packer executes each provisioner in order:
   - Uploads scripts/files to the instance
   - Executes shell commands or playbooks
   - Each provisioner runs in sequence
5. **Cleanup scripts**: Provisioners that remove SSH keys, logs, package cache, and zero free space
6. **Stop instance**: Packer stops the running instance (if the builder supports it — EBS-backed AMIs are stopped for a clean snapshot)
7. **Create image**: Packer creates the image artifact:
   - AWS: Creates an EBS snapshot of the root volume, registers it as an AMI
   - GCE: Creates a disk image from the instance disk
   - Azure: Captures a managed image
   - Docker: Commits the container
   - QEMU: Copies the qcow2 file
8. **Terminate source instance**: Packer terminates the source instance and cleans up temporary resources (security groups, key pairs, etc.)
9. **Post-processors**: If defined, post-processors transform the artifact (manifest JSON, vagrant box, docker push)
10. **Output**: Packer outputs the artifact ID(s) (AMI ID, image name, etc.)

```
Start ──► Create instance ──► Wait for SSH ──► Run provisioners
  │                                                │
  │                                            [breakpoint]
  │                                                │
  │                                         Run cleanup scripts
  │                                                │
  │                                         Stop instance
  │                                                │
  │                                         Create image/snapshot
  │                                                │
  │                                         Terminate instance
  │                                                │
  └────────────► Image ready (AMI, GCE image, etc.)
```

### How AWS EBS Snapshots Work

When Packer creates an AMI (Amazon Machine Image):

1. **EBS Snapshot**: AWS takes a point-in-time, block-level snapshot of the EBS root volume attached to the build instance
2. **Incremental**: Snapshots are incremental — only changed blocks are saved
3. **Block-level**: Each block is typically 512 KiB to 64 MiB in size; only blocks that changed from the previous snapshot are stored
4. **Lazy copy**: The first snapshot of a volume copies all blocks; subsequent snapshots are incremental
5. **S3-backed**: EBS snapshots are stored in Amazon S3 (in a region-specific bucket you don't see)
6. **AMI registration**: Packer registers the snapshot as an AMI, which includes:
   - A reference to the snapshot
   - Block device mapping (which device is root, size, type)
   - Launch permissions (who can use this AMI)
   - Tags
7. **Copy to regions**: If `ami_regions` is specified, the snapshot is copied to those regions and registered there

### How Cloud-Init Runs

```
Power ON
   │
   ▼
BIOS/UEFI boot
   │
   ▼
Kernel starts → systemd → cloud-init.target
   │
   ├── cloud-init-local.service
   │   │  Detect datasource (NoCloud, EC2, GCE, Azure)
   │   │  Parse kernel cmdline for ds=nocloud-net
   │   │  Set up network config
   │   ▼
   ├── cloud-init.service
   │   │  Fetch user-data and meta-data from datasource
   │   │  Process cloud-config (YAML)
   │   │  Execute modules in order (from /etc/cloud/cloud.cfg):
   │   │    1. bootcmd — runs on every boot
   │   │    2. write_files — writes files to disk
   │   │    3. rsyslog — configure logging
   │   │    4. resolv_conf — configure DNS
   │   │    5. ntp — set up NTP
   │   │    6. users — create users and groups
   │   │    7. ssh_authorized_keys — deploy SSH keys
   │   │    8. packages — install packages
   │   │    9. runcmd — run arbitrary commands
   │   │   10. ssh — configure SSH keys
   │   ▼
   ├── cloud-config.service
   │   │  Run final configuration modules
   │   ▼
   └── cloud-final.service
       │  Execute scripts in /var/lib/cloud/scripts/per-boot/
       │  Execute scripts in /var/lib/cloud/scripts/per-instance/
       │  Execute scripts in /var/lib/cloud/scripts/per-once/
       ▼
   Boot complete — instance ready
```

**Datasource detection order:**
1. NoCloud (seed from ISO/CDROM filesystem labeled `cidata`)
2. ConfigDrive (OpenStack)
3. EC2 (169.254.169.254 metadata endpoint)
4. GCE (metadata.google.internal)
5. Azure (168.63.129.16 wireserver)
6. Hetzner, CloudSigma, other cloud platforms

### Pre-Baked Images vs Post-Boot Configuration

| Aspect | Pre-Baked (Immutable) | Post-Boot (Mutable) |
|--------|----------------------|-------------------|
| Boot time | Fast (seconds) | Slow (minutes — installs/configures) |
| Reproducibility | Guaranteed identical | Depends on network, repos, timing |
| Security patches | In image | At boot (may use outdated packages temporarily) |
| Complexity | More complex build pipeline | Simpler launch process |
| Rollback | Instant (re-deploy old image) | Slow (re-run config) |
| Debugging | Launch test instance | SSH into running instance |
| Image sprawl | Need to manage versions | One base image for everything |
| Config changes | Require image rebuild | Runtime userdata can change |
| Dependency on external services | Only during build | At every boot (repo servers, CM server) |

### Security Model of Immutable Deployment

No SSH access to production:
- Port 22 is closed in security groups
- No SSH keys deployed in the image
- No user accounts with login shells
- `PermitRootLogin no` and `PasswordAuthentication no`

**How to manage without SSH:**
- **Debugging**: Launch a separate instance from the same image in a sandbox VPC
- **Logs**: Centralized logging (CloudWatch, ELK, Loki) — never SSH to read logs
- **Metrics**: CloudWatch, Prometheus, Datadog — never SSH to check disk/memory
- **Configuration**: Userdata at boot, environment variables, config management
- **Shell access**: AWS SSM Session Manager (audited, no SSH key needed) for rare emergencies
- **Serial console**: AWS EC2 Serial Console for kernel-level debugging

**Security benefits:**
- No attack surface from SSH daemon
- No SSH key management (no lost keys, no rotated keys)
- No lateral movement — attacker can't SSH from one instance to another
- Every instance starts from a known good state — no persistent malware
- Immutable means no persistent compromise — terminate the instance, the malware is gone
- Audit trail — every change goes through the image pipeline

---



---

[← Previous](12-12-hands-on-practices-115.md) | [↑ Index](index.md) | [Next →](14-14-command-reference.md)
