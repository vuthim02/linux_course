## 💻 PRACTICE SECTION — 20 Hands-On Exercises

> Type every command yourself. Create a practice user to avoid affecting real accounts.

### Level 1 Practices — Permission Fundamentals

---

### ✅ Practice 1: Read Permission Strings

```bash
cd /tmp && mkdir -p perm_practice && cd perm_practice

# Create some test files
touch file1.txt file2.sh
mkdir dir1

# Give them different permissions
chmod 644 file1.txt
chmod 755 file2.sh
chmod 700 dir1

ls -la

# For each file, write down:
# - What is the file type?
# - What can the owner do?
# - What can the group do?
# - What can others do?
```

---

### ✅ Practice 2: Experiment with Permissions

```bash
cd /tmp/perm_practice

# Remove read permission from a file
chmod 200 test.txt
cat test.txt         # What happens?

# Add read back
chmod 400 test.txt
cat test.txt         # Now?

# Remove execute from a directory
chmod 644 dir1
ls dir1              # Can you list it?
cd dir1              # Can you enter it?
```

---

### ✅ Practice 3: Permission Conversion Drills

Convert these manually, then verify with `chmod`:

```bash
# Symbolic to Numeric
# u=rwx,g=rx,o=   =  ?
# u=rw,g=r,o=r    =  ?
# u=rwx,g=rwx,o=  =  ?

# Numeric to Symbolic
# 751 = ?
# 640 = ?
# 555 = ?

# Test your answers:
touch test_perm
chmod 751 test_perm
ls -l test_perm
```

---

### ✅ Practice 4: Directory vs File Permissions

```bash
cd /tmp/perm_practice

mkdir dir_test
cd dir_test
touch secret.txt

# Go back and remove execute from parent
cd ..
chmod 644 dir_test
ls -l dir_test       # Can you see files?
ls dir_test          # Can you list them?
cat dir_test/secret.txt  # Can you read the file?

# Now add execute back
chmod 755 dir_test
cat dir_test/secret.txt  # Works now?

# Conclusion: x on directory is essential
```

---

### ✅ Practice 5: Create Practice Users

```bash
# Create two practice users
sudo useradd -m -s /bin/bash student1
sudo useradd -m -s /bin/bash student2

# Set passwords
echo "student1:password123" | sudo chpasswd
echo "student2:password123" | sudo chpasswd

# Verify
id student1
id student2
```

---

### ✅ Practice 6: Test File Isolation

```bash
# As student1, create a file
sudo -u student1 bash -c 'echo "Secret data" > /tmp/student1_file.txt'
sudo -u student1 bash -c 'chmod 600 /tmp/student1_file.txt'

# As student2, try to read it
sudo -u student2 bash -c 'cat /tmp/student1_file.txt'
# Should fail — Permission denied

# As student1, allow student2 to read it
sudo -u student1 bash -c 'chmod 644 /tmp/student1_file.txt'

# As student2, try again
sudo -u student2 bash -c 'cat /tmp/student1_file.txt'
# Should work now
```

---

### ✅ Practice 7: Read /etc/passwd and /etc/shadow

```bash
# Anatomy of /etc/passwd
head -5 /etc/passwd
tail -5 /etc/passwd

# Count total users
wc -l /etc/passwd

# Count regular users (UID >= 1000)
awk -F: '$3 >= 1000 {print $1}' /etc/passwd | wc -l

# Try reading shadow without sudo
cat /etc/shadow    # Permission denied

# Read with sudo
sudo head -5 /etc/shadow
```

---

### ✅ Practice 8: Explore /etc/skel

```bash
# See skeleton directory
ls -la /etc/skel/

# Create a new user and see their home
sudo useradd -m testuser
ls -la /home/testuser/
# Notice: same files as /etc/skel/

# Clean up
sudo userdel -r testuser
```

---

### Level 2 Practices — User & Group Administration

---

### ✅ Practice 9: Create Users with Specific Settings

```bash
# Create a user with custom UID, group, and settings
sudo groupadd developers
sudo useradd -u 3000 -g developers -G sudo -c "John Developer" -m -s /bin/bash johnd

# Verify
id johnd
# uid=3000(johnd) gid=3001(developers) groups=3001(developers),27(sudo)

grep johnd /etc/passwd
grep johnd /etc/shadow
```

---

### ✅ Practice 10: Lock and Unlock Users

```bash
# Lock the user
sudo passwd -l johnd

# Verify in shadow
sudo grep johnd /etc/shadow
# Notice the ! prefix on the password hash

# Try to switch to the user (should fail)
sudo -u johnd whoami

# Unlock
sudo passwd -u johnd

# Now it works
sudo -u johnd whoami
```

---

### ✅ Practice 11: Force Password Change on Next Login

```bash
# Expire password
sudo passwd -e johnd

# Check status
sudo passwd -S johnd

# When johnd logs in next, they will be forced to change password
```

---

### ✅ Practice 12: Modify a User

