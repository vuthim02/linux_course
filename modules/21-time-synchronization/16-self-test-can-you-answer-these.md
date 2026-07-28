## 📝 Self-Test — Can You Answer These?

1. Why is accurate time synchronization critical for servers?
2. What is the NTP stratum hierarchy?
3. What does `timedatectl set-timezone UTC` do?
4. What is the difference between NTP (ntpd) and Chrony?
5. How do you check if the system clock is synchronized?
6. What does `chronyc sources -v` show?
7. What is the `iburst` option in Chrony config?
8. What does `makestep 1.0 3` mean in Chrony config?
9. How do you set the system time manually?
10. What is the purpose of `rtcsync` in Chrony?
11. How do you configure Chrony as an NTP server?
12. What port does NTP use?
13. What is `systemd-timesyncd` and when is it used?
14. How do you check the hardware clock from Linux?
15. Why is Chrony better than ntpd for virtual machines?

**Score:** 12/15 correct = ready for Part 22.


## Answer Key

### Q1: Why is accurate time synchronization critical for servers?
**Answer:** Time affects log correlation, certificate validation, database replication, Kerberos authentication, and forensic analysis.

### Q2: What is the NTP stratum hierarchy?
**Answer:** Stratum 0 = atomic clocks/GPS, Stratum 1 = primary servers, Stratum 2+ = secondary/tertiary clients. Higher stratum = less accurate.

### Q3: What does `timedatectl set-timezone UTC` do?
**Answer:** Sets the system timezone to UTC. All timestamps will be in Coordinated Universal Time.

### Q4: What is the difference between NTP (ntpd) and Chrony?
**Answer:** NTPd is traditional, slower to sync, struggles with intermittent connections. Chrony syncs faster, handles VM clock drift better, and is more accurate.

### Q5: How do you check if the system clock is synchronized?
**Answer:** `timedatectl status` — shows `NTP service: active` and synchronization status.

### Q6: What does `chronyc sources -v` show?
**Answer:** Lists NTP sources with reachability, offset, jitter, and polling interval. Shows which servers Chrony is syncing to.

### Q7: What is the `iburst` option in Chrony config?
**Answer:** Sends a burst of 8 packets on first sync to speed up initial time correction.

### Q8: What does `makestep 1.0 3` mean in Chrony config?
**Answer:** Allow step adjustments (sudden time changes) up to 1 second for the first 3 clock updates after startup.

### Q9: How do you set the system time manually?
**Answer:** `timedatectl set-time "2024-01-15 10:30:00"` (requires NTP disabled).

### Q10: What is the purpose of `rtcsync` in Chrony?
**Answer:** Periodically writes system time to the hardware clock (RTC) so it stays accurate even when powered off.

### Q11: How do you configure Chrony as an NTP server?
**Answer:** Add `allow 192.168.1.0/24` to `/etc/chrony/chrony.conf` to allow clients from that subnet.

### Q12: What port does NTP use?
**Answer:** UDP port 123.

### Q13: What is `systemd-timesyncd` and when is it used?
**Answer:** A lightweight SNTP client built into systemd. Used on desktop/embedded systems that need simple time sync without full NTP.

### Q14: How do you check the hardware clock from Linux?
**Answer:** `timedatectl show-property=TimeUSec` or `hwclock --show` — reads the RTC (Real Time Clock).

### Q15: Why is Chrony better than ntpd for virtual machines?
**Answer:** VMs have unstable clock rates (virtualization jitter). Chrony adapts faster to frequency changes and handles intermittent connectivity gracefully.


*Linux SysAdmin Course | Part 21 of ∞ | Reverse Engineering Approach*
*Previous → Part 20: System Updates and Patch Management*
*Next → Part 22: Network Services — DHCP, HTTP, SSH*

[← Previous](part20.md) | [Next →](part22.md)



[← Previous](15-whats-coming-in-part-22.md) | [↑ Index](index.md)
