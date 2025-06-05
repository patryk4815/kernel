{
  description = "kernel";

  nixConfig = {
    extra-substituters = [
      "https://patryk4815.cachix.org"
    ];
    extra-trusted-public-keys = [
      "patryk4815.cachix.org-1:NVPj2ZnbKi30JPrj2Vdd3VVNXrv6u/4Mt7yAD4/uqkY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      forceSystemLinux = (
        system':
        let
          pkgs = nixpkgs.legacyPackages.${system'};
          fix = builtins.replaceStrings [ "-darwin" ] [ "-linux" ] system';
          system = if pkgs.stdenv.isLinux then system' else fix;
        in
        system
      );

      vms = {
        "i686-linux" = {
          nixCross = "gnu32";
          qemuArch = "i386";
          qemuArgs = [
            "-machine pc"
            "-kernel $KERNEL_DIR/bzImage"
            "-append \"console=ttyS0 $KERNEL_CMDLINE\""
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "x86_64-linux" = {
          nixCross = "gnu64";
          qemuArch = "x86_64";
          qemuArgs = [
            "-machine pc"
            "-kernel $KERNEL_DIR/bzImage"
            "-append \"console=ttyS0 $KERNEL_CMDLINE\""
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "armv7l-linux" = {
          nixCross = "armv7l-hf-multiplatform";
          qemuArch = "arm";
          qemuArgs = [
            "-machine virt"
            "-cpu cortex-a7"
            "-kernel $KERNEL_DIR/zImage"
          ];
          sharedDir = [
            "-fsdev local,id=test_dev,path=/tmp/shared,security_model=mapped,multidevs=remap"
            "-device virtio-9p-device,fsdev=test_dev,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-device,netdev=eth0"
          ];
        };
        "aarch64-linux" = {
          nixCross = "aarch64-multiplatform";
          qemuArch = "aarch64";
          qemuArgs = [
            "-machine virt"
            "-cpu cortex-a57"
            "-kernel $KERNEL_DIR/Image"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "riscv64-linux" = {
          nixCross = "riscv64";
          qemuArch = "riscv64";
          qemuArgs = [
            "-machine virt"
            "-kernel $KERNEL_DIR/Image"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-device,netdev=eth0"
          ];
        };
        "s390x-linux" = {
          nixCross = "s390x";
          qemuArch = "s390x";
          qemuArgs = [
            "-machine s390-ccw-virtio"
            "-kernel $KERNEL_DIR/bzImage"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "ppc64-linux" = {
          nixCross = "ppc64";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine powernv"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          sharedDir = [
            "-fsdev local,id=test_dev,path=/tmp/shared,security_model=mapped,multidevs=remap"
            "-device virtio-9p-pci,fsdev=test_dev,mount_tag=shared,bus=pcie.1"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0,bus=pcie.0"
          ];
        };
        "ppc64le-linux" = {
          nixCross = "powernv";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine powernv"
            "-kernel $KERNEL_DIR/zImage"
          ];
          sharedDir = [
            "-fsdev local,id=test_dev,path=/tmp/shared,security_model=mapped,multidevs=remap"
            "-device virtio-9p-pci,fsdev=test_dev,mount_tag=shared,bus=pcie.1"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0,bus=pcie.0"
          ];
        };
        "loongarch64-linux" = {
          nixCross = "loongarch64-linux";
          qemuArch = "loongarch64";
          qemuArgs = [
            "-machine virt"
            "-cpu la464"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "mips-linux" = {
          nixCross = "mips-linux-gnu";
          qemuArch = "mips";
          qemuArgs = [
            "-machine malta"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "mipsel-linux" = {
          nixCross = "mipsel-linux-gnu";
          qemuArch = "mipsel";
          qemuArgs = [
            "-machine malta"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "mips64el-linux" = {
          nixCross = "mips64el-linux-gnuabi64";
          qemuArch = "mips64el";
          qemuArgs = [
            "-machine loongson3-virt"
            "-cpu Loongson-3A4000"
            "-kernel $KERNEL_DIR/vmlinux"
            "-append \"console=ttyS0 $KERNEL_CMDLINE\""
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
      };

      run_qemu =
        system: cross:
        let
          args = vms.${cross};
          pkgs = nixpkgs.legacyPackages.${system};
          initrd = self.packages.${system}."initrd-${cross}";
          kernel = self.packages.${system}."kernel-${cross}";
        in
        pkgs.writeShellScriptBin "run" ''
          KERNEL_DIR=${kernel}
          INITRD_DIR=${initrd}
          KERNEL_CMDLINE="panic=-1 oops=panic"
          SHARED_DIR=''${SHARED_DIR:-/tmp/shared}

          # Port forward:
          # -device virtio-net-device,netdev=eth0 \
          # -netdev user,id=eth0,hostfwd=tcp::2222-:22
          # -netdev user,id=n0,hostfwd=hostip:hostport-guestip:guestport
          #
          # Debugger:
          # -S -gdb tcp::''${GDB_PORT}
          #
          # VSOCK:
          # -device vhost-vsock-pci,guest-cid=3

          show_help() {
              echo "Usage: $0 [options]"
              echo "Options:"
              echo "  --debug, -d       Enables debug gdbstubs"
              echo "  --nokaslr         Disable KASLR"
              echo "  --help, -h        Displays this help message"
          }

          # Default values
          DEBUG=false
          NOKASLR=false
          QEMU_EXTRACMD=""

          for arg in "$@"; do
              case "$arg" in
                  --debug|-d)
                      DEBUG=true
                      ;;
                  --nokaslr)
                      NOKASLR=true
                      ;;
                  --help|-h)
                      show_help
                      exit 0
                      ;;
                  *)
                      echo "Unknown option: $arg"
                      show_help
                      exit 1
                      ;;
              esac
          done

          if [ "$DEBUG" = true ]; then
            echo "gdbserver is listening on port :1234. Please use the following VMLINUX file:"
            echo "$KERNEL_DIR/vmlinux.debug"
            echo
            echo

            if [ "$NOKASLR" = false ]; then
              echo "KASLR is enabled. To disable it, use the --nokaslr option."
              echo "Note: If KASLR is enabled, you will need to manually calculate the offset,"
              echo "because debug symbols from vmlinux will not work correctly."
            fi

            QEMU_EXTRACMD="-s -S"
          fi

          if [ "$NOKASLR" = true ]; then
            KERNEL_CMDLINE="$KERNEL_CMDLINE nokaslr"
          fi

          ${pkgs.qemu}/bin/qemu-system-${args.qemuArch} \
            -m 2G \
            -smp 1 \
            -nographic \
            -no-reboot \
            -append "$KERNEL_CMDLINE" \
            -initrd $INITRD_DIR/initrd $QEMU_EXTRACMD \
            ${toString args.qemuArgs} ${toString args.network} ${toString args.sharedDir}
        '';

      kernelDrvs =
        system':
        let
          system = forceSystemLinux system';
        in
        (nixpkgs.lib.attrsets.mapAttrs' (cross: value: {
          name = "kernel-${cross}";
          value =
            nixpkgs.legacyPackages.${system}.pkgsCross.${vms.${cross}.nixCross}.callPackage ./kernel.nix
              { };
        }) vms);

      initrdDrvs =
        system':
        let
          system = forceSystemLinux system';
        in
        (nixpkgs.lib.attrsets.mapAttrs' (cross: value: {
          name = "initrd-${cross}";
          value =
            nixpkgs.legacyPackages.${system}.pkgsCross.${vms.${cross}.nixCross}.callPackage ./initrd.nix
              { };
        }) vms);

      vmDrvs =
        system:
        (nixpkgs.lib.attrsets.mapAttrs' (cross: value: {
          name = "vm-${cross}";
          value = run_qemu system cross;
        }) vms);
    in
    {
      packages = forAllSystems (
        system:
        {

        }
        // (vmDrvs system)
        // (kernelDrvs system)
        // (initrdDrvs system)
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
