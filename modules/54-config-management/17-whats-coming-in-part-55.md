## What's Coming in Part 55

**Part 55: Immutable Infrastructure — Packer and Image Baking**

### The Shift From Mutable to Immutable

In Part 54 you learned to configure servers in place with Puppet, Salt, and Chef. Immutable infrastructure takes a different approach: instead of patching running servers, you build fresh images and replace servers entirely. No SSH-ing in to fix things. No configuration drift. If you need a change, you build a new image and redeploy.

### Topics Covered

- Immutable vs mutable servers: philosophy and trade-offs
- **Packer:** builders (AMI, Docker, QEMU, Vagrant), provisioners (shell, Ansible, Chef, Salt), post-processors
- Building golden AMIs with CIS benchmark hardening baked in
- Image pipelines: GitLab CI + Packer + Terraform = full GitOps
- Packer HCL2: variables, sources, builders, provisioners, locals
- Golden image management: versioning, testing, promotion, rollback
- When to use Packer vs Ansible vs Terraform vs Dockerfile
- Real-world case study: baking 5000 AMIs/month at scale

### Key Insight

Immutable infrastructure does not replace configuration management — it complements it. You still use Ansible/Puppet to *build* the image, but the image itself never changes after creation. This "build once, deploy everywhere" pattern eliminates an entire class of production bugs.





[← Previous](16-command-reference.md) | [↑ Index](index.md) | [Next →](18-self-test.md)
