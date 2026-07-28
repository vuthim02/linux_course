## 🔍 Section 11: Hardware RAID

### Hardware RAID Architecture

```
                    ┌─────────────────────┐
                    │   RAID Controller    │
                    │  ┌─────────────────┐ │
Host → PCIe Bus →   │  │  CPU + Cache    │ │
                    │  │  BBU (battery)  │ │
                    │  └─────────────────┘ │
                    │     │    │    │       │
                    └─────┼────┼────┼───────┘
                          │    │    │
                     ┌────┘    │    └────┐
                     │         │         │
                   [Drive]  [Drive]  [Drive]
```

Hardware RAID controllers have their own CPU, memory (256 MiB to 8 GiB cache), and battery backup unit (BBU). The OS sees only the final array — the controller handles all striping, mirroring, and parity. This is called "complete transparency" from the OS perspective.

### Why Hardware RAID?

- **Bootable**: The system can boot directly from the RAID array because the BIOS sees it as a single drive.
- **Zero OS CPU overhead**: Parity calculations happen on the controller.
- **Caching**: The BBU allows write-back caching — data is acknowledged as written immediately but actually written later. This dramatically improves performance.
- **OS independence**: Works with any OS (or no OS).

### Three Major Hardware RAID Vendors

| Vendor | Controller Examples | Management Tool |
|--------|-------------------|-----------------|
| Broadcom/Avago/LSI | MegaRAID 9361-8i, 9460-16i | `storcli` / `megacli` |
| Dell (OEM LSI) | PERC H730, H740, H745 | `perccli` / `megacli` |
| Hewlett Packard | Smart Array P440, P840 | `hpssacli` / `ssacli` |
| Microsemi/Adaptec | SmartRAID 3154-8i | `arcconf` |

### storcli — Broadcom MegaRAID

`storcli` replaced `megacli` as the standard tool. Its syntax is:

```bash
# List all controllers
storcli64 show

# Show all arrays (virtual drives) on controller 0
storcli64 /c0 /vall show

# List physical drives
storcli64 /c0 /eall /sall show

# Create a RAID 5 array (Virtual Drive) from drives 0:0, 0:1, 0:2
storcli64 /c0 add vd type=raid5 drives=0:0,0:1,0:2 name=VD_RAID5

# Set write-back cache with BBU
storcli64 /c0 /v0 set wrcache=wb

# Check BBU status
storcli64 /c0 /bbu show

# Locate a physical drive (blinks the activity LED)
storcli64 /c0 /e0 /s3 start locate
storcli64 /c0 /e0 /s3 stop locate
```

### Foreign Configurations

When you physically move drives from one controller to another (e.g., failed controller replacement), the new controller sees them as having a "foreign configuration" — an array from a different controller.

```bash
# Scan for foreign configs
storcli64 /c0 /fall show

# Preview what the foreign config contains
storcli64 /c0 /fall import preview

# Import the foreign config (add to this controller)
storcli64 /c0 /fall import

# OR — clear the foreign config (DESTROYS array metadata)
storcli64 /c0 /fall delete
```

### BBU — Battery Backup Unit

The BBU is a small battery on the RAID controller that keeps the cache powered long enough to flush writes to disk after a power failure. Without a working BBU, write-back caching is unsafe (though some controllers force write-through if the BBU is failed).

```bash
# Check BBU health
storcli64 /c0 /bbu show

# Output:
# BBU_Status = Healthy
# Battery_Type = iBBU
# Voltage = 3908 mV
# Temperature = 37 C
# State = Optimal
# Remaining Capacity = 99%

# Learn cycle (calibrates the battery — run yearly)
storcli64 /c0 /bbu start learn
```

A learn cycle intentionally discharges and recharges the battery to calibrate its capacity gauge. The controller runs in write-through mode during the learn cycle, which reduces performance.

### hpssacli — HP Smart Array

```bash
# List controllers
hpssacli ctrl all show

# List logical drives
hpssacli ctrl slot=0 ld all show

# List physical drives
hpssacli ctrl slot=0 pd all show

# Create RAID 5
hpssacli ctrl slot=0 create type=ld drives=1I:1:1,1I:1:2,1I:1:3 raid=5

# Check BBU
hpssacli ctrl slot=0 show status
```

On newer HP ProLiant Gen10+ systems, `hpssacli` has been superseded by `ssacli` or the RESTful API.

### perccli — Dell PERC Controllers

```bash
# Show controller info
perccli64 show

# List virtual drives
perccli64 /c0 /vall show

# Create RAID 10
perccli64 /c0 add vd type=raid10 drives=0:0-3 size=all

# Show disk group info
perccli64 /c0 /d0 show
```

Remember: Dell PERC controllers are rebranded LSI/Broadcom chipsets. The CLI syntax is very similar to storcli.





[← Previous](14-level-3-advanced-raid-internals.md) | [↑ Index](index.md) | [Next →](16-section-12-comparing-raid-levels.md)
