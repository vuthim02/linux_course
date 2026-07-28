## 🔍 Section 11: Provisioners

### What Are Provisioners?

Provisioners run scripts on resources after creation:

- **`file`** — Upload files to the resource
- **`remote-exec`** — Run commands on the resource (via SSH/WinRM)
- **`local-exec`** — Run commands on the machine running Terraform

### file Provisioner

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  provisioner "file" {
    source      = "${path.module}/scripts/setup.sh"
    destination = "/home/ubuntu/setup.sh"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}
```

### remote-exec Provisioner

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}
```

### local-exec Provisioner

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}

resource "null_resource" "post_deploy" {
  depends_on = [aws_instance.web]

  provisioner "local-exec" {
    command = <<EOF
      echo "Instance ${aws_instance.web.id} created at ${aws_instance.web.public_ip}" >> /var/log/deployments.log
      curl -X POST https://hooks.slack.com/services/T... \
        -H 'Content-Type: application/json' \
        -d '{"text":"EC2 instance ${aws_instance.web.id} deployed!"}'
    EOF
  }
}
```

### Why Provisioners Are a Last Resort

HashiCorp explicitly recommends against provisioners. Why?

1. **Not idempotent** — Running `apply` again doesn't re-run provisioners (unless you taint the resource)
2. **Stateful** — Provisioners run on create, not on update; if you change the script, Terraform won't re-run it
3. **Slow** — SSH/WinRM connections are slow and unreliable
4. **Hard to debug** — Errors are hard to reproduce
5. **Config management exists** — Use **Ansible, Chef, Puppet, Salt** for post-deployment config, or better yet, use **userdata/cloud-init**

**Better approach: cloud-init userdata**:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF
}
```

**Even better: packer image + immutable infrastructure**:

```hcl
# Pre-bake the AMI with Packer, then just reference it
resource "aws_instance" "web" {
  ami           = data.aws_ami.my_app_ami.id
  instance_type = "t3.micro"
  # No provisioners needed — everything is in the AMI
}
```

When you absolutely must use a provisioner, use `on_failure` and `when`:

```hcl
provisioner "remote-exec" {
  when        = destroy         # Run on destroy instead of create
  on_failure  = continue        # Don't fail if the script fails
  inline = ["sudo shutdown -h now"]
}
```





[← Previous](11-section-10-workspaces.md) | [↑ Index](index.md) | [Next →](13-section-12-terraform-cloud-enterprise.md)
