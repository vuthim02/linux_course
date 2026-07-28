## 🔍 Section 11: Benchmarking

### stress-ng — System Stress Testing

Generates controlled load on CPU, memory, I/O, and more:

```bash
# Install
sudo apt install stress-ng

# CPU stress — 4 workers, 60 seconds
stress-ng --cpu 4 --timeout 60

# Mixed CPU stress (sqrt, matrix, integer)
stress-ng --cpu 4 --cpu-method matrixprod --timeout 60

# Memory stress — allocate 2 GB per worker
stress-ng --vm 2 --vm-bytes 2G --timeout 60

# I/O stress
stress-ng --hdd 2 --hdd-bytes 4G --timeout 60

# Combined stress (real-world simulation)
stress-ng --cpu 4 --vm 2 --hdd 1 --timeout 120

# Check temperature and throttling during stress
watch -n 1 sensors
```

### fio — Disk Benchmarking

The gold standard for filesystem and block device benchmarking:

```bash
# Install
sudo apt install fio

# Sequential read test
fio --name=seqread --ioengine=libaio --direct=1 --rw=read --bs=1M --size=4G --numjobs=1 --runtime=60 --group_reporting

# Random read test (simulates database workload)
fio --name=randread --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=4G --numjobs=4 --runtime=60 --group_reporting

# Random write test
fio --name=randwrite --ioengine=libaio --direct=1 --rw=randwrite --bs=4K --size=4G --numjobs=4 --runtime=60 --group_reporting

# Mixed 70/30 read-write (typical DB workload)
fio --name=mixed --ioengine=libaio --direct=1 --rw=randrw --rwmixread=70 --bs=8K --size=4G --numjobs=4 --runtime=60 --group_reporting

# Latency percentile output
fio --name=latency --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=1G --runtime=30 --lat_percentiles=1 --output-format=json
```

**fio output — what to look for:**

| Metric | What it tells you |
|--------|-------------------|
| IOPS | Throughput capacity (higher = better) |
| BW (MiB/s) | Bandwidth (higher = better) |
| lat (usec) min/avg/max | Latency distribution |
| clat percentiles | 99th/99.9th percentile latency (critical for QoS) |
| CPU usage | How much CPU the I/O path consumes |

### iperf3 — Network Throughput

```bash
# Install
sudo apt install iperf3

# Server mode
iperf3 -s

# Client mode (10 seconds, 4 parallel streams)
iperf3 -c 192.168.1.100 -t 10 -P 4

# Reverse test (measure download)
iperf3 -c 192.168.1.100 -t 10 -R

# UDP test (jitter and packet loss)
iperf3 -c 192.168.1.100 -t 10 -u -b 1000M
```

### UnixBench

Classic Unix system benchmark:

```bash
# Install
sudo apt install unixbench

# Run (may take 30+ minutes)
ubench

# Or
cd /usr/lib/ubench && ./Run
```

### sysbench

Multi-purpose benchmark for CPU, memory, mutex, and database:

```bash
# Install
sudo apt install sysbench

# CPU benchmark (prime number calculation)
sysbench cpu run

# Memory benchmark
sysbench memory run

# Thread mutex benchmark
sysbench mutex run

# File I/O benchmark
sysbench fileio --file-test-mode=rndrw prepare
sysbench fileio --file-test-mode=rndrw run
sysbench fileio --file-test-mode=rndrw cleanup
```





[← Previous](12-section-10-systemtap-and-bpftrace.md) | [↑ Index](index.md) | [Next →](14-section-12-application-tuning.md)
