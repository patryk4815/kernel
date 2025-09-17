
# Run vm
```
nix run github:patryk4815/kernel#vm-aarch64-linux --accept-flake-config -- --help
```
### Options:
```
Options:
  --debug, -d       Enables debug gdbstubs
  --nokaslr         Disable KASLR
  -i IMAGE          Docker image (default: none)
  -g PORT           Set GDB port (default: 1234)
  -p H:G            Forward host port H to guest port G (Docker-style, can be repeated)
  --help, -h        Displays this help message
```

# Matrix
| Attr/Architecture    | Endianess | Network/NAT | SharedDir |
|----------------------|-----------|-------------|------------|
| vm-i686-linux        | Little    | ✅          | ✅         |
| vm-x86_64-linux      | Little    | ✅          | ✅         |
| vm-armv7l-linux      | Little    | ✅          | ✅         |
| vm-aarch64-linux     | Little    | ✅          | ✅         |
| vm-riscv64-linux     | Little    | ✅          | ✅         |
| vm-s390x-linux       | Big       | ✅          | ✅         |
| vm-ppc64-linux       | Big       | ✅          | ✅         |
| vm-ppc64le-linux     | Little    | ✅          | ✅         |
| vm-loongarch64-linux | Little    | ✅          | ✅         |
| vm-mips-linux        | Big       | ✅          | ✅         |
| vm-mipsel-linux      | Little    | ✅          | ✅         |
| vm-mips64el-linux    | Little    | ✅          | ✅         |
