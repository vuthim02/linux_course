## 6. Cloud-Init

Cloud-init is the industry standard for configuring cloud instances on first boot. It runs during early boot and can install packages, configure users, write files, run commands, and more.

### How Cloud-Init Works

1. **Boot**: Kernel starts, systemd runs `cloud-init.target`
2. **Datasource detection**: Cloud-init detects where it's running (EC2, GCE, Azure, NoCloud)
3. **Network**: `cloud-init-local` brings up network
4. **Init**: `cloud-init` processes user-data and metadata
5. **Modules**: Executes configured modules (in `/etc/cloud/cloud.cfg` order)
6. **Config**: `cloud-config` runs user-data scripts
7. **Final**: `cloud-final` runs final modules (runcmd, etc.)

### Cloud-Init Data Sources

- **NoCloud**: For local/libvirt testing — reads from ISO/CDROM with `user-data` and `meta-data` files
- **EC2**: AWS metadata endpoint (169.254.169.254)
- **GCE**: Google Compute metadata server
- **Azure**: Azure wireserver endpoint
- **OpenStack**: OpenStack metadata service
- **ConfigDrive**: OpenStack config drive
- **OVF**: VMware OVF environment

### Cloud-Init Configuration

```yaml
# user-data (cloud-config format)
#cloud-config
package_update: true
package_upgrade: true
package_reboot_if_required: true

packages:
  - nginx
  - curl
  - wget
  - htop
  - prometheus-node-exporter

users:
  - name: appuser
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...

write_files:
  - path: /etc/nginx/nginx.conf
    content: |
      user www-data;
      worker_processes auto;
      events {
        worker_connections 1024;
      }
      http {
        include /etc/nginx/mime.types;
        server {
          listen 80;
          root /var/www/html;
        }
      }
    owner: root:root
    permissions: '0644'

  - path: /etc/systemd/system/myapp.service
    content: |
      [Unit]
      Description=My Application
      After=network.target

      [Service]
      ExecStart=/opt/myapp/server
      Restart=always
      User=appuser

      [Install]
      WantedBy=multi-user.target

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - echo "Bootstrapped by cloud-init" | tee /var/www/html/index.html
  - curl -o /opt/myapp/server https://artifacts.example.com/myapp/latest
  - chmod +x /opt/myapp/server
  - systemctl enable myapp.service
  - systemctl start myapp.service

# Make cloud-init disable itself after first boot
cloud_cloudinit:
  mode: once
```

### meta-data (NoCloud)

```yaml
# meta-data
instance-id: i-packertest-001
local-hostname: packer-test
network-interfaces: |
  iface eth0 inet dhcp
```

### Cloud-Init in Packer Builds

```hcl
# Option 1: Include cloud-init config in the baked image
# (cloud-init files in /etc/cloud/cloud.cfg.d/)
provisioner "file" {
  source      = "cloud-init/99-custom.cfg"
  destination = "/etc/cloud/cloud.cfg.d/99-custom.cfg"
}

# Option 2: Bake the user-data into the image (for testing)
provisioner "file" {
  source      = "cloud-init/user-data"
  destination = "/var/lib/cloud/seed/nocloud/user-data"
}

provisioner "file" {
  source      = "cloud-init/meta-data"
  destination = "/var/lib/cloud/seed/nocloud/meta-data"
}

# Option 3: Reset cloud-init so it runs fresh on first boot
provisioner "shell" {
  inline = [
    "sudo cloud-init clean --logs",
    "sudo rm -rf /var/lib/cloud/instances/*"
  ]
}
```

```yaml
# /etc/cloud/cloud.cfg.d/99-custom.cfg
# This runs on every boot — careful with idempotency
cloud_config_modules:
  - emit_upstart
  - snap
  - ssh-import-id
  - keyboard
  - locale
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - rsyslog
  - ca-certs
  - resolv_conf
  - ntp
  - timezone
  - disable_ec2_metadata
  - runcmd
  - bootcmd

datasource_list: [NoCloud, EC2, ConfigDrive, None]

# Pin the datasource list to prevent probing delays
datasource:
  NoCloud:
    fs_label: cidata
  EC2:
    timeout: 10
    max_attempts: 3
```

### Creating Custom Images with Cloud-Init (QEMU)

For local testing with QEMU and NoCloud:

```bash
# Create cloud-init ISO for NoCloud
mkdir -p cloud-init
cat > cloud-init/user-data << 'EOF'
#cloud-config
package_update: true
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
EOF

cat > cloud-init/meta-data << 'EOF'
instance-id: local-dev-001
local-hostname: packer-test-vm
EOF

# Create ISO
genisoimage -output seed.iso -volid cidata -joliet -rock cloud-init/user-data cloud-init/meta-data
# OR
mkisofs -o seed.iso -V cidata -r -J cloud-init/user-data cloud-init/meta-data
```





[← Previous](05-5-provisioners.md) | [↑ Index](index.md) | [Next →](07-7-image-pipeline.md)
