## 19. Self-Test

### Questions

**1.** What syscall creates Linux namespaces?
a) fork()
b) clone() with namespace flags
c) exec()
d) open()

**2.** Which namespace is NOT isolated by default in Docker containers?
a) PID
b) Network
c) User
d) Mount

**3.** What does `overlay2` use for copy-on-write?
a) Btrfs snapshots
b) Upper directory
c) Device mapper
d) ZFS clones

**4.** What is the key architectural difference between Docker and Podman?
a) Docker uses runc, Podman uses crun
b) Docker uses a daemon; Podman forks directly
c) Docker is rootless by default
d) Podman cannot run containers

**5.** Which directive in a Dockerfile sets the default command that CAN be overridden?
a) ENTRYPOINT
b) CMD
c) RUN
d) START

**6.** What does `docker compose down -v` do?
a) Stop and remove containers, networks, and volumes
b) Only stop containers
c) Remove images
d) Delete Docker Compose binary

**7.** What is the purpose of `/etc/subuid`?
a) Map host UIDs to container UIDs for rootless
b) Configure Docker subnet
c) Set user limits
d) Define container capabilities

**8.** Which flag makes a container's filesystem read-only?
a) `--read-only`
b) `--no-write`
c) `--immutable`
d) `--frozen`

**9.** What does the `USER` instruction in a Dockerfile do?
a) Sets the username for the container hostname
b) Sets the user for RUN, CMD, and ENTRYPOINT
c) Creates a new user
d) Restricts SSH access

**10.** In a multi-stage build, what does `COPY --from=builder` do?
a) Copies files from the builder stage to the final stage
b) Copies from the host filesystem
c) Downloads from a URL
d) Extracts a tar archive

**11.** What is `slirp4netns` used for?
a) Rootless container networking
b) Container image compression
c) Log rotation
d) Volume encryption

**12.** What does `--cap-drop ALL` in Docker do?
a) Removes all Linux capabilities
b) Drops all network traffic
c) Removes all volumes
d) Stops all containers

**13.** Which port does a local Docker registry listen on by default?
a) 80
b) 443
c) 5000
d) 8080

**14.** What is the OCI runtime used by Podman by default on modern systems?
a) runc
b) crun
c) containerd
d) docker-shim

**15.** What happens when a file is deleted from a container that exists in a lower overlay layer?
a) The file is erased from all layers
b) A whiteout file is created in the upper layer
c) The layer is rebuilt
d) The file becomes read-only

### Answers

1. **b** — `clone()` with flags like `CLONE_NEWPID`, `CLONE_NEWNET`
2. **c** — User namespace is NOT isolated by default (unless `--userns-remap` or rootless)
3. **b** — Upper directory holds new/changed files; lower layers are read-only
4. **b** — Docker uses dockerd daemon; Podman forks child processes directly
5. **b** — `CMD` can be overridden; `ENTRYPOINT` replaces
6. **a** — `down -v` stops and removes containers, networks, AND volumes
7. **a** — Maps host UID ranges to container UIDs for rootless operation
8. **a** — `--read-only` makes the container's filesystem read-only
9. **b** — Sets the user for subsequent `RUN`, `CMD`, and `ENTRYPOINT` instructions
10. **a** — Copies artifacts from a named build stage to the final image
11. **a** — Userspace NAT networking for rootless containers
12. **a** — Drops all Linux kernel capabilities from the container
13. **c** — Default registry port is 5000
14. **b** — crun (C implementation, faster than runc)
15. **b** — A character device whiteout `0:0` is created in the upper layer

**Score:** 12/15 correct = ready for Part 39.


```
*Previous → Part 37: Automation with Ansible*
*Next → Part 39: Web Servers — Apache and Nginx*
```

[← Previous](part37.md) | [Next →](part39.md)



[← Previous](23-18-whats-coming-in-part.md) | [↑ Index](index.md)
