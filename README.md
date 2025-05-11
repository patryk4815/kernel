
# Run vm
```
nix run github:patryk4815/kernel#vm-aarch64-linux
```

# Build kernel/initrd
```
nix build github:patryk4815/kernel#kernel-aarch64-linux
nix build github:patryk4815/kernel#initrd-aarch64-linux
```

# Matrix
| Attr/Architecture     | Network/NAT | SharedDir |
|-----------------------|-------------|------------|
| vm-i686-linux         | ❌          | ❌         |
| vm-x86_64-linux       | ❌          | ❌         |
| vm-armv7l-linux       | ❌          | ❌         |
| vm-aarch64-linux      | ❌          | ❌         |
| vm-riscv64-linux      | ❌          | ❌         |
| vm-s390x-linux        | ❌          | ❌         |
| vm-ppc64-linux        | ❌          | ❌         |
| vm-ppc64le-linux      | ❌          | ❌         |
| vm-loongarch64-linux  | ❌          | ❌         |
| vm-mips-linux         | ❌          | ❌         |
| vm-mipsel-linux       | ❌          | ❌         |
| ~~vm-mips64-linux~~   | ❌          | ❌         |
| ~~vm-mips64el-linux~~ | ❌          | ❌         |
