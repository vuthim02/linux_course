## 🔄 Section 9: Live Kernel Patching and Snapshot Rollback

### Live Kernel Patching

Apply security patches to the kernel **without reboot**.

| Solution | Free Tier | Scope |
|----------|-----------|-------|
| **KernelCare** (replaced by TuxCare) | Paid | All distros |
| **Canonical Livepatch** | Free for up to 5 machines | Ubuntu |
| **Ksplice** (Oracle) | Paid | Oracle Linux |
| **kpatch** (Red Hat) | Included with RHEL | RHEL/CentOS |

```bash
# Ubuntu Livepatch
sudo snap install canonical-livepatch
sudo canonical-livepatch enable <token>

# Check status
sudo canonical-livepatch status --verbose
```

### Snapshot Rollback with snapper (Btrfs/ZFS)

```bash
# Install snapper
sudo apt install snapper
sudo dnf install snapper

# Create a pre/post snapshot pair before updates
sudo snapper -c root create -d "Before kernel update" --command "apt upgrade"

# List snapshots
sudo snapper -c root list

# Rollback to a previous snapshot
sudo snapper -c root undochange <snap1>..<snap2>
```

### Snapper Configurations

- **timeline**: automatic hourly/daily/weekly snapshots
- **number**: keep only N most recent snapshots
- **pre/post**: logical pairs around state-changing operations



[← Previous](12-section-8-rollback-strategies.md) | [↑ Index](index.md) | [Next →](22-rules-of-thumb.md)
