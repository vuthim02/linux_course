## 💻 PRACTICE SECTION — 15 Hands-On Exercises


### 📘 Level 1 Practices: Samba Installation and Basic Shares

Install Samba, explore the package structure, validate configuration with testparm, and create your first standalone share.

### ✅ Practice 1: Install Samba and Explore the Package

```bash
mkdir -p ~/linux-course/part29
cd ~/linux-course/part29

# Install Samba
sudo apt update
sudo apt install -y samba smbclient cifs-utils

# Verify installation
dpkg -l | grep samba
smbd --version
nmbd --version

# List all Samba binaries
dpkg -L samba-common | grep bin
ls /usr/sbin/smb*

# Check which services are available
systemctl list-unit-files | grep -i samba
systemctl list-unit-files | grep nmb
systemctl list-unit-files | grep winbind
```


### ✅ Practice 2: Explore Default smb.conf and testparm

```bash
cd ~/linux-course/part29

# Check the default configuration
cat /etc/samba/smb.conf

# Count lines, sections
grep '^\[.*\]$' /etc/samba/smb.conf
echo "---"
grep -c '^\[.*\]$' /etc/samba/smb.conf
echo "sections found"

# Validate with testparm
testparm -s 2>&1

# Output only the global parameters
testparm -s --parameter-name "workgroup" 2>/dev/null
testparm -s --parameter-name "server string" 2>/dev/null
testparm -s --parameter-name "security" 2>/dev/null

# Save the full verbose output
testparm -v 2>/dev/null > default_samba_params.txt
head -50 default_samba_params.txt
```


### ✅ Practice 3: Create a Simple Standalone Share


### 📘 Level 2 Practices: Client Tools, Mounting, Monitoring, and Domain Operations

Connect with smbclient, mount CIFS shares, set up user-level security, monitor connections with smbstatus, configure logging, and test SMB protocol versions.

```bash
cd ~/linux-course/part29

# 1. Create a directory for the share
sudo mkdir -p /srv/samba/labshare

# 2. Create some test files
echo "Welcome to the Samba lab share" | sudo tee /srv/samba/labshare/README.txt
sudo touch /srv/samba/labshare/{document1.txt,datafile.csv,report.pdf}

# 3. Set permissions
sudo chown -R nobody:nogroup /srv/samba/labshare
sudo chmod -R 0775 /srv/samba/labshare

# 4. Back up and create new smb.conf
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

sudo tee /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = WORKGROUP
   server string = Lab Samba Server
   netbios name = LABSERVER
   security = user
   map to guest = Bad User
   dns proxy = no
   log file = /var/log/samba/log.%m
   max log size = 1000

[labshare]
   comment = Lab Practice Share
   path = /srv/samba/labshare
   read only = no
   guest ok = yes
   browseable = yes
   create mask = 0644
   directory mask = 0755
EOF

# 5. Validate and restart
testparm -s
sudo systemctl restart smbd nmbd
sudo systemctl status smbd --no-pager -l
```


### ✅ Practice 4: Connect to Your Share with smbclient

```bash
cd ~/linux-course/part29

# 1. List shares on your own server
smbclient -L //127.0.0.1 -N -p 445

# 2. Connect interactively
smbclient //127.0.0.1/labshare -N

# Inside smbclient:
#   ls
#   get README.txt
#   put /etc/hostname hostname.txt
#   ls
#   exit

# 3. Scripted smbclient
smbclient //127.0.0.1/labshare -N -c '
   ls
   get README.txt
   put /etc/hostname labhostname.txt
   ls
   exit
'

# 4. Verify downloaded files
cat README.txt
cat labhostname.txt 2>/dev/null || echo "Check local directory"
```


### ✅ Practice 5: Set Up User-Level Security

```bash
cd ~/linux-course/part29

# 1. Create local users
sudo useradd -m -s /usr/sbin/nologin labuser1
sudo useradd -m -s /usr/sbin/nologin labuser2

# 2. Set SMB passwords
echo -e "Pass1234\nPass1234" | sudo smbpasswd -a labuser1 -s
echo -e "Pass5678\nPass5678" | sudo smbpasswd -a labuser2 -s

# 3. Verify users in pdbedit
sudo pdbedit -L

# 4. Create a secure share
sudo mkdir -p /srv/samba/secure
echo "Confidential data" | sudo tee /srv/samba/secure/secret.txt

# 5. Update smb.conf
sudo tee -a /etc/samba/smb.conf << 'EOF'

[secure]
   comment = Secure Share (Authorized Users Only)
   path = /srv/samba/secure
   valid users = labuser1
   read only = no
   browseable = no
   create mask = 0600
   directory mask = 0700
EOF

testparm -s

# 6. Set file system permissions
sudo chown -R root:labuser1 /srv/samba/secure
sudo chmod 2770 /srv/samba/secure

sudo systemctl restart smbd

# 7. Test access
echo "--- Testing labuser1 (should succeed) ---"
smbclient //127.0.0.1/secure -U labuser1%Pass1234 -c 'ls; get secret.txt; exit'

echo "--- Testing labuser2 (should fail) ---"
smbclient //127.0.0.1/secure -U labuser2%Pass5678 -c 'ls; exit' 2>&1
```


