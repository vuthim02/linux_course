## 💻 Level 1 Practices

### ✅ Practice 1: Your First Script

```bash
mkdir -p ~/linux-course/part6
cd ~/linux-course/part6

# Create and save this as hello.sh:
cat > hello.sh << 'EOF'
#!/bin/bash
echo "Hello, Linux SysAdmin!"
echo "Today is $(date)"
echo "You are logged in as $(whoami)"
EOF

chmod +x hello.sh
./hello.sh
```


### ✅ Practice 2: Variables

```bash
cd ~/linux-course/part6

cat > variables.sh << 'EOF'
#!/bin/bash
name="Alice"
age=30
hostname=$(hostname)

echo "Name: $name"
echo "Age: $age"
echo "Hostname: $hostname"
echo "Script: $0"
EOF

chmod +x variables.sh
./variables.sh
```


### ✅ Practice 3: User Input

```bash
cd ~/linux-course/part6

cat > greet.sh << 'EOF'
#!/bin/bash
read -p "What is your name? " name
read -p "How old are you? " age

echo "Hello, $name!"
echo "In 10 years you will be $((age + 10))."
EOF

chmod +x greet.sh
./greet.sh
```


### ✅ Practice 4: Conditionals

```bash
cd ~/linux-course/part6

cat > check_file.sh << 'EOF'
#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

file="$1"

if [ -f "$file" ]; then
    echo "$file exists and is a regular file."
    echo "Size: $(stat -c%s "$file") bytes"
elif [ -d "$file" ]; then
    echo "$file is a directory."
    echo "Contents: $(ls "$file" | wc -l) items"
elif [ -e "$file" ]; then
    echo "$file exists (but is not a regular file or directory)."
else
    echo "$file does not exist."
    exit 1
fi
EOF

chmod +x check_file.sh
./check_file.sh /etc/hosts
./check_file.sh /etc
./check_file.sh /nonexistent
```


### ✅ Practice 5: Command-Line Arguments

```bash
cd ~/linux-course/part6

cat > args_demo.sh << 'EOF'
#!/bin/bash

echo "Script: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "All args: $@"
echo "Arg count: $#"

echo ""
echo "Iterating through all arguments:"
count=1
for arg in "$@"; do
    echo "  Arg $count: $arg"
    ((count++))
done
EOF

chmod +x args_demo.sh
./args_demo.sh one two three four
```


# ⭐ Level 2: Intermediary — Control Flow and Data Structures

![Linux command-line in GNOME Terminal showing Bash](https://upload.wikimedia.org/wikipedia/commons/2/29/Linux_command-line._Bash._GNOME_Terminal._screenshot.png)
*Screenshot: Linux command line in GNOME Terminal. Credit: Wikimedia Commons user, GPL.*

> **Level 2 Goal:** Master loops, functions, exit codes, arrays, and file I/O to build reusable and data-processing scripts.




[← Previous](05-section-4-arguments-and-parameters.md) | [↑ Index](index.md) | [Next →](07-section-1-loops-doing-things.md)
