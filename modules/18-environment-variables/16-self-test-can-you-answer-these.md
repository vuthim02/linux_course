## 📝 Self-Test — Can You Answer These?

1. How do you list all environment variables?
2. What is the difference between `VAR=value` and `export VAR=value`?
3. What does the PATH variable do and how is it searched?
4. Name the four main shell startup files and when each is read.
5. What is the practical difference between `~/.bash_profile` and `~/.bashrc`?
6. What is an alias and how do you create one permanently?
7. How is a shell function different from an alias?
8. What does `PS1` control and give an example with color.
9. How do you add a directory to PATH for the current session?
10. How do you remove an environment variable?
11. How do you run a command with a variable set only for that command?
12. What is the `env -i` command used for?
13. How can a child process access parent's variables?
14. What does `locale -a` show?
15. Where would you add a system-wide environment variable?

**Score:** 12/15 correct = ready for Part 19.


## Answer Key

### Q1: How do you list all environment variables?
**Answer:** `env` or `printenv` — shows all exported variables and their values.

### Q2: What is the difference between `VAR=value` and `export VAR=value`?
**Answer:** `VAR=value` sets a variable only in the current shell. `export VAR=value` makes it available to child processes.

### Q3: What does the PATH variable do and how is it searched?
**Answer:** PATH is a colon-separated list of directories. The shell searches left-to-right for executable commands. First match wins.

### Q4: Name the four main shell startup files and when each is read.
**Answer:** `~/.bash_profile` (login shell, interactive), `~/.bashrc` (non-login interactive), `~/.bash_logout` (login shell exit), `/etc/profile` (system-wide login).

### Q5: What is the practical difference between `~/.bash_profile` and `~/.bashrc`?
**Answer:** `.bash_profile` runs once at login (SSH, console). `.bashrc` runs for every new terminal. Usually `.bash_profile` sources `.bashrc`.

### Q6: What is an alias and how do you create one permanently?
**Answer:** An alias is a shortcut for a command. Add to `~/.bashrc`: `alias ll='ls -la'`. Run `source ~/.bashrc` to apply.

### Q7: How is a shell function different from an alias?
**Answer:** An alias only does simple text substitution. A function can have arguments, control flow, variables, and complex logic.

### Q8: What does `PS1` control and give an example with color?
**Answer:** PS1 is the primary shell prompt. Example: `PS1='\[\e[1;32m\]\u@\h:\w\$\[\e[0m\] '` (green user@host:dir$).

### Q9: How do you add a directory to PATH for the current session?
**Answer:** `export PATH="/new/dir:$PATH"` — prepends the directory so it's searched first.

### Q10: How do you remove an environment variable?
**Answer:** `unset VAR_NAME` — removes the variable from the current shell and its children.

### Q11: How do you run a command with a variable set only for that command?
**Answer:** `VAR=value command` — sets VAR only for the duration of that command's execution.

### Q12: What is the `env -i` command used for?
**Answer:** Runs a command with a completely clean environment (no inherited variables). E.g., `env -i /bin/bash`.

### Q13: How can a child process access parent's variables?
**Answer:** Via `export`. A parent must `export` a variable for its children (and their children) to see it.

### Q14: What does `locale -a` show?
**Answer:** Lists all available locales installed on the system.

### Q15: Where would you add a system-wide environment variable?
**Answer:** `/etc/environment` or `/etc/profile.d/custom.sh` — affects all users at login.


*Linux SysAdmin Course | Part 18 of ∞ | Reverse Engineering Approach*
*Previous → Part 17: SELinux and AppArmor*
*Next → Part 19: Software Repositories and PPAs*

[← Previous](part17.md) | [Next →](part19.md)



[← Previous](15-whats-coming-in-part-19.md) | [↑ Index](index.md)