### ✅ Practice 6: Mount a CIFS Share on Linux

```bash
cd ~/linux-course/part29

# 1. Create mount point
sudo mkdir -p /mnt/labshare

# 2. Create a credentials file
sudo mkdir -p /etc/samba/credentials
sudo tee /etc/samba/credentials/labuser1.cred << 'EOF'
username=labuser1
password=Pass1234
domain=WORKGROUP
EOF

sudo chmod 600 /etc/samba/credentials/labuser1.cred

# 3. Mount the share
sudo mount -t cifs //127.0.0.1/secure /mnt/labshare \
   -o credentials=/etc/samba/credentials/labuser1.cred,uid=$(id -u),gid=$(id -g),iocharset=utf8,vers=3.0

# 4. Verify
mount -t cifs
df -h /mnt/labshare
ls -la /mnt/labshare

# 5. Write a file through the mount
echo "Written via CIFS mount at $(date)" > /mnt/labshare/test_write.txt
cat /mnt/labshare/test_write.txt

# 6. See it via smbclient
smbclient //127.0.0.1/secure -U labuser1%Pass1234 -c 'ls; exit'

# 7. Unmount
sudo umount /mnt/labshare
```


### ✅ Practice 7: Explore smbstatus and Connection Monitoring

```bash
cd ~/linux-course/part29

# 1. Open two terminals, or use background:
# Terminal 1: Keep a connection open
smbclient //127.0.0.1/labshare -N -c 'sleep 30; exit' &
SMBPID=$!

# 2. Check smbstatus while connected
sleep 2
smbstatus
smbstatus -p
smbstatus -S

# 3. Note the PID
echo "smbclient PID: $SMBPID"
ps aux | grep smb[c]lient

# 4. Find the smbd child handling it
ps aux | grep smbd

# 5. Close the connection
kill $SMBPID 2>/dev/null
sleep 1
smbstatus

# 6. Test lock display
# Create a lock scenario:
(echo "lock"; sleep 10; echo "release") | smbclient //127.0.0.1/labshare -N -c 'open README.txt; sleep 10; close; exit' &
sleep 3
smbstatus -L

wait
```


### ✅ Practice 8: Create Multiple Shares with Permission Masks

```bash
cd ~/linux-course/part29

# 1. Create department-style shares
sudo mkdir -p /srv/samba/{dept_a,dept_b,archive}
echo "Department A data" | sudo tee /srv/samba/dept_a/readme.txt
echo "Department B data" | sudo tee /srv/samba/dept_b/readme.txt
echo "Archive data" | sudo tee /srv/samba/archive/readme.txt

# 2. Create groups and users
sudo groupadd dept_a
sudo groupadd dept_b
sudo usermod -aG dept_a labuser1
sudo usermod -aG dept_b labuser2

# 3. Set filesystem permissions
sudo chown root:dept_a /srv/samba/dept_a
sudo chmod 2770 /srv/samba/dept_a
sudo chown root:dept_b /srv/samba/dept_b
sudo chmod 2770 /srv/samba/dept_b
sudo chown root:root /srv/samba/archive
sudo chmod 2775 /srv/samba/archive

# 4. Add share definitions
sudo tee /etc/samba/shares.conf << 'EOF'
[dept_a]
   comment = Department A
   path = /srv/samba/dept_a
   valid users = @dept_a
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = yes

[dept_b]
   comment = Department B
   path = /srv/samba/dept_b
   valid users = @dept_b
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = yes

[archive]
   comment = Shared Archive
   path = /srv/samba/archive
   valid users = @dept_a, @dept_b
   read only = yes
   browseable = yes
EOF

echo "include = /etc/samba/shares.conf" | sudo tee -a /etc/samba/smb.conf

testparm -s
sudo systemctl restart smbd

# 5. Test access
echo "--- Department A access ---"
smbclient //127.0.0.1/dept_a -U labuser1%Pass1234 -c 'ls; put /etc/hostname host_from_a.txt; ls; exit'

echo "--- Department B access (should fail for A) ---"
smbclient //127.0.0.1/dept_b -U labuser1%Pass1234 -c 'ls; exit' 2>&1

echo "--- Archive (read-only) ---"
smbclient //127.0.0.1/archive -U labuser1%Pass1234 -c 'ls; exit'
```


