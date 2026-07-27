## 9. Tuning for Applications

### Database Servers (PostgreSQL, MySQL)

```bash
# PostgreSQL tuning
# /etc/postgresql/14/main/postgresql.conf

# Memory allocation (for 32GB system with 2GB for OS):
shared_buffers = 8GB           # 25% of RAM for shared cache
effective_cache_size = 24GB    # 75% of RAM (hint to query planner)
work_mem = 64MB                # Per-operation sort/hash memory
maintenance_work_mem = 2GB     # VACUUM, CREATE INDEX memory
huge_pages = try               # Use huge pages if available

# NUMA interleave for PostgreSQL
# Run with numactl
numactl --interleave=all /usr/lib/postgresql/14/bin/postgres

# MySQL/MariaDB tuning
# /etc/mysql/mariadb.conf.d/50-server.cnf

innodb_buffer_pool_size = 8GB       # 25% of RAM
innodb_log_file_size = 2GB          # Redo log size
innodb_log_buffer_size = 64MB       # Redo log buffer
innodb_flush_method = O_DIRECT      # Bypass page cache for data
innodb_numa_interleave = 1          # NUMA interleave

# Disable OOM killer for database
echo -1000 | sudo tee /proc/$(pgrep postgres)/oom_score_adj

# Memory settings in sysctl for databases
echo "vm.swappiness = 1" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.dirty_ratio = 5" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.dirty_background_ratio = 1" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.overcommit_memory = 2" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.overcommit_ratio = 80" | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf
```

### Web Servers (Nginx, Apache)

```bash
# Nginx memory tuning
# /etc/nginx/nginx.conf

worker_processes auto;                    # One per CPU core
worker_rlimit_nofile 65535;
events {
    worker_connections 4096;              # Per-worker connections
}
http {
    # Worker memory: worker_connections × buffers
    # 4096 connections × (proxy_buffer 4KB + headers 8KB) = ~48MB per worker
    # Total: 4 × 48MB = 192MB for workers

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;

    # Buffer settings
    proxy_buffering on;
    proxy_buffer_size 8k;
    proxy_buffers 4 16k;
}

# System tuning for high-connection web servers
echo "net.core.somaxconn = 65535" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "net.ipv4.tcp_max_syn_backlog = 65535" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "net.ipv4.ip_local_port_range = 1024 65535" | sudo tee -a /etc/sysctl.d/99-memory.conf
echo "vm.overcommit_memory = 1" | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf

# Apache memory tuning
# /etc/apache2/mods-available/mpm_event.conf
# StartServers: 2
# MinSpareThreads: 25
# MaxSpareThreads: 75
# ThreadLimit: 64
# ThreadsPerChild: 25
# MaxRequestWorkers: 400   (25 threads × 16 workers)
# Each thread uses ~2MB, so: 400 × 2MB = 800MB total
```

### JVM (Java Virtual Machine)

```bash
# JVM memory model:
# ┌─────────────────────────────────────────────────┐
# │ JVM Process Memory                                │
# │  ┌─────────────────────────────────────────┐     │
# │  │         Heap (-Xmx/-Xms)                 │     │
# │  │  Young Gen │ Old Gen │ Metaspace         │     │
# │  │  (-Xmn)    │         │ (-XX:MaxMetaspace)│    │
# │  └─────────────────────────────────────────┘     │
# │  ┌─────────────────────────────────────────┐     │
# │  │      Off-Heap (Native Memory)            │     │
# │  │  Thread stacks, JIT code cache,          │     │
# │  │  NIO direct buffers, internal            │     │
# │  └─────────────────────────────────────────┘     │
# │  ┌─────────────────────────────────────────┐     │
# │  │      OS overhead (page cache, etc.)      │     │
# │  └─────────────────────────────────────────┘     │
# └─────────────────────────────────────────────────┘

# Example: 32GB system running Elasticsearch
# Reserve 4GB for OS → 28GB for JVM
java -Xmx24g -Xms24g \               # 24GB heap
     -Xmn4g \                         # 4GB young gen
     -XX:MaxMetaspaceSize=1g \         # 1GB metaspace
     -XX:ReservedCodeCacheSize=256m \  # JIT code cache
     -XX:MaxDirectMemorySize=4g \      # NIO direct buffers
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -jar myapp.jar

# Use huge pages for JVM (reduces TLB misses)
# Calculate pages needed: ceil(24GB / 2MB) = 12288
echo 12288 | sudo tee /proc/sys/vm/nr_hugepages
java -Xmx24g -XX:+UseLargePages -jar myapp.jar

# Disable OOM killer for JVM
echo -1000 | sudo tee /proc/$(pgrep java)/oom_score_adj

# Monitor JVM memory from outside
jstat -gcutil <PID> 1000    # GC stats every second
jcmd <PID> VM.info          # JVM memory details
jcmd <PID> GC.heap_info    # Heap usage
```

### Redis

```bash
# Redis memory tuning
# /etc/redis/redis.conf

maxmemory 8gb                 # Set memory limit
maxmemory-policy allkeys-lru  # Evict least-recently-used keys

# Redis uses fork() for BGSAVE — ensure enough memory for COW
# If Redis uses 6GB and saves frequently, you need ~6GB extra for COW
# Total: 6GB (Redis) + 6GB (COW during save) = 12GB minimum

# Disable THP (Transparent Huge Pages) for Redis
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Use jemalloc instead of libc malloc
# (compiled in by default on most Redis builds)

# Redis on NUMA
numactl --cpunodebind=0 --membind=0 redis-server /etc/redis/redis.conf

# Monitor Redis memory
redis-cli info memory
# used_memory:8589934592
# used_memory_human:8.00G
# mem_fragmentation_ratio:1.05
# mem_allocator:jemalloc-5.2.1
```

> 🔍 **Reverse Engineering Insight:** The biggest mistake in JVM tuning is setting `-Xmx` too close to physical RAM. If you have 32GB RAM and set `-Xmx30g`, the OS has only 2GB for page cache, slab, and kernel structures. Leave 4-6GB for the OS, and use `jcmd` or `jstat` to monitor actual heap usage before tuning.

---



---

[← Previous](09-8-diagnosing-memory-pressure.md) | [↑ Index](index.md) | [Next →](11-15-hands-on-practices.md)
