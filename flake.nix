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

      vms = {
        "i686-linux" = {
          nixCross = "gnu32";
          qemuArch = "i386";
          qemuArgs = [
            "-machine pc"
            "-kernel $KERNEL_DIR/bzImage"
            "-append \"console=ttyS0 $KERNEL_CMDLINE\""
          ];
          network = true;
        };
        "x86_64-linux" = {
          nixCross = "gnu64";
          qemuArch = "x86_64";
          qemuArgs = [
            "-machine pc"
            "-kernel $KERNEL_DIR/bzImage"
            "-append \"console=ttyS0 $KERNEL_CMDLINE\""
          ];
          network = true;
        };
        "armv7l-linux" = {
          nixCross = "armv7l-hf-multiplatform";
          qemuArch = "arm";
          qemuArgs = [
            "-machine virt"
            "-cpu cortex-a7"
            "-kernel $KERNEL_DIR/zImage"

            "-netdev user,id=eth0"
            "-device virtio-net-device,netdev=eth0"

            "-fsdev local,id=test_dev,path=/tmp/shared,security_model=mapped,multidevs=remap"
            "-device virtio-9p-device,fsdev=test_dev,mount_tag=shared"
          ];
          network = true;
        };
        "aarch64-linux" = {
          nixCross = "aarch64-multiplatform";
          qemuArch = "aarch64";
          qemuArgs = [
            "-machine virt"
            "-cpu cortex-a57"
            "-kernel $KERNEL_DIR/Image"
          ];
          network = true;
        };
        "riscv64-linux" = {
          nixCross = "riscv64";
          qemuArch = "riscv64";
          qemuArgs = [
            "-machine virt"
            "-kernel $KERNEL_DIR/Image"

            "-netdev user,id=eth0"
            "-device virtio-net-device,netdev=eth0"
          ];
          network = true;
        };
        "s390x-linux" = {
          nixCross = "s390x";
          qemuArch = "s390x";
          qemuArgs = [
            "-machine s390-ccw-virtio"
            "-kernel $KERNEL_DIR/bzImage"
          ];
          network = true;
        };
        "ppc64-linux" = {
          nixCross = "ppc64";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine powernv"
            "-kernel $KERNEL_DIR/vmlinux"

            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
          network = true;
        };
        "ppc64le-linux" = {
          nixCross = "powernv";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine powernv"
            "-kernel $KERNEL_DIR/zImage"

            "-netdev user,id=eth0"
            "-device virtio-net-pci,netdev=eth0"
          ];
          network = true;
        };
        "loongarch64-linux" = {
          nixCross = "loongarch64-linux";
          qemuArch = "loongarch64";
          qemuArgs = [
            "-machine virt"
            "-cpu la464"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          network = true;
        };
        "mips-linux" = {
          nixCross = "mips-linux-gnu";
          qemuArch = "mips";
          qemuArgs = [
            "-machine malta"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          network = true;
        };
        "mipsel-linux" = {
          nixCross = "mipsel-linux-gnu";
          qemuArch = "mipsel";
          qemuArgs = [
            "-machine malta"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          network = true;
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
          network = true;
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

          #  -virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared \
          # ${pkgs.virtiofsd}/bin/virtiofsd --socket-path /tmp/vhostqemu --shared-dir /tmp/shared &
          #             -chardev socket,id=virtfs0,path=/tmp/vhostqemu \
          #            -device vhost-user-fs-pci,queue-size=1024,chardev=virtfs0,tag=shared \
          #            -object memory-backend-file,id=mem0,size=1G,mem-path=/dev/shm,share=on \
          #            -numa node,memdev=mem0 \
          # TODO: armv7l nie wspiera 9p /
          # TODO: VSOCK: -device vhost-vsock-pci,guest-cid=3 \
          #
          # Port forward:
          # -device virtio-net-device,netdev=net \
          #-netdev user,id=net,hostfwd=tcp::2222-:22

          ${pkgs.qemu}/bin/qemu-system-${args.qemuArch} \
            -m 2G \
            -smp 1 \
            -nographic \
            -no-reboot \
            -append "$KERNEL_CMDLINE" \
            -initrd $INITRD_DIR/initrd \
            -virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared \
            ${toString args.qemuArgs}
        '';

      kernelDrvs =
        system:
        (nixpkgs.lib.attrsets.mapAttrs' (cross: value: {
          name = "kernel-${cross}";
          value =
            nixpkgs.legacyPackages.${system}.pkgsCross.${vms.${cross}.nixCross}.callPackage ./kernel.nix
              { };
        }) vms);

      initrdDrvs =
        system:
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
