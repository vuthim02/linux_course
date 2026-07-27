## 11. Parsing Command-Line Args

### `getopts` — Short Options

```bash
#!/bin/bash

usage() {
    echo "Usage: $0 [-v] [-o output_file] [-n count] name"
    exit 1
}

verbose=false
output_file=""
count=1

while getopts ":vo:n:" opt; do
    case $opt in
        v)
            verbose=true
            ;;
        o)
            output_file="$OPTARG"
            ;;
        n)
            count="$OPTARG"
            [[ "$count" =~ ^[0-9]+$ ]] || { echo "Count must be a number"; exit 1; }
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument"
            usage
            ;;
    esac
done

shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    echo "Error: name argument is required"
    usage
fi

name="$1"
echo "Count: $count, Output: ${output_file:-stdout}, Name: $name"
```

### Manual `shift` Parsing (POSIX)

```bash
#!/bin/bash

verbose=false
output_file=""
count=1

while [ $# -gt 0 ]; do
    case "$1" in
        --verbose|-v)
            verbose=true
            shift
            ;;
        --output|-o)
            output_file="$2"
            shift 2
            ;;
        --count|-n)
            count="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        --*|-*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            break
            ;;
    esac
done

name="$1"
echo "Name: $name, Verbose: $verbose, Output: ${output_file:-stdout}, Count: $count"
```

---



---

[← Previous](14-10-arrays.md) | [↑ Index](index.md) | [Next →](16-13-real-admin-script-examples.md)
