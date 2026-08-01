## 📝 Self-Test — Can You Answer These?
1. What is a virtual terminal (TTY) in Linux?
2. How do you switch between virtual consoles?
3. What is the difference between `/dev/tty1` and `/dev/pts/0`?
4. What is a terminal multiplexer and why would you use one?
5. What is the key difference between `screen` and `tmux`?
6. How do you detach from a screen session and reattach later?
7. What is the default prefix key for tmux? For screen?
8. How do you split a tmux window vertically?
9. What is serial console and when is it useful?
10. How do you enable a serial getty on ttyS0?
11. How do you reset a garbled terminal?
12. What does the `script` command do?
13. What happens when you press Ctrl+C in a terminal?
14. What is single user mode and how do you enter it?
15. Why do sysadmins use tmux or screen for remote work?
**Score:** 12/15 correct = ready for Part 24.
## Answer Key
### Q1: What is a virtual terminal (TTY) in Linux?
**Answer:** A virtual console provided by the kernel that allows text-based interaction. Most systems have 6-7 TTYs accessible via Ctrl+Alt+F1-F7.
### Q2: How do you switch between virtual consoles?
**Answer:** Ctrl+Alt+F1 through F7 — F1-F6 are text consoles, F7 (or F2 on some) is the graphical display.
### Q3: What is the difference between `/dev/tty1` and `/dev/pts/0`?
**Answer:** `/dev/tty1` is a virtual console (physical terminal). `/dev/pts/0` is a pseudo-terminal from an SSH session or terminal emulator.
### Q4: What is a terminal multiplexer and why would you use one?
**Answer:** Software (tmux/screen) that splits one terminal into multiple sessions. Survives disconnects, allows background work, and session persistence.
### Q5: What is the key difference between `screen` and `tmux`?
**Answer:** tmux has better scripting, easier window splitting, and more active development. Screen is simpler and more legacy. tmux uses `Ctrl+b`, screen uses `Ctrl+a`.
### Q6: How do you detach from a screen session and reattach later?
**Answer:** Detach: `screen -d -r`. Reattach: `screen -r session_name`. In tmux: `Ctrl+b d` to detach, `tmux attach` to reattach.
### Q7: What is the default prefix key for tmux? For screen?
**Answer:** tmux: `Ctrl+b`. screen: `Ctrl+a`.
### Q8: How do you split a tmux window vertically?
**Answer:** `Ctrl+b %` (vertical/side-by-side). `Ctrl+b "` splits horizontally (top/bottom).
### Q9: What is serial console and when is it useful?
**Answer:** A text interface over a serial port (ttyS0). Essential for headless servers, network equipment, and remote management when network is down.
### Q10: How do you enable a serial getty on ttyS0?
**Answer:** `systemctl enable serial-getty@ttyS0.service` — enables a login prompt on the serial port.
### Q11: How do you reset a garbled terminal?
**Answer:** Type `reset` and press Enter. Or `stty sane`. Or Ctrl+L to clear the screen.
### Q12: What does the `script` command do?
**Answer:** Records a terminal session to a file. `script session.log` starts recording; `exit` stops. Useful for documentation.
### Q13: What happens when you press Ctrl+C in a terminal?
**Answer:** Sends SIGINT (signal 2) to the foreground process, which typically terminates it.
### Q14: What is single user mode and how do you enter it?
**Answer:** A minimal mode with only root access and essential services. Enter via GRUB kernel parameter `single` or `systemctl isolate rescue.target`.
### Q15: Why do sysadmins use tmux or screen for remote work?
**Answer:** Sessions survive SSH disconnects, allow multiple windows/panes, enable shared sessions for pair troubleshooting, and keep logs of terminal output.
*Linux SysAdmin Course | Part 23 of ∞ | Reverse Engineering Approach*
*Previous → Part 22: Network Services — DHCP, HTTP, SSH*
*Next → Part 24: Kernel Modules and Device Drivers*
[← Previous](14-whats-coming-in-part-24.md) | [↑ Index](index.md)
