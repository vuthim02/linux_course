## 💻 Level 4 — Mastery Practices

### ✅ Practice 1: Systemd Drop-in Override

```bash
cd ~/linux-course/part12

# 1. Create a drop-in to add memory limit to cron
sudo mkdir -p /etc/systemd/system/cron.service.d

# 2. Add resource limits
sudo tee /etc/systemd/system/cron.service.d/limits.conf << 'EOF'
[Service]
MemoryMax=256M
CPUQuota=50%
Restart=always
RestartSec=10
EOF

# 3. Reload and verify
sudo systemctl daemon-reload
systemctl cat cron
systemd-delta

# 4. Clean up
sudo rm -r /etc/systemd/system/cron.service.d/
sudo systemctl daemon-reload
```

### ✅ Practice 2: Create a Path-Triggered Service

```bash
cd ~/linux-course/part12

# 1. Watch directory
sudo mkdir -p /opt/incoming
sudo chmod 777 /opt/incoming

# 2. Path unit
sudo tee /etc/systemd/system/process-incoming.path << 'EOF'
[Unit]
Description=Watch incoming directory

[Path]
PathChanged=/opt/incoming
Unit=process-incoming.service

[Install]
WantedBy=multi-user.target
EOF

# 3. Service unit
sudo tee /etc/systemd/system/process-incoming.service << 'EOF'
[Unit]
Description=Process incoming files

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Files in incoming:"; ls /opt/incoming | systemd-cat -t incoming'
EOF

# 4. Enable and test
sudo systemctl daemon-reload
sudo systemctl enable --now process-incoming.path
touch /opt/incoming/test.txt
sleep 2
journalctl -t incoming -n 5

# 5. Clean up
sudo systemctl disable --now process-incoming.path
sudo rm /etc/systemd/system/process-incoming.{path,service}
sudo systemctl daemon-reload
```

### ✅ Practice 3: User Service

```bash
cd ~/linux-course/part12

# 1. Enable lingering
sudo loginctl enable-linger $USER

# 2. Create user service directory
mkdir -p ~/.config/systemd/user

# 3. Create a user timer service
cat > ~/.config/systemd/user/hello-user.service << 'EOF'
[Unit]
Description=Hello User Service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Hello from user service at $(date)"'
EOF

cat > ~/.config/systemd/user/hello-user.timer << 'EOF'
[Unit]
Description=Run hello every minute

[Timer]
OnCalendar=*-*-* *:*:00
Persistent=true

[Install]
WantedBy=default.target
EOF

# 4. Enable and start
systemctl --user daemon-reload
systemctl --user enable --now hello-user.timer
systemctl --user list-timers

# 5. Check it ran
sleep 70
journalctl --user -u hello-user -n 5

# 6. Clean up
systemctl --user disable --now hello-user.timer
rm ~/.config/systemd/user/hello-user.{service,timer}
systemctl --user daemon-reload
```

### ✅ Practice 4: systemd-analyze verify

```bash
cd ~/linux-course/part12

# 1. Create a broken service
cat > broken.service << 'EOF'
[Unit]
Description=Broken service example

[Service]
ExecStart=myapp      # Missing full path!
Type=invalid         # Invalid type!

[Install]
WantedBy=multi
EOF

# 2. Check it
systemd-analyze verify broken.service
echo "Exit code: $?"

# 3. Create a working service and verify
cat > working.service << 'EOF'
[Unit]
Description=Working service

[Service]
Type=oneshot
ExecStart=/bin/true

[Install]
WantedBy=multi-user.target
EOF

systemd-analyze verify working.service
echo "Exit code: $?"
```

### ✅ Practice 5: systemd-run Transient Units

```bash
cd ~/linux-course/part12

# 1. Run a command with memory limit
sudo systemd-run -u transient-test \
  -p MemoryMax=50M \
  -- /bin/bash -c 'echo "Running with 50M limit"; sleep 3; echo "Done"'

# 2. Check status
systemctl status transient-test

# 3. Check journal
journalctl -u transient-test -n 10

# 4. Run a recurring task with systemd-run timer
systemd-run --user --on-calendar="minutely" \
  --unit=minute-task \
  -- /bin/bash -c 'echo "Minute task at $(date)"'

sleep 70
journalctl --user -u minute-task -n 3

# 5. Clean up
systemctl --user stop minute-task.timer 2>/dev/null || true
```

### ✅ Practice 6: systemd-analyze Deep Dive

```bash
cd ~/linux-course/part12

# 1. Generate boot plot
systemd-analyze plot > boot.svg
echo "Boot plot saved (open in browser)"

# 2. Conditional chain with blame
echo "=== Slowest services ==="
systemd-analyze blame | head -10

echo ""
echo "=== Critical chain ==="
systemd-analyze critical-chain

# 3. Check if there are security issues
systemd-analyze security
# Shows exposure level for each service
# Higher exposure = more permissive service config

# 4. Security of a specific service
systemd-analyze security sshd
echo "Lower score = better security"
```



[← Previous](26-section-17-tmpfiles-and-analyze.md) | [↑ Index](index.md) | [Next →](22-rules-of-thumb.md)
