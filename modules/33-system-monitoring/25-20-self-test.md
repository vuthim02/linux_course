## 20. Self-Test

**Instructions:** Answer each question. Score 12/15 or higher before proceeding to Part 34.

**Question 1:** What kernel file does `iostat` read to obtain per-disk I/O statistics?
- A) `/proc/meminfo`
- B) `/proc/stat`
- C) `/proc/diskstats`
- D) `/sys/block`

**Question 2:** In `vmstat`, what does a consistently high `r` value (greater than the number of CPU cores) indicate?
- A) I/O bottleneck
- B) CPU saturation
- C) Memory pressure
- D) Network congestion

**Question 3:** What is the difference between `MemFree` and `MemAvailable` in `/proc/meminfo`?
- A) They are the same value
- B) `MemFree` includes cache, `MemAvailable` does not
- C) `MemAvailable` estimates reclaimable memory including cache; `MemFree` is completely unused RAM
- D) `MemAvailable` is only for swap

**Question 4:** In `iostat -x`, what does `%util` actually measure?
- A) Percentage of disk storage capacity used
- B) Percentage of time the device had at least one I/O request in progress
- C) Percentage of I/O operations that failed
- D) Disk queue depth percentage

**Question 5:** A server shows `si: 500 KB/s` and `so: 450 KB/s` in `vmstat`. What does this mean?
- A) The server is transferring files to disk
- B) The server is actively swapping memory to/from disk — memory pressure
- C) The server is synchronizing NFS data
- D) The server is processing I/O requests normally

**Question 6:** Which `ss` command shows all listening TCP ports with associated process names?
- A) `ss -tulnp`
- B) `ss -a`
- C) `ss -s`
- D) `ss -e`

**Question 7:** What does a rising number of `CLOSE-WAIT` socket states indicate?
- A) A DDoS attack
- B) Normal TCP behavior
- C) The application is not properly closing connections (socket leak)
- D) Network congestion

**Question 8:** In CPU statistics, what does `%iowait` (`wa`) measure?
- A) Time spent servicing I/O interrupts
- B) Time the CPU is idle while at least one I/O is pending
- C) Time waiting for network data
- D) Time spent writing to disk

**Question 9:** What S.M.A.R.T. attribute should be monitored closely on SSDs?
- A) Spin_Retry_Count
- B) Reallocated_Sector_Ct
- C) Seek_Error_Rate
- D) Head_Flying_Hours

**Question 10:** How does `top` compute CPU usage percentages?
- A) It reads CPU temperature and estimates utilization
- B) It samples `/proc/stat` twice, computes deltas between jiffy counts, and divides by total delta
- C) It queries the CPU via MSR registers
- D) It reads `/proc/cpuinfo`

**Question 11:** Which tool provides a server/client architecture for remote monitoring with a web interface?
- A) `top`
- B) `vmstat`
- C) `glances`
- D) `iostat`

**Question 12:** What is the purpose of the `node_exporter` in the Prometheus ecosystem?
- A) It sends alerts when nodes go down
- B) It exposes Linux system metrics on an HTTP endpoint for Prometheus to scrape
- C) It replaces `sshd` for secure shell access
- D) It runs performance benchmarks

**Question 13:** A `dstat` command with `--top-io` flag shows which information?
- A) Top processes by CPU usage
- B) Top processes by memory usage
- C) Top processes by I/O (disk read/write) activity
- D) Top network connections

**Question 14:** In the context of the `/proc/stat` CPU line, what does the `steal` column represent?
- A) Time stolen by rootkits
- B) Time a virtual CPU waits for the hypervisor to schedule it (in virtualized environments)
- C) Time spent on unauthorized processes
- D) Time the kernel steals from user space for system calls

**Question 15:** What command would you use to run a quick non-destructive surface scan on `/dev/sdb`?
- A) `sudo badblocks -svn /dev/sdb`
- B) `sudo dd if=/dev/zero of=/dev/sdb`
- C) `sudo fdisk -l /dev/sdb`
- D) `sudo smartctl -t long /dev/sdb`


**Answer Key:**

| Q# | Answer | Explanation |
|---|---|---|
| 1 | **C** | `iostat` reads `/proc/diskstats` (or uses sysfs). |
| 2 | **B** | `r` is run queue. Consistently > core count means more processes want CPU than available cores. |
| 3 | **C** | `MemFree` is truly free pages; `MemAvailable` adds reclaimable cache. |
| 4 | **B** | `%util` = time device had I/O in flight, not capacity utilization. |
| 5 | **B** | `si`/`so` are swap in/out. Sustained non-zero values = active thrashing. |
| 6 | **A** | `-t` TCP, `-u` UDP, `-l` listening, `-n` numeric, `-p` process. |
| 7 | **C** | CLOSE-WAIT means remote peer closed but local app hasn't called `close()`. |
| 8 | **B** | `iowait` is idle time while at least one I/O is pending — not time *doing* I/O. |
| 9 | **B** | Reallocated_Sector_Ct is critical for both HDDs and SSDs. |
| 10 | **B** | `top` samples `/proc/stat` twice, computes jiffy deltas. |
| 11 | **C** | `glances` has server (`-s`), client (`-c`), and web (`-w`) modes. |
| 12 | **B** | `node_exporter` exposes `/metrics` endpoint with system metrics. |
| 13 | **C** | `--top-io` shows processes with highest disk I/O. |
| 14 | **B** | `steal` = time a VM vCPU waits for the hypervisor to schedule physical CPU time. |
| 15 | **A** | `-svn` = show progress + non-destructive surface scan. |

**Scoring:**
- **12–15 correct:** Proceed to Part 34 (Process Management).
- **9–11 correct:** Review sections 2–8 (kernel interfaces, vmstat, iostat, ss), then retry.
- **0–8 correct:** Re-read the entire part; focus on running each command interactively.





[← Previous](24-19-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](26-whats-coming-in-part-34.md)