### ✅ Practice 9: Configure Samba Logging and Debugging

```bash
cd ~/linux-course/part29

# 1. Set log level for debugging
sudo tee /etc/samba/smb.conf.d/debug.conf << 'EOF'
[global]
   log level = 3 auth:5
   log file = /var/log/samba/log.%m
   max log size = 5000
EOF

echo "include = /etc/samba/smb.conf.d/debug.conf" | sudo tee -a /etc/samba/smb.conf

sudo systemctl restart smbd

# 2. Generate some log activity
smbclient //127.0.0.1/labshare -N -c 'ls; get README.txt; exit'

# 3. Examine logs
sudo ls -la /var/log/samba/
sudo cat /var/log/samba/log.127.0.0.1

# 4. Set logging back to normal
sudo sed -i 's/log level = 3 auth:5/log level = 1/' /etc/samba/smb.conf.d/debug.conf
sudo systemctl restart smbd
```


### ✅ Practice 10: SMB Protocol Version Testing


### 📘 Level 3 Practices: Advanced Features, Security, and Performance

Test file locking and oplocks, enable SMB encryption, benchmark Samba transfers, and build a mixed Linux/Windows file server integration project.

```bash
cd ~/linux-course/part29

# 1. Force SMB2 and test
sudo tee /etc/samba/smb.conf.d/protocol.conf << 'EOF'
[global]
   server min protocol = SMB2_02
   server max protocol = SMB3_11
   disable netbios = yes
   smb ports = 445
EOF

# include this in main config (check if not already there)
grep -q "protocol.conf" /etc/samba/smb.conf || \
   echo "include = /etc/samba/smb.conf.d/protocol.conf" | sudo tee -a /etc/samba/smb.conf

sudo systemctl restart smbd nmbd

# 2. Try SMB1 (should fail)
echo "--- Attempt SMB1 connection (should fail) ---"
smbclient -L //127.0.0.1 -m NT1 -N 2>&1 || echo "SMB1 correctly rejected"

# 3. Try modern protocols (should work)
echo "--- SMB2.02 ---"
smbclient -L //127.0.0.1 -m SMB2_02 -N 2>&1 | head -5

echo "--- SMB3.11 ---"
smbclient -L //127.0.0.1 -m SMB3_11 -N 2>&1 | head -5

# 4. Verify NetBIOS disabled (port 139)
ss -tlnp | grep -E ':139|:445'
echo "Port 139 should not be listening (NetBIOS disabled)"
```


### ✅ Practice 11: smbclient Advanced Operations

```bash
cd ~/linux-course/part29

# 1. Create a local test directory with files
mkdir -p smbclient_test
dd if=/dev/urandom bs=1M count=10 of=smbclient_test/largefile.bin 2>/dev/null
echo "small file content" > smbclient_test/small.txt
echo "another file" > smbclient_test/another.txt

# 2. Upload multiple files with mput
smbclient //127.0.0.1/labshare -N -c "
   lcd smbclient_test
   prompt OFF
   mput *
   ls
   exit
"

# 3. Download with mget
mkdir -p smbclient_download
smbclient //127.0.0.1/labshare -N -c "
   lcd smbclient_download
   prompt OFF
   mget *
   ls
   exit
"

# 4. Verify download
ls -la smbclient_download/

# 5. Use tar over smbclient
smbclient //127.0.0.1/labshare -N -c '
   tar c labshare_backup.tar
   ls *.tar
   exit
'

# 6. Recursive directory operations
smbclient //127.0.0.1/labshare -N -c '
   mkdir subdir1
   cd subdir1
   mkdir subdir2
   cd subdir2
   put /etc/hostname nested_test.txt
   recurse ON
   ls
   exit
'
```


### ✅ Practice 12: Test File Locking and Oplocks

