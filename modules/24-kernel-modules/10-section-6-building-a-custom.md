## 🔍 Section 6: Building a Custom Kernel Module

### Prerequisites

```bash
# Install kernel headers and build tools
# Debian/Ubuntu
sudo apt install linux-headers-$(uname -r) build-essential

# Fedora/RHEL
sudo dnf install kernel-devel kernel-headers gcc make

# Verify headers are installed
ls /lib/modules/$(uname -r)/build/
```

### Simple "Hello World" Module

```bash
cd ~/linux-course/part24
mkdir -p hello_module
cd hello_module
```

```c
// hello.c — Simple kernel module
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int __init hello_init(void)
{
    printk(KERN_INFO "Hello, kernel module loaded!\n");
    return 0;
}

static void __exit hello_exit(void)
{
    printk(KERN_INFO "Goodbye, kernel module unloaded!\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Linux Course");
MODULE_DESCRIPTION("A simple hello world module");
```

```makefile
# Makefile for the hello module
obj-m += hello.o

all:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

```bash
# Build the module
make

# Load the module
sudo insmod hello.ko

# Check kernel messages
dmesg | tail -5
# Should see: Hello, kernel module loaded!

# Check if loaded
lsmod | grep hello

# Unload
sudo rmmod hello

# Check kernel messages again
dmesg | tail -5
# Should see: Goodbye, kernel module unloaded!
```





[← Previous](09-section-5-troubleshooting-kernel-modules.md) | [↑ Index](index.md) | [Next →](11-section-7-device-drivers-and.md)
