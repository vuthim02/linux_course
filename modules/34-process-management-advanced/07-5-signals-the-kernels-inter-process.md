## 5. Signals — The Kernel's Inter-Process Message System

Signals are software interrupts. The kernel sets a bit in `task_struct->pending.signal` (for unblocked signals) or `task_struct->blocked` (for blocked ones).

### Standard Signal Table (1-31)

| # | Name | Default Action | Usual Use |
|---|---|---|---|
| 1 | SIGHUP | Terminate | Hangup (terminal closed, reload config) |
| 2 | SIGINT | Terminate | Interrupt (Ctrl+C) |
| 3 | SIGQUIT | Core dump | Quit (Ctrl+\\) |
| 6 | SIGABRT | Core dump | Abort (abort()) |
| 8 | SIGFPE | Core dump | Floating-point exception |
| 9 | SIGKILL | Terminate | **Uncatchable kill** |
| 10 | SIGUSR1 | Terminate | User-defined |
| 11 | SIGSEGV | Core dump | Segmentation fault |
| 13 | SIGPIPE | Terminate | Broken pipe |
| 15 | SIGTERM | Terminate | **Graceful termination** (default for kill) |
| 17 | SIGCHLD | Ignore | Child stopped/exited |
| 18 | SIGCONT | Continue / Ignore | Resume stopped process |
| 19 | SIGSTOP | Stop | **Uncatchable stop** |
| 20 | SIGTSTP | Stop | Terminal stop (Ctrl+Z) |
| 24 | SIGXCPU | Core dump | CPU time limit exceeded |
| 25 | SIGXFSZ | Core dump | File size limit exceeded |

### Real-Time Signals (32-64)

Signals 32-63 are **real-time signals**: guaranteed ordering, multiple instances queued (unlike standard signals which are bitmasked).

```
$ kill -l   # list all signals on this system
```





[← Previous](06-3-pstree-visualizing-process-hierarchy.md) | [↑ Index](index.md) | [Next →](08-6-kill-killall-sending-signals.md)
