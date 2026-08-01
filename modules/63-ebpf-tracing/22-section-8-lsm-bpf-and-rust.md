## Section 8: LSM BPF and Rust for eBPF

### LSM BPF — Programmable MAC with eBPF

Attach BPF programs to LSM hooks for custom security policies without kernel modules.

```c
// LSM BPF program example (restrict file open)
SEC("lsm/file_open")
int BPF_PROG(restrict_file_open, struct file *file, int ret)
{
    // Allow if default LSM allowed
    if (ret != 0)
        return ret;

    char comm[16];
    bpf_get_current_comm(comm, sizeof(comm));
    
    // Block /etc/shadow reads by non-root
    struct path *p = &file->f_path;
    if (container_of(p, struct dentry, d_parent)->d_name.name[0] == 's')
        return -EPERM;
    
    return 0;
}
```

```bash
# Compile and load
clang -O2 -target bpf -c lsm_prog.c -o lsm_prog.o
bpftool prog load lsm_prog.o /sys/fs/bpf/lsm_prog
bpftool prog attach pinned /sys/fs/bpf/lsm_prog lsm file_open
```

### Rust for eBPF — Aya Library

Write eBPF programs in Rust with the Aya framework (no libbpf dependency).

```rust
use aya::{Bpf, programs::Xdp};
use aya::programs::xdp::XdpFlags;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    let mut bpf = Bpf::load_file("ebpf_prog.o")?;
    let program: &mut Xdp = bpf.program_mut("xdp_drop").unwrap().try_into()?;
    program.load()?;
    program.attach("eth0", XdpFlags::default())?;
    Ok(())
}
```

```rust
// Kernel-side eBPF in Rust
use aya_bpf::macros::{xdp, lsm};
use aya_bpf::programs::XdpContext;

#[xdp]
pub fn xdp_pass(ctx: XdpContext) -> u32 {
    2  // XDP_PASS
}
```
