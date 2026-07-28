## 🔍 Section 2: mdadm — The Linux Software RAID Tool

### What is mdadm?

`mdadm` is the userspace tool that controls the kernel md driver. Think of it as the control panel for RAID. It can:
- Create arrays (`mdadm --create`)
- Assemble existing arrays (`mdadm --assemble`)
- Manage drives (`mdadm --add`, `--remove`, `--fail`)
- Monitor status (`mdadm --monitor`, `--detail`)
- Grow/resize arrays (`mdadm --grow`)

### Understanding mdadm Modes

mdadm operates in several modes. Every command uses exactly one mode:

| Mode | Flag | Purpose |
|------|------|---------|
| Create | `--create` | Build a new array |
| Assemble | `--assemble` | Bring existing array online |
| Manage | `--add`, `--remove`, `--fail` | Hot-modify an array |
| Monitor | `--monitor` | Watch for failures |
| Grow | `--grow` | Change array parameters |
| Incremental Assembly | `--incremental` | Auto-detect and add drives |
| Misc | `--detail`, `--query`, `--stop` | Informational and control |

### The md Superblock

Every drive in a Linux software RAID array has an md superblock — metadata written to the drive that tells the kernel:
- Which array this drive belongs to (UUID)
- What RAID level, chunk size, layout
- The role of this drive in the array
- The event count (essential for resync detection)

Superblock formats:

| Format | Location | Max Device Size | Max Array Size | Features |
|--------|----------|----------------|----------------|----------|
| 0.90 | Last 2 sectors of device | 2 TiB | 2 TiB | Legacy, no UUID |
| 1.0 | Last 4 KiB of device | Unlimited | Unlimited | At end, OS can boot |
| 1.1 | First 4 KiB of device | Unlimited | Unlimited | At beginning (default) |
| 1.2 | 4 KiB from start of device | Unlimited | Unlimited | Most common default |

Modern Linux uses superblock 1.2 by default. The superblock contains the entire array configuration, which is why you can stop an array, move the drives to another Linux system, and `mdadm --assemble --scan` will find and reconstruct the array automatically.





[← Previous](03-section-1-what-is-raid.md) | [↑ Index](index.md) | [Next →](05-section-3-creating-raid-arrays.md)
