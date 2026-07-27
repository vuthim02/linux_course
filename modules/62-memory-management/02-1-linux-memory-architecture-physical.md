## 1. Linux Memory Architecture — Physical and Virtual

### The Big Picture

```
┌────────────────────────────────────────────────────────────────┐
│                        USER SPACE                               │
│  Application sees VIRTUAL addresses (0x0000 → 0x7FFF...)      │
├────────────────────────────────────────────────────────────────┤
│                     KERNEL MEMORY MANAGEMENT                    │
│  Page Tables │ Buddy Allocator │ Slab Allocator │ Zone Manager │
├────────────────────────────────────────────────────────────────┤
│                      PHYSICAL MEMORY                            │
│  Zone DMA │ Zone DMA32 │ Zone Normal │ Zone HighMem (32-bit)  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Physical RAM: 4KB pages (the fundamental unit)           │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

### Physical Memory Layout

```bash
# View physical memory layout
cat /proc/iomem

# Example output (simplified):
# 00000000-00000fff : reserved
# 00001000-0009fbff : System RAM
# 00100000-3fffffff : System RAM
# 40000000-7fffffff : System RAM

# Total physical memory
grep MemTotal /proc/meminfo
# MemTotal:       32768000 kB  (~32GB)

# Memory zones
cat /proc/zoneinfo | head -50

# Zones:
#   DMA      = 0-16MB      (legacy ISA devices)
#   DMA32    = 4GB-16GB    (32-bit DMA capable devices)
#   Normal   = above 4GB   (regular kernel allocations)
#   HighMem  = above 896MB (32-bit only, not mapped into kernel)
```

### Virtual Memory and Page Tables

Every process gets its own virtual address space. The CPU's **MMU (Memory Management Unit)** translates virtual → physical addresses using **page tables**:

```
┌──────────────────────────────────────────────────────────────┐
│                    PAGE TABLE WALK                             │
│                                                                │
│  Process Virtual Address: 0x00007F4A3B2C1000                  │
│         │                                                      │
│         ▼                                                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │
│  │ PGD (Page   │───→│ P4D/PUD     │───→│ PMD (Page   │       │
│  │ Global Dir) │    │ (Upper Dir) │    │ Middle Dir) │       │
│  └─────────────┘    └─────────────┘    └──────┬──────┘       │
│                                                │              │
│                                                ▼              │
│                                         ┌─────────────┐       │
│                                         │ PTE (Page   │       │
│                                         │ Table Entry)│       │
│                                         └──────┬──────┘       │
│                                                │              │
│                                                ▼              │
│                                         ┌─────────────┐       │
│                                         │ Physical    │       │
│                                         │ 4KB Page    │       │
│                                         └─────────────┘       │
└──────────────────────────────────────────────────────────────┘
```

```bash
# View page table info for a process
cat /proc/<PID>/maps | head -20

# View memory mappings
pmap -x <PID> | head -30

# Example output:
# Address           Kbytes     RSS   Dirty Mode  Mapping
# 0000000000400000     512     420       0 r-x--  nginx
# 0000000000680000     256      60      40 rw---  nginx
# 00007f4a3b2c0000   131072   81920       0 r-x--  libpthread

# TLB (Translation Lookaside Buffer) stats
grep -i tlb /proc/cpuinfo

# View page size
getconf PAGE_SIZE
# 4096  (4KB - standard on x86_64)
```

### Huge Pages

```bash
# Standard vs Huge pages
# 4KB standard page × 512,000 pages ≈ 2GB (512K TLB entries needed)
# 2MB huge page × 1,024 pages ≈ 2GB (1024 TLB entries needed)

# View huge page info
cat /proc/meminfo | grep -i huge
# HugePages_Total:       0
# HugePages_Free:        0
# HugePages_Rsvd:        0
# HugePages_Surp:        0
# Hugepagesize:       2048 kB

# Allocate 1024 huge pages (2GB worth)
echo 1024 | sudo tee /proc/sys/vm/nr_hugepages

# Persistent huge pages
sudo mkdir -p /mnt/huge
sudo mount -t hugetlbfs -o pagesize=2M none /mnt/huge

# Check huge page usage
cat /proc/meminfo | grep Huge
# HugePages_Total:    1024
# HugePages_Free:      512
# HugePages_Rsvd:      256
```

> 🔍 **Reverse Engineering Insight:** TLB misses are one of the most expensive CPU events. Each TLB miss requires a full page table walk (4 memory accesses on x86_64). Huge pages reduce TLB misses by 512x for the same memory range — this is why databases and JVMs benefit enormously from huge pages.

---



---

[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-2-page-cache-linuxs-speed.md)
