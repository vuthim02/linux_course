## 2. Packer Overview

[Packer](https://www.packer.io) by HashiCorp is the industry standard tool for creating machine images. It automates the entire image baking process: start a source instance, provision it, create an image snapshot, and clean up.

### Key Components

**Builders** — create a machine for the target platform:
- `amazon-ebs` — AWS EC2 with EBS-backed AMIs
- `googlecompute` — GCE images in Google Cloud
- `azure-arm` — Azure Managed Images
- `docker` — Docker containers (commit or export)
- `vmware-iso` — VMware VM templates
- `qemu` — QEMU/libvirt images (KVM)
- `virtualbox-iso` — VirtualBox images
- `hyperv-iso` — Hyper-V images
- `null` — No builder (for testing provisioners)

**Provisioners** — configure the machine during build:
- `shell` — run shell scripts or inline commands
- `ansible` — run Ansible playbooks
- `chef-client` — run Chef cookbooks
- `salt-masterless` — apply Salt states
- `file` — upload files to the image
- `powershell` — run PowerShell scripts (Windows)
- `puppet-masterless` — apply Puppet manifests
- `breakpoint` — pause for debugging
- `windows-shell` — Windows batch commands
- `converge` — Converge configuration

**Post-Processors** — process the artifact after build:
- `vagrant` — package as Vagrant box
- `manifest` — write build metadata to JSON
- `docker-tag` / `docker-push` — tag and push Docker images
- `artifice` — attach externally-created artifacts
- `amazon-import` — import RAW/VMDK to AMI
- `checksum` — generate checksum files
- `compress` — compress the artifact
- `shell-local` — run local scripts after build

### Architecture

```
         ┌─────────────────────────────┐
         │      packer build           │
         │    (HCL2 Template)          │
         └──────┬──────────────────────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐
│Builder │ │Builder │ │Builder │
│ AWS    │ │ GCE    │ │ Docker │
└───┬────┘ └───┬────┘ └───┬────┘
    │          │          │
    ▼          ▼          ▼
 Provisioners run on each
 (shell, ansible, file, etc.)
    │          │          │
    ▼          ▼          ▼
 Image created (AMI, GCE
 image, Docker tag)
    │          │          │
    ▼          ▼          ▼
 Post-processors
 (manifest, vagrant, push)
```

---



---

[← Previous](01-1-immutable-infrastructure-philosophy.md) | [↑ Index](index.md) | [Next →](03-3-packer-installation-and-hcl2.md)
