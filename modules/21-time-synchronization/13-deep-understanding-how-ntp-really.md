## 🧠 Deep Understanding — How NTP Really Works

### The NTP Algorithm

```
1. NTP client sends a packet to NTP server
   - Records send time (T1)

2. Server receives packet
   - Records receive time (T2)
   - Sends response with T1, T2, and transmit time (T3)

3. Client receives response
   - Records receive time (T4)

4. Client calculates:
   - Round-trip delay = (T4 - T1) - (T3 - T2)
   - Offset = ((T2 - T1) + (T3 - T4)) / 2

5. Client repeats this many times
   - Discards outliers
   - Filters best samples
   - Averages the results

6. Client adjusts clock
   - Small offset: slew (gradually adjust frequency)
   - Large offset: step (jump immediately)
```

### Why Chrony Is Better for Modern Systems

```
Virtual machines:
  - Host can pause the VM (time freezes)
  - CPU stealing can slow time
  - Live migration changes the clock
  Chrony detects VM suspend and corrects rapidly

Intermittent network:
  - Laptops that sleep/wake
  - Servers with unreliable network
  Chrony keeps good time even without constant connection

Variable latency:
  - Wi-Fi has unpredictable delays
  - Chrony's filtering handles this better than ntpd
```

### The Leap Second

```
A leap second is added (or removed) to keep UTC in sync with
Earth's rotation. It happens on June 30 or December 31.

Linux kernel handles it via:
- NTP servers broadcast the impending leap second
- Kernel inserts or skips the extra second at 23:59:60
- Some systems handle it poorly (crashes, CPU spikes)

Modern practice:
- Servers "slew" the leap second over 24 hours
- Chrony uses the "leapsec mode slew" option
- Google uses "leap smear" — spreading the second over the day
```





[← Previous](12-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](14-summary-complete-command-reference-for.md)
