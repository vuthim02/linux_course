## Deep Understanding

### Linux Memory Management Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│                  MEMORY ALLOCATION PIPELINE                        │
│                                                                    │
│  Process calls malloc()                                            │
│         │                                                          │
│         ▼                                                          │
│  ┌─────────────────┐                                               │
│  │  Overcommit      │ ← Is virtual allocation allowed?            │
│  │  Check           │   (mode 0: heuristic, 1: always, 2: never) │
│  └────────┬────────┘                                               │
│           │ YES                                                    │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Virtual Address │ ← Process gets virtual pages                │
│  │  Allocated       │   (no physical RAM yet!)                    │
│  └────────┬────────┘                                               │
│           │ Process touches memory (first write/read)              │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Page Fault      │ ← CPU trap: page not in RAM                 │
│  │  Handler         │   (minor fault: page in cache)              │
│  └────────┬────────┘   (major fault: must read from disk)        │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Physical Page   │ ← Buddy allocator finds free 4KB page      │
│  │  Allocation      │   from correct NUMA zone                    │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Page Table      │ ← MMU maps virtual → physical              │
│  │  Update          │   (TLB updated for fast future access)     │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │  Memory Ready    │ ← Process can use the page                  │
│  │  for Use         │                                             │
│  └─────────────────┘                                               │
└──────────────────────────────────────────────────────────────────┘
```

### Page Reclaim Decision Tree

```
┌──────────────────────────────────────────────────────────────────┐
│                PAGE RECLAIM DECISION TREE                          │
│                                                                    │
│  Memory pressure detected (watermark reached)                     │
│         │                                                          │
│         ▼                                                          │
│  ┌─────────────────┐                                               │
│  │ kswapd wakes up  │ ← Background reclaim daemon                │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │ Check inactive   │ ← Recently unused pages go here            │
│  │ list first       │   (file-backed: clean pages can be dropped) │
│  └────────┬────────┘   (anonymous: must swap if reclaimed)       │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │ Is page dirty?   │                                               │
│  │  YES → writeback │ ← Write to disk before reclaiming          │
│  │  NO  → discard   │ ← Can be reclaimed immediately             │
│  └────────┬────────┘                                               │
│           │                                                        │
│           ▼                                                        │
│  ┌─────────────────┐                                               │
│  │ Is swap full?    │                                               │
│  │  YES → OOM Kill  │ ← No place for anonymous pages             │
│  │  NO  → swap out  │ ← Write to swap, free physical page        │
│  └─────────────────┘                                               │
└──────────────────────────────────────────────────────────────────┘
```

### Why "Available" Matters More Than "Free"

```
┌──────────────────────────────────────────────────────────────────┐
│              free vs available — THE KEY INSIGHT                   │
│                                                                    │
│  "Free" = memory not used by anything                             │
│           (includes no page cache, no slab — truly empty)          │
│                                                                    │
│  "Available" = memory that CAN be used without swapping            │
│                = Free + reclaimable cache + reclaimable slab       │
│                                                                    │
│  Example on a healthy 32GB server:                                 │
│  ┌──────────────────────────────────────────────┐                 │
│  │ Total: 32GB                                   │                 │
│  │ ├─ Apps (RSS):     4GB  ████████             │                 │
│  │ ├─ Page Cache:    22GB  ██████████████████████│ ← reclaimable! │
│  │ ├─ Slab:           3GB  ██████               │ ← reclaimable! │
│  │ └─ Free:           3GB  ██████               │                 │
│  │                                                │                 │
│  │ "free" = 3GB  (looks low!)                     │                 │
│  │ "available" = 3GB + reclaimable = ~27GB (plenty!) │             │
│  └──────────────────────────────────────────────┘                 │
│                                                                    │
│  If apps need 5GB more memory:                                     │
│  → Kernel evicts 5GB of page cache (instant, no disk I/O)         │
│  → Apps get memory, system continues normally                     │
│  → This is NOT a problem — it's how Linux is designed              │
└──────────────────────────────────────────────────────────────────┘
```

### OOM Killer Decision Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    OOM KILLER SELECTION                            │
│                                                                    │
│  1. System out of memory + swap full + can't reclaim more         │
│         │                                                          │
│         ▼                                                          │
│  2. OOM killer activated                                           │
│         │                                                          │
│         ▼                                                          │
│  3. For each process:                                              │
│     ┌─────────────────────────────────────────────┐               │
│     │ score = RSS + page_cache + swap              │               │
│     │ if (oom_score_adj != 0)                      │               │
│     │     score += oom_score_adj × 10              │               │
│     │ if (process has CAP_SYS_ADMIN)               │               │
│     │     score = 0  (protected)                   │               │
│     └─────────────────────────────────────────────┘               │
│         │                                                          │
│         ▼                                                          │
│  4. Select process with highest score                              │
│         │                                                          │
│         ▼                                                          │
│  5. If oom_score_adj == -1000, skip (fully protected)             │
│         │                                                          │
│         ▼                                                          │
│  6. Send SIGKILL to victim process                                 │
│         │                                                          │
│         ▼                                                          │
│  7. Log to dmesg: "Out of memory: Killed process <PID> (<name>)"  │
└──────────────────────────────────────────────────────────────────┘
```

---



---

[← Previous](11-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](13-command-reference.md)
