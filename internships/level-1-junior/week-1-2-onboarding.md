# Internship — Level 1, Week 1-2
## Employee Onboarding Script

### Real-World Scenario

Your company hires 5 new engineers this month. IT needs to create their Linux accounts, set up home directories, configure SSH access, and ensure consistent dotfiles. Currently this is done manually — error-prone and slow.

### Requirements

Write a bash script `/usr/local/bin/onboard-user.sh` that:

1. **Accepts arguments:**
   ```
   sudo ./onboard-user.sh --username jdoe --fullname "John Doe" --ssh-key "ssh-rsa AAAA..."
   ```

2. **Creates the user** with:
   - Home directory: `/home/jdoe`
   - Default shell: `/bin/bash`
   - Primary group: `staff`
   - Secondary groups: `sudo`, `docker` (if they exist)

3. **Configures the account:**
   - Copies skeleton files from `/etc/skel/`
   - Creates `.ssh/authorized_keys` with the provided SSH key (correct permissions: 700, 600)
   - Sets a random initial password (24 chars), prints it for the admin
   - Forces password change on first login (`chage -d 0`)

4. **Creates standard directories:**
   - `~/projects/`
   - `~/logs/`
   - `~/backups/`

5. **Logging:**
   - Logs every action to `/var/log/user-onboarding.log`
   - Format: `2026-06-24 14:30:01 | SUCCESS | Created user jdoe`
   - On failure: `2026-06-24 14:30:01 | ERROR | Failed to create home directory for jdoe`

6. **Error handling:**
   - Exit if not run as root
   - Exit if username already exists
   - Exit if SSH key is missing or invalid format
   - Use `set -euo pipefail`

7. **Bonus (optional):**
   - Send a Slack webhook notification on success
   - Generate a random avatar image (use `convert` from ImageMagick)

### Validation

```bash
# Test 1: Create a user
sudo ./onboard-user.sh --username testuser --fullname "Test User" --ssh-key "$(cat ~/.ssh/id_rsa.pub)"

# Test 2: Verify user exists
id testuser
# uid=1002(testuser) gid=50(staff) groups=50(staff),27(sudo)

# Test 3: Verify SSH key
sudo cat /home/testuser/.ssh/authorized_keys

# Test 4: Verify first login forces password change
sudo chage -l testuser | grep "Last password change"

# Test 5: Check log
tail -3 /var/log/user-onboarding.log
```

### Deliverables

- `~/internship/onboard-user.sh` — the script
- `~/internship/onboard-user.log` — test run output
- `~/internship/test-results.txt` — verification output

### Hints

- `getopt` or manual `case` for argument parsing
- `useradd -m -g staff -G sudo,docker -s /bin/bash "$USERNAME"`
- `openssl rand -base64 18` for random passwords
- `logger` or `tee -a` for logging