```bash
cd ~/linux-course/part29

# 1. Configure oplocks on the share
sudo tee /etc/samba/smb.conf.d/locks.conf << 'EOF'
[global]
   kernel oplocks = yes
   lock spin count = 10
   lock spin time = 100

[labshare]
   oplocks = yes
   level2 oplocks = yes
   blocking locks = yes
EOF

grep -q "locks.conf" /etc/samba/smb.conf || \
   echo "include = /etc/samba/smb.conf.d/locks.conf" | sudo tee -a /etc/samba/smb.conf

sudo systemctl restart smbd

# 2. Create a test file
echo "Lock test content" > /tmp/lock_test.txt
smbclient //127.0.0.1/labshare -N -c "put /tmp/lock_test.txt lock_test.txt; exit"

# 3. Open in one session with a hold
smbclient //127.0.0.1/labshare -N -c '
   open lock_test.txt
   sleep 15
   close
   exit
' &

sleep 3

# 4. Try to open the same file from another session
echo "--- Second session attempting to open locked file ---"
smbclient //127.0.0.1/labshare -N -c '
   open lock_test.txt
   ls
   exit
' &

sleep 5
smbstatus -L

wait
```


### ✅ Practice 13: Test SMB Encryption

```bash
cd ~/linux-course/part29

# 1. Enable encryption on the labshare
sudo tee /etc/samba/smb.conf.d/encrypt.conf << 'EOF'
[global]
   server smb encrypt = desired

[labshare]
   smb encrypt = required
EOF

grep -q "encrypt.conf" /etc/samba/smb.conf || \
   echo "include = /etc/samba/smb.conf.d/encrypt.conf" | sudo tee -a /etc/samba/smb.conf

testparm -s
sudo systemctl restart smbd

# 2. Connect and check encryption status
smbclient //127.0.0.1/labshare -N -c 'ls; exit'

# 3. Check smbstatus for encryption column
smbstatus | grep -i encrypt

# 4. Mount with encryption requirement
sudo mount -t cifs //127.0.0.1/labshare /mnt/labshare \
   -o guest,vers=3.0,seal
# seal = require encryption at SMB3 level

mount -t cifs
sudo umount /mnt/labshare
```


### ✅ Practice 14: Benchmark Samba Transfers

```bash
cd ~/linux-course/part29

# 1. Create a large test file
dd if=/dev/zero of=/tmp/benchmark_test.dat bs=1M count=100 2>/dev/null

# 2. Upload timing
echo "--- Upload benchmark ---"
time smbclient //127.0.0.1/labshare -N -c "put /tmp/benchmark_test.dat benchmark.dat; exit"

# 3. Download timing (different file name to avoid cache)
smbclient //127.0.0.1/labshare -N -c "put /tmp/benchmark_test.dat download_test.dat; exit"
echo "--- Download benchmark ---"
time smbclient //127.0.0.1/labshare -N -c "get download_test.dat /dev/null; exit"

# 4. Compare SMB versions
echo "--- SMB2.02 upload ---"
time smbclient //127.0.0.1/labshare -N -m SMB2_02 -c "put /tmp/benchmark_test.dat smb2_bench.dat; exit"

echo "--- SMB3.11 upload ---"
time smbclient //127.0.0.1/labshare -N -m SMB3_11 -c "put /tmp/benchmark_test.dat smb3_bench.dat; exit"

# 5. Clean up test files
smbclient //127.0.0.1/labshare -N -c '
   rm benchmark.dat
   rm download_test.dat
   rm smb2_bench.dat
   rm smb3_bench.dat
   ls
   exit
'

rm -f /tmp/benchmark_test.dat
```


### ✅ Practice 15: Real-World Integration — Mixed Linux/Windows File Server

