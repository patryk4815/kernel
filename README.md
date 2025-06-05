
# Run vm
```
nix run github:patryk4815/kernel#vm-aarch64-linux --accept-flake-config -- --help
```

# Build kernel/initrd
```
nix build github:patryk4815/kernel#kernel-aarch64-linux --accept-flake-config
nix build github:patryk4815/kernel#initrd-aarch64-linux --accept-flake-config
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
