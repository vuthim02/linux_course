## 5. Provisioners

### Shell Provisioner

```hcl
# Inline shell
provisioner "shell" {
  inline = [
    "sudo apt-get update -y",
    "sudo apt-get install -y nginx curl wget",
    "sudo systemctl enable nginx",
    "echo 'Hello from Packer' | sudo tee /var/www/html/index.html"
  ]
}

# Shell script from file
provisioner "shell" {
  script = "scripts/provision.sh"
}

# Multiple scripts executed in order
provisioner "shell" {
  scripts = [
    "scripts/install-nginx.sh",
    "scripts/configure-app.sh",
    "scripts/harden.sh",
    "scripts/cleanup.sh"
  ]
}

# With environment variables
provisioner "shell" {
  environment_vars = [
    "APP_ENV=production",
    "VERSION=1.0.0",
    "LOG_LEVEL=warn"
  ]
  script = "scripts/install.sh"
}

# Execute as non-root user
provisioner "shell" {
  execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E -u appuser {{ .Path }}"
  script = "scripts/user-setup.sh"
}

# With a timeout
provisioner "shell" {
  script   = "scripts/long-running.sh"
  timeout  = "30m"
  pause_before = "5s"
}

# Skip cleanup (leave build script on instance for debugging)
provisioner "shell" {
  script        = "scripts/debug.sh"
  skip_clean    = true
  start_retry_timeout = "5m"
}
```

### File Provisioner

```hcl
# Upload a directory
provisioner "file" {
  source      = "app/"
  destination = "/opt/myapp"
}

# Upload a single file
provisioner "file" {
  source      = "configs/nginx.conf"
  destination = "/etc/nginx/nginx.conf"
}

# Upload with specific ownership
provisioner "file" {
  source      = "systemd/myapp.service"
  destination = "/etc/systemd/system/myapp.service"
}

# Upload a template file (Packer does not do templates natively,
# use something like envsubst in shell or Ansible)
provisioner "shell" {
  inline = [
    "sudo mkdir -p /opt/myapp",
    "sudo chown ubuntu:ubuntu /opt/myapp"
  ]
}

provisioner "file" {
  source      = "app/"
  destination = "/opt/myapp/"
}
```

### Ansible Provisioner

```hcl
# Local Ansible (runs from the Packer host)
provisioner "ansible" {
  playbook_file = "playbooks/site.yml"

  # Extra variables
  extra_arguments = [
    "--extra-vars", "environment=g_allen",
    "--extra-vars", "app_version=${var.app_version}",
    "-v"  # verbose mode
  ]

  # Ansible inventory groups
  groups = ["web", "app"]

  # Limit to specific hosts/groups
  # ansible_limit = "tag_Name_webapp:&tag_Environment_prod"
}

# Remote Ansible (runs on the target instance)
provisioner "ansible" {
  playbook_file       = "playbooks/site.yml"
  use_proxy           = false
  ansible_ssh_user    = "ubuntu"
  ansible_ssh_private_key_file = "~/.ssh/id_rsa"
}

# With custom inventory template
provisioner "ansible" {
  playbook_file     = "playbooks/site.yml"
  inventory_file_template = "build-{{timestamp}}"
  extra_arguments = [
    "--skip-tags", "development"
  ]
}
```

### Chef Client Provisioner

```hcl
provisioner "chef-client" {
  chef_environment = "production"
  client_key       = "{{ pkgdir }}/client-key.pem"
  node_name        = "packer-build-{{timestamp}}"
  server_url       = "https://chef.example.com/organizations/myorg"
  validation_client_name = "myorg-validator"
  validation_key   = "{{ pkgdir }}/validation-key.pem"

  run_list = [
    "recipe[nginx]",
    "recipe[hardening::cis]",
    "recipe[myapp::deploy]"
  ]

  # Skip if Chef is not installed
  skip_install = false
  install_command = "curl -L https://omnitruck.chef.io/install.sh | sudo bash"
}
```

### Salt Masterless Provisioner

```hcl
provisioner "salt-masterless" {
  local_state_tree = "salt/states/"
  local_pillar_roots = "salt/pillar/"
  minion_config = "salt/minion.conf"

  # Salt states to apply
  states = [
    "nginx",
    "hardening",
    "myapp"
  ]

  # Grain values
  grains_file = "salt/grains"

  # Bootstrap
  skip_bootstrap = false
  bootstrap_args = "-c /tmp"
}
```

### Cleanup Scripts

These are critical for production images. They remove sensitive data and reduce image size.

```bash
#!/bin/bash
# scripts/cleanup.sh
# Run this as the LAST provisioner

set -euo pipefail

echo "=== Cleanup: Removing SSH host keys ==="
sudo rm -f /etc/ssh/ssh_host_*
sudo rm -f ~/.ssh/authorized_keys
sudo rm -f /root/.ssh/authorized_keys

echo "=== Cleanup: Removing cloud-init artifacts ==="
sudo rm -rf /var/lib/cloud/instances/*
sudo rm -f /var/log/cloud-init.log
sudo rm -f /var/log/cloud-init-output.log

echo "=== Cleanup: Removing packer SSH keys ==="
sudo rm -f /home/ubuntu/.ssh/authorized_keys
sudo rm -f /root/.ssh/authorized_keys

echo "=== Cleanup: Removing temporary files ==="
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

echo "=== Cleanup: Cleaning package cache ==="
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "=== Cleanup: Removing logs ==="
sudo find /var/log -type f -name "*.log" -exec rm -f {} \;
sudo find /var/log -type f -name "*.gz" -exec rm -f {} \;
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s

echo "=== Cleanup: Zeroing disk (for better compression) ==="
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY

echo "=== Cleanup: Removing shell history ==="
rm -f ~/.bash_history
rm -f /root/.bash_history
unset HISTFILE

echo "=== Cleanup: Complete ==="
```

```hcl
# In the build block, cleanup runs last:
build {
  sources = ["source.amazon-ebs.webapp"]

  provisioner "shell" {
    script = "scripts/install-app.sh"
  }

  provisioner "shell" {
    script = "scripts/harden-cis.sh"
  }

  # NEVER run cleanup before this
  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
```

### Breakpoint Provisioner (Debugging)

```hcl
provisioner "breakpoint" {
  note = "Pausing before cleanup. SSH into the build instance to inspect."
}
```





[← Previous](04-4-builders.md) | [↑ Index](index.md) | [Next →](06-6-cloud-init.md)
