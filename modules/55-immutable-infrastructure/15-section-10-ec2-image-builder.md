## Section 10: EC2 Image Builder and BuildKit/Kaniko

### EC2 Image Builder — AWS Managed Image Pipeline

Managed service to automate the creation, test, and distribution of AMIs.

```yaml
# Component definition (YAML)
name: HardeningComponent
schemaVersion: 1.0
phases:
  - name: build
    steps:
      - name: UpdatePackages
        action: ExecuteBash
        inputs:
          commands:
            - sudo apt update && sudo apt upgrade -y
      - name: InstallCISBenchmark
        action: ExecuteBash
        inputs:
          commands:
            - sudo apt install -y cis-benchmark
```

**Recipe**: document with source AMI + components + test suites → **Pipeline**: build, test, distribute, share.

### BuildKit — Next-Gen Docker Builder

Modern build engine (used by Docker since 23.0, also standalone).

```bash
# Build with BuildKit
DOCKER_BUILDKIT=1 docker build -t myapp:latest .

# Parallel builds, cache mounts, secrets
# --mount=type=cache,target=/root/.cache/go-build
# --mount=type=secret,id=token

# BuildKit standalone
buildctl build --frontend dockerfile.v0 \
  --local context=. --local dockerfile=.
```

### Kaniko — Build Containers in Kubernetes

Build container images without Docker daemon (runs in user space).

```yaml
# Kubernetes Job using Kaniko
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      args:
        - --dockerfile=Dockerfile
        - --destination=gcr.io/my-project/myapp:latest
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker/
  restartPolicy: Never
```
