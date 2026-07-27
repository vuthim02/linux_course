## 🔍 Section 2: CPU Tuning

### CPU Governors

Linux CPU frequency scaling allows the kernel to adjust clock speed and voltage.

```bash
# List available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

# Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set all CPUs to performance (maximum frequency, no scaling down)
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set to powersave (lowest frequency)
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# On some systems, use cpupower
sudo cpupower frequency-set -g performance
```

| Governor | Use Case |
|----------|----------|
| `performance` | Latency-sensitive workloads (databases, trading, real-time) |
| `powersave` | Battery-powered, idle-heavy systems |
| `ondemand` | Default on older kernels — ramp up on demand |
| `conservative` | Slower ramp-up than ondemand |
| `schedutil` | Modern default — frequency hints from scheduler |

### CPU Isolation — `isolcpus`

Isolate cores from the general scheduler so dedicated processes can run without interference:

Add to kernel command line in `/etc/default/grub`:

```
GRUB_CMDLINE_LINUX="isolcpus=2,3 nohz_full=2,3 rcu_nocbs=2,3"
```

Then rebuild:

```bash
sudo update-grub
sudo reboot
```

| Parameter | Effect |
|-----------|--------|
| `isolcpus=2,3` | Kernel scheduler will not schedule regular tasks on CPU 2-3 |
| `nohz_full=2,3` | Disable timer ticks on isolated CPUs (reduce overhead) |
| `rcu_nocbs=2,3` | Offload RCU callbacks from isolated CPUs |

After isolation, bind your workload:

```bash
# Bind a process to isolated CPUs
sudo taskset -c 2,3 ./my_latency_sensitive_app
```

### Process Affinity with `taskset`

Control which CPUs a process or thread can run on:

```bash
# Check affinity of a running process
taskset -p 1234

# Set affinity (bind to CPUs 0 and 2)
sudo taskset -pc 0,2 1234

# Launch a program on specific CPUs
taskset -c 0,1 ./myapp

# Mask format (hexadecimal bitmask)
taskset -p 0x3 1234   # CPUs 0 and 1
taskset -p 0xF 1234   # CPUs 0,1,2,3
```

### `irqbalance`

IRQ balancing spreads hardware interrupt handlers across CPUs:

```bash
# Check status
systemctl status irqbalance

# Stop irqbalance for manual IRQ affinity (advanced tuning)
sudo systemctl stop irqbalance

# Manual IRQ affinity — assign NIC IRQs to specific CPUs
# Find IRQ for your NIC
grep eth0 /proc/interrupts

# Set smp_affinity for that IRQ (CPU 0 only = 0x00000001)
echo 1 | sudo tee /proc/irq/48/smp_affinity
```

### CPU Pinning for VMs and Containers

**KVM/QEMU:**

```bash
# Pin vCPUs to physical CPUs in libvirt XML
virsh vcpupin vm_name 0 2   # vCPU 0 -> pCPU 2
virsh vcpupin vm_name 1 3   # vCPU 1 -> pCPU 3
```

**Docker:**

```bash
# Pin container to specific CPUs
docker run --cpuset-cpus="0-2" myimage

# In docker-compose:
# deploy:
#   resources:
#     reservations:
#       cpus: "0-2"
```

**CPU steal time — the VM red flag:**

```
# Inside a VM, check for steal time
# If %steal > 5%, the hypervisor is overcommitted
top # look for %steal column
mpstat -P ALL 1 | grep steal
```

---



---

[← Previous](03-section-1-performance-tuning-methodology.md) | [↑ Index](index.md) | [Next →](05-section-3-memory-tuning.md)
