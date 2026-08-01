## Section 8: KSM, PMEM/CXL, and cgroup v2 Memory

### KSM — Kernel Same-page Merging

Deduplicates anonymous memory pages across processes (used by KVM).

```bash
# Enable/configure
echo 1 > /sys/kernel/mm/ksm/run
echo 100 > /sys/kernel/mm/ksm/pages_to_scan
echo 2000 > /sys/kernel/mm/ksm/sleep_millisecs

# Monitor
cat /sys/kernel/mm/ksm/pages_shared
cat /sys/kernel/mm/ksm/pages_sharing
```

### PMEM / CXL — Persistent Memory Ecosystem

**PMEM (Persistent Memory)**: byte-addressable, non-volatile memory (Optane DC — discontinued 2021, ecosystem lives on in CXL).

**CXL (Compute Express Link)**: PCIe-based interconnect for memory pooling/disaggregation.

```bash
# ndctl — manage NVDIMMs
ndctl list -N                  # List namespaces
ndctl create-namespace -m fsdax  # Create FSDAX namespace
mkfs.ext4 /dev/pmem0           # Format as block device
mount -o dax /dev/pmem0 /mnt   # Mount with DAX (direct access)
```

### cgroup v2 Memory Controller

```bash
# Unified hierarchy since cgroup v2
# Memory limits
echo 512M > /sys/fs/cgroup/mygroup/memory.max

# Memory pressure notification
echo "1000000" > /sys/fs/cgroup/mygroup/memory.pressure_level

# Swap management
echo 0 > /sys/fs/cgroup/mygroup/memory.swap.max  # Disable swap for group

# OOM control
echo 1 > /sys/fs/cgroup/mygroup/memory.oom.group  # Kill entire group on OOM
```

| Feature | cgroup v1 | cgroup v2 |
|---------|-----------|-----------|
| Hierarchy | Multiple | Single unified |
| Memory+swap | Separate controllers | Unified (`memory.swap.*`) |
| PSI (Pressure Stall) | N/A | Built-in |
| BPF integration | Limited | Full |
| Default since | — | 2019 (systemd 243+) |
