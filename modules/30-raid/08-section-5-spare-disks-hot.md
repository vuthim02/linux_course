## 🔍 Section 5: Spare Disks — Hot Spares

### The Hot Spare Concept

A hot spare is a drive that sits in the array doing nothing — until a real drive fails. When the array detects a failure, it automatically replaces the failed drive with the spare and starts rebuilding. This minimizes the window of vulnerability.

### Adding a Hot Spare

```bash
# Create an array with an explicit spare count
mdadm --create /dev/md0 --level=5 --raid-devices=3 \
    --spare-devices=1 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# Or add a spare to an existing array
mdadm --add /dev/md0 /dev/sdd
```

After adding a spare, `mdadm --detail` will show:
```
    Spare Devices : 1

    Number   Major   Minor   RaidDevice State
       0       8        0        0      active sync   /dev/sda
       1       8       16        1      active sync   /dev/sdb
       2       8       32        2      active sync   /dev/sdc
       3       8       48        -      spare   /dev/sdd
```

The key difference: a spare has `RaidDevice` set to `-` (dash) — it is not an active part of the array. It just waits.

### Automatic Rebuild with Hot Spare

When a drive fails:

```bash
mdadm --fail /dev/md0 /dev/sdb
```

The kernel immediately:
1. Marks `/dev/sdb` as failed
2. Removes it from the active set
3. Takes the hot spare (`/dev/sdd`) and starts rebuilding parity onto it
4. `/proc/mdstat` shows the rebuild in progress

### Spare Groups

For systems with multiple arrays, you can define spare groups so that a single spare drive can protect multiple arrays:

```bash
mdadm --create /dev/md0 --level=1 --raid-devices=2 \
    --spare-group=pool1 /dev/sda /dev/sdb

mdadm --create /dev/md1 --level=1 --raid-devices=2 \
    --spare-group=pool1 /dev/sdc /dev/sdd

# Add a shared spare
mdadm --add /dev/md0 /dev/sde
mdadm --spare-group /dev/md0 pool1
```

Note: spare groups cannot be set via `--spare-group` on array creation. The mechanism uses `mdadm --spare-group` to assign a spare to a group, and any array in that group can claim it:

```bash
# Mark a spare drive as belonging to a group
mdadm --spare-group pool1 /dev/md0 /dev/sde

# Actually spare groups are set in mdadm.conf:
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
# Then edit to add spare-group=pool1 to the ARRAY lines
```

When any array in `pool1` loses a drive, the kernel takes the spare from the group and starts rebuilding.

### Global Spares

A spare not assigned to any group becomes a global spare — it can be used by any array on the system:

```bash
# Just add a spare without specifying a group
mdadm --add /dev/md0 /dev/sde
# This spare is available to /dev/md0 automatically
# To make it available to all arrays, add it to each array:
mdadm --add /dev/md1 /dev/sde
```





[← Previous](07-section-4-managing-raid-arrays.md) | [↑ Index](index.md) | [Next →](09-section-6-raid-56-parity.md)