```bash
# Add johnd to more groups
sudo usermod -aG docker johnd
id johnd
# Notice docker group added

# Change description
sudo usermod -c "John Developer (Senior)" johnd
grep johnd /etc/passwd

# Change shell
sudo usermod -s /bin/zsh johnd
grep johnd /etc/passwd
```

---

### ✅ Practice 13: Group Management

```bash
# Create groups
sudo groupadd project-alpha
sudo groupadd project-beta

# Add members
sudo gpasswd -a student1 project-alpha
sudo gpasswd -a student2 project-beta
sudo gpasswd -a student1 project-beta

# Check membership
grep project-alpha /etc/group
grep project-beta /etc/group

# See member's groups
groups student1
groups student2
```

---

### ✅ Practice 14: Explore chown and chgrp

```bash
cd /tmp/perm_practice

# Create a file as your normal user
touch owned_by_me.txt
ls -l owned_by_me.txt

# Change group (works because you own it)
chgrp student1 owned_by_me.txt
ls -l owned_by_me.txt

# Try to change owner to someone else (should fail)
chown student2 owned_by_me.txt
# chown: changing ownership of 'owned_by_me.txt': Operation not permitted

# Use sudo (works)
sudo chown student2 owned_by_me.txt
ls -l owned_by_me.txt
```

---

### Level 3 Practices — Advanced Access Control

---

### ✅ Practice 15: SUID Exploration

```bash
# Find all SUID binaries on your system
find /usr/bin /usr/sbin -perm -4000 -type f 2>/dev/null

# Look at passwd specifically
ls -l /usr/bin/passwd
# Notice the 's' in owner position

# See how SUID works
echo "My uid is: $(id -u)"
# Now run passwd — it needs to write to /etc/shadow as root
# The SUID bit makes this possible
```

---

### ✅ Practice 16: SGID on Directories

```bash
cd /tmp/perm_practice

# Create a shared directory with SGID
sudo mkdir sgid_test
sudo chgrp project-alpha sgid_test
sudo chmod g+s sgid_test
sudo chmod 770 sgid_test

# As student1, create a file inside
sudo -u student1 touch sgid_test/file_from_student1.txt
ls -l sgid_test/
# Notice: group is 'project-alpha', NOT student1's primary group

# As student2, can they write?
sudo -u student2 touch sgid_test/file_from_student2.txt
ls -l sgid_test/
```

---

### ✅ Practice 17: Sticky Bit Demo

```bash
cd /tmp

# Create a shared directory without sticky bit
mkdir nosticky
chmod 777 nosticky

# As student1, create a file
sudo -u student1 touch nosticky/student1.txt

# As student2, try to delete student1's file
sudo -u student2 rm nosticky/student1.txt
# This WORKS — anyone can delete anyone's files in world-writable dirs

# Now create with sticky bit
mkdir withsticky
chmod 1777 withsticky

# As student1, create a file
sudo -u student1 touch withsticky/student1.txt

# As student2, try to delete it
sudo -u student2 rm withsticky/student1.txt
# This FAILS — sticky bit protects it
```

---

### ✅ Practice 18: umask Experiments

```bash
cd /tmp/perm_practice

# Check current umask
umask

# Create a file with default umask
touch default_perm.txt
ls -l default_perm.txt

# Change umask and create another
umask 0077
touch private.txt
ls -l private.txt

umask 0002
touch shared.txt
ls -l shared.txt

# Restore normal
umask 0022
```

---

### ✅ Practice 19: ACL Practice

```bash
cd /tmp/perm_practice

# Create a file
touch acl_test.txt
chmod 640 acl_test.txt
ls -l acl_test.txt    # No + yet

# Give student1 specific access
setfacl -m u:student1:rwx acl_test.txt
ls -l acl_test.txt    # + appears!

# View the ACL
getfacl acl_test.txt

# Test as student1
sudo -u student1 bash -c 'echo "ACL works!" >> /tmp/perm_practice/acl_test.txt'
sudo -u student1 bash -c 'cat /tmp/perm_practice/acl_test.txt'
```

---

### ✅ Practice 20: Real SysAdmin Scenario — Setting Up a Shared Project Directory

```bash
# Create the project directory structure
sudo mkdir -p /srv/projects/alpha/{src,logs,docs,backup}
sudo chown -R root:project-alpha /srv/projects/alpha

# Set permissions: owner and group full access, others nothing
sudo chmod -R 770 /srv/projects/alpha

# Set SGID so all files inherit group
sudo chmod g+s /srv/projects/alpha

# Set default ACL so new files also get the right permissions
sudo setfacl -Rdm g:project-alpha:rwx /srv/projects/alpha
sudo setfacl -Rm g:project-alpha:rwx /srv/projects/alpha

# Give a specific user (not in group) access
sudo setfacl -Rm u:student1:rx /srv/projects/alpha

# Verify everything
ls -la /srv/projects/alpha
getfacl /srv/projects/alpha

# Test as different users
sudo -u student1 touch /srv/projects/alpha/src/test.txt
sudo -u student2 ls /srv/projects/alpha/src
```

---



---

[← Previous](18-section-14-the-complete-permission.md) | [↑ Index](index.md) | [Next →](20-deep-understanding-how-permissions-really.md)
