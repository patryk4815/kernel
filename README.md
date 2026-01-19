
# Run vm
```
nix run github:patryk4815/kernel#vm-aarch64-linux --accept-flake-config -- --help
```
### Options:
```
Options:
  --debug, -d          Enables debug gdbstubs
  --nokaslr            Disable KASLR
  --platform PLAT      Platform for docker image eg. linux/amd64 (default: target-kernel)
  -i IMAGE             Docker image (default: none)
  -g PORT              Set GDB port (default: 1234)
  -p H:G               Forward host port H to guest port G (Docker-style, can be repeated)
  --help, -h           Displays this help message
```

# Matrix
| Attr/Architecture  | Endianess                | Network/NAT        | SharedDir          |
|--------------------|--------------------------|--------------------|--------------------|
| vm-i686-linux      | Little                   | ✅                  | ✅                  |
| vm-x86_64-linux    | Little                   | ✅                  | ✅                  |
| vm-x86_64_baseline-linux   | Little                   | ✅                  | ✅                  |
| vm-x86_64_v2-linux | Little                   | ✅                  | ✅                  |
| vm-x86_64_v3-linux | Little                   | ✅                  | ✅                  |
| vm-x86_64_v4-linux | ❌ not supported ❌ - see https://gitlab.com/qemu-project/qemu/-/issues/2878 |
| vm-armv7l-linux    | Little                   | ✅                  | ✅                  |
| vm-aarch64-linux   | Little                   | ✅                  | ✅                  |
| vm-riscv64-linux   | Little                   | ✅                  | ✅                  |
| vm-s390x-linux     | Big                      | ✅                  | ✅                  |
| vm-ppc64-linux     | Big                      | ✅                  | ✅                  |
| vm-ppc64le-linux   | Little                   | ✅                  | ✅                  |
| vm-loongarch64-linux | Little                   | ✅                  | ✅                  |
| vm-mips-linux      | Big                      | ✅                  | ✅                  |
| vm-mipsel-linux    | Little                   | ✅                  | ✅                  |
| vm-mips64el-linux  | Little                   | ✅                  | ✅                  |


### Distros:
* mispel - Debian 12 "bookworm" last release
* misp64el - debian
* mips - openwrt, debian ostatni release 9 stretch
* ppc64 - adelie linux, chimera Linux
* ppc64le - most of distros
* s390x - most of distros
* i686 - most of distros
* x86_64 - most of distros
* armv7l - ?? most of distros
* aarch64 - most of distros
* riscv64 - most of distros
* loongarch64 - most of distros

### Docker images:
* mipsel - vicamo/debian:bookworm (debian 12)
* misp64el - vicamo/debian:bookworm (debian 12) / debian:bookworm
* mips - openwrt/rootfs:malta-be (linux/mips_24kc)
* ppc64 - adelielinux/adelie:latest
* loongarch64 - ghcr.io/loong64/debian:trixie

TODO:
- console=hvc0 + CONFIG_VIRTIO_CONSOLE=y  (virtio_console)
agetty /dev/hvc0 9600 vt100
https://blog.memzero.de/toying-with-virtio/

