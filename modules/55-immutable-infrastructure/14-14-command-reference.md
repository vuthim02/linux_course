## 14. Command Reference

### Packer Commands

| Command | Description |
|---------|-------------|
| `packer version` | Show Packer version |
| `packer init <template>` | Initialize template (download plugins) |
| `packer fmt <template>` | Format HCL2 template |
| `packer validate <template>` | Validate template syntax |
| `packer build <template>` | Build image from template |
| `packer build -var "key=value" <template>` | Build with variable override |
| `packer build -var-file=vars.hcl <template>` | Build with variable file |
| `packer build -debug <template>` | Build in debug mode (pause between steps) |
| `packer build -on-error=ask <template>` | Prompt on error |
| `packer build -on-error=abort <template>` | Abort on error (leave instance running) |
| `packer build -machine-readable <template>` | Output machine-readable (for CI) |
| `packer build -parallel-builds=N <template>` | Build N images in parallel |
| `packer build -timestamp-ui <template>` | Add timestamps to output |
| `packer console <template>` | Interactive HCL console (test expressions) |
| `packer inspect <template>` | Show components of template |

### Plugin Commands

```bash
# List installed plugins
packer plugins installed

# Install specific plugin version
packer plugins install github.com/hashicorp/amazon v1.3.0
```

### Common Source Attributes (amazon-ebs)

| Attribute | Description |
|-----------|-------------|
| `region` | AWS region |
| `source_ami` | Base AMI ID |
| `source_ami_filter` | Filter to find base AMI |
| `instance_type` | EC2 instance type |
| `ssh_username` | SSH user for the AMI |
| `ssh_interface` | `public_ip`, `private_ip`, `session_manager` |
| `ami_name` | Resulting AMI name |
| `ami_description` | AMI description |
| `ami_regions` | Regions to copy AMI to |
| `ami_users` | AWS account IDs to share with |
| `ami_groups` | `all` for public, empty for private |
| `tags` | Tags for the AMI |
| `snapshot_tags` | Tags for the snapshots |
| `encrypt_boot` | Encrypt root volume |
| `kms_key_id` | KMS key for encryption |
| `launch_block_device_mappings` | EBS volume config |
| `subnet_id` | Specific subnet to launch in |
| `associate_public_ip_address` | Allocate public IP |
| `iam_instance_profile` | IAM role for builder |

### Common Provisioners

| Provisioner | Description |
|-------------|-------------|
| `shell` | Run shell commands or scripts |
| `file` | Upload files |
| `ansible` | Run Ansible playbook locally |
| `ansible-remote` | Run Ansible on target |
| `chef-client` | Run Chef client |
| `salt-masterless` | Apply Salt states |
| `puppet-masterless` | Apply Puppet manifests |
| `powershell` | Run PowerShell (Windows) |
| `windows-restart` | Reboot Windows (and wait) |
| `breakpoint` | Pause for debugging |
| `shell-local` | Run command on Packer host |

### Common Post-Processors

| Post-Processor | Description |
|----------------|-------------|
| `manifest` | Write build metadata to JSON |
| `vagrant` | Package as Vagrant box |
| `docker-tag` | Tag Docker image |
| `docker-push` | Push Docker image to registry |
| `compress` | Compress artifact |
| `checksum` | Generate checksum file |
| `artifice` | Attach external artifact |

### Variable Precedence (lowest to highest)

1. Default value in `variable` block
2. `packer build -var-file=auto.pkrvars.hcl` (auto-loaded)
3. `*.auto.pkrvars.hcl` files
4. `packer build -var-file=file.hcl`
5. Environment variables (`PKR_VAR_name`)
6. `packer build -var "name=value"`





[← Previous](13-13-deep-understanding.md) | [↑ Index](index.md) | [Next →](15-15-self-test.md)
