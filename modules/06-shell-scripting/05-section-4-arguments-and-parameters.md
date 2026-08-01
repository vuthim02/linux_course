## 🔍 Section 4: Arguments and Parameters

### Reading Script Arguments

```bash
#!/bin/bash
# Save as args.sh

echo "Script name: $0"
echo "First argument: $1"
echo "Second argument: $2"
echo "All arguments: $@"
echo "Number of arguments: $#"
```

```bash
$ ./args.sh foo bar baz
# Script name: ./args.sh
# First argument: foo
# Second argument: bar
# All arguments: foo bar baz
# Number of arguments: 3
```

### Shifting Arguments

```bash
#!/bin/bash
# Use shift to process arguments one by one

while [ "$#" -gt 0 ]; do
    echo "Processing: $1"
    shift
done
```
```bash 
╭─ ~/Desktop/TEST on feature-login !5 ?
╰─❯ source script2.sh a b c d e f g h i j k l m n o p q r s t u v w x y z
```


[← Previous](04-section-3-conditionals-making-decisions.md) | [↑ Index](index.md) | [Next →](06-level-1-practices.md)
