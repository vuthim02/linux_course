## 3. Installing Docker

### Docker Engine (Ubuntu/Debian)

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt update
sudo apt install ca-certificates curl gnupg

# Add Docker's GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Docker Desktop

Docker Desktop runs a VM (Hyper-V/WSL2 on Windows, HyperKit on macOS, KVM on Linux). For Linux administration, **Docker Engine** is preferred — lighter, no GUI dependency.

### Configure dockerd

```json
// /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://mirror.gcr.io"],
  "insecure-registries": ["192.168.1.100:5000"],
  "default-address-pools": [
    {"base": "172.20.0.0/16", "size": 24}
  ]
}
```

```bash
# Apply config
sudo systemctl restart docker

# Check current config
docker info
```





[← Previous](05-2-docker-vs-podman.md) | [↑ Index](index.md) | [Next →](07-4-installing-podman.md)