```bash
cd ~/linux-course/part29

# Build a complete, production-style file server configuration

# 1. Create directory structure
sudo mkdir -p /srv/samba/{profiles,home,groups/{sales,engineering,exec},public}
sudo mkdir -p /srv/samba/groups/sales/{invoices,reports,archive}
sudo mkdir -p /srv/samba/groups/engineering/{designs,specs,builds}
sudo mkdir -p /srv/samba/exec/confidential
sudo mkdir -p /srv/samba/public/software
sudo mkdir -p /srv/samba/profiles/{sales_vp,engineer_lead}

# 2. Create groups and users
sudo groupadd --gid 5000 sales
sudo groupadd --gid 5001 engineering
sudo groupadd --gid 5002 execs

for user in alice bob charlie dave eve; do
    sudo useradd -m -s /usr/sbin/nologin -g users -G users "$user"
    echo -e "Pass1234\nPass1234" | sudo smbpasswd -a "$user" -s
done

sudo usermod -aG sales alice
sudo usermod -aG sales bob
sudo usermod -aG engineering charlie
sudo usermod -aG engineering dave
sudo usermod -aG execs eve
sudo usermod -aG sales eve  # Exec can see sales too

# 3. Set filesystem permissions
sudo chown root:sales /srv/samba/groups/sales
sudo chmod 2770 /srv/samba/groups/sales

sudo chown root:engineering /srv/samba/groups/engineering
sudo chmod 2770 /srv/samba/groups/engineering

sudo chown root:execs /srv/samba/exec
sudo chmod 2770 /srv/samba/exec

sudo chown root:users /srv/samba/public
sudo chmod 2775 /srv/samba/public

sudo chown eve:execs /srv/samba/exec/confidential
sudo chmod 2770 /srv/samba/exec/confidential

# 4. Create sample files
echo "Q4 Financial Report (Draft)" | sudo tee /srv/samba/groups/sales/reports/q4_draft.txt
echo "Server Design v2.1" | sudo tee /srv/samba/groups/engineering/designs/server_v2.txt
echo "Board Meeting Minutes" | sudo tee /srv/samba/exec/confidential/board_minutes.txt
echo "Public Software Release" | sudo tee /srv/samba/public/software/readme.txt

# 5. Write the production config
sudo tee /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = COMPANY
   server string = Production File Server
   netbios name = FILESRV
   security = user
   map to guest = Never
   dns proxy = no

   # Performance
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE
   read raw = yes
   write raw = yes
   strict allocate = no
   use mmap = yes
   getwd cache = yes

   # Security
   server min protocol = SMB2_10
   server smb encrypt = desired
   client signing = required
   disable netbios = yes
   smb ports = 445

   # Logging
   log level = 1
   log file = /var/log/samba/log.%m
   max log size = 5000

[homes]
   comment = Home Directories
   browseable = no
   read only = no
   create mask = 0700
   directory mask = 0700
   valid users = %S

[sales]
   comment = Sales Department
   path = /srv/samba/groups/sales
   valid users = @sales
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = yes
   veto files = /Thumbs.db/.DS_Store/
   hide unreadable = yes

[engineering]
   comment = Engineering Department
   path = /srv/samba/groups/engineering
   valid users = @engineering
   read only = no
   create mask = 0664
   directory mask = 0775
   browseable = yes
   veto files = /Thumbs.db/.DS_Store/

[exec]
   comment = Executive
   path = /srv/samba/exec
   valid users = @execs
   read only = no
   create mask = 0660
   directory mask = 0770
   browseable = no

[public]
   comment = Company Public Files
   path = /srv/samba/public
   guest ok = yes
   read only = yes
   browseable = yes
   create mask = 0644
   directory mask = 0755
EOF

# 6. Validate
testparm -s

# 7. Restart
sudo systemctl restart smbd

# 8. Test all shares
echo "=== Testing All Shares ==="
echo ""

echo "--- Sales (alice) ---"
smbclient //127.0.0.1/sales -U alice%Pass1234 -c 'ls; cd reports; ls; exit'

echo "--- Engineering (charlie) ---"
smbclient //127.0.0.1/engineering -U charlie%Pass1234 -c 'ls; cd designs; ls; exit'

echo "--- Engineering for sales user (should fail) ---"
smbclient //127.0.0.1/engineering -U alice%Pass1234 -c 'ls; exit' 2>&1

echo "--- Exec (eve) ---"
smbclient //127.0.0.1/exec -U eve%Pass1234 -c 'ls; cd confidential; ls; get board_minutes.txt; exit'

echo "--- Public (anonymous) ---"
smbclient //127.0.0.1/public -N -c 'ls; cd software; ls; exit'

# 9. Check smbstatus
echo ""
echo "=== Active Connections ==="
smbstatus

# 10. Create a summary report
{
    echo "============================================"
    echo "  SAMBA INTEGRATION PRACTICE REPORT"
    echo "  $(date)"
    echo "============================================"
    echo ""
    echo "Server: $(hostname)"
    echo "Samba version: $(smbd --version 2>&1)"
    echo ""
    echo "Shares configured:"
    smbclient -L //127.0.0.1 -U alice%Pass1234 2>/dev/null | grep -E '^\t' | grep -v '^$'
    echo ""
    echo "Users with SMB access:"
    sudo pdbedit -L 2>/dev/null
    echo ""
    echo "Active connections:"
    smbstatus -p 2>/dev/null
    echo ""
    echo "Check: testparm validation"
    testparm -s 2>&1 | grep -E "Loaded|Processing"
    echo "============================================"
} | tee integration_report.txt

echo ""
echo "Practice 15 complete — integration report saved to integration_report.txt"
```





[← Previous](16-section-12-performance-tuning.md) | [↑ Index](index.md) | [Next →](18-deep-understanding-how-smbcifs-really.md)
