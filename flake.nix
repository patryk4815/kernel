{
  description = "kernel";

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
          qemuArch = "x86";
          qemuArgs = [
            "-machine pc"
            "-kernel $KERNEL_DIR/bzImage"
            "-append \"console=ttyS0 $KERNEL_CMDLINE\""
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
        };
        "armv7l-linux" = {
          nixCross = "armv7l-hf-multiplatform";
          qemuArch = "arm";
          qemuArgs = [
            # "-machine versatilepb"
            # "-m 256M"
            # "-dtb $KERNEL_DIR/dts/arm/versatile-pb.dtb"
            # "-machine orangepi-pc"
            # "-smp 4"
            # "-dtb $KERNEL_DIR/dts/allwinner/sun8i-h3-orangepi-pc.dtb"
            "-machine virt"
            "-cpu cortex-a7"
            "-kernel $KERNEL_DIR/zImage"
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
        };
        "riscv64-linux" = {
          nixCross = "riscv64";
          qemuArch = "riscv64";
          qemuArgs = [
            "-machine virt"
            "-kernel $KERNEL_DIR/Image"
          ];
        };
        "s390x-linux" = {
          nixCross = "s390x";
          qemuArch = "s390x";
          qemuArgs = [
            "-machine s390-ccw-virtio"
            "-kernel $KERNEL_DIR/bzImage"
          ];
        };
        "ppc64-linux" = {
          nixCross = "ppc64";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine powernv"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
        };
        "ppc64le-linux" = {
          nixCross = "powernv";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine powernv"
            "-kernel $KERNEL_DIR/vmlinux"
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
        };
        "mips-linux" = {
          nixCross = "mips-linux-gnu";
          qemuArch = "mips";
          qemuArgs = [
            "-machine virt"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
        };
        "mipsel-linux" = {
          nixCross = "mipsel-linux-gnu";
          qemuArch = "mipsel";
          qemuArgs = [
            "-machine virt"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
        };
        "mips64-linux" = {
          nixCross = "mips64-linux-gnuabi64";
          qemuArch = "mips64";
          qemuArgs = [
            "-machine virt"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
        };
        "mips64el-linux" = {
          nixCross = "mips64el-linux-gnuabi64";
          qemuArch = "mips64el";
          qemuArgs = [
            "-machine virt"
            "-kernel $KERNEL_DIR/vmlinux"
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
          KERNEL_CMDLINE="panic=1 oops=panic"
          SHARED_DIR=''${SHARED_DIR:-/tmp/shared}

          #  -virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared \
          # ${pkgs.virtiofsd}/bin/virtiofsd --socket-path /tmp/vhostqemu --shared-dir /tmp/shared &
          #             -chardev socket,id=virtfs0,path=/tmp/vhostqemu \
          #            -device vhost-user-fs-pci,queue-size=1024,chardev=virtfs0,tag=shared \
          #            -object memory-backend-file,id=mem0,size=1G,mem-path=/dev/shm,share=on \
          #            -numa node,memdev=mem0 \
          # TODO: armv7l nie wspiera 9p /
          # TODO: VSOCK: -device vhost-vsock-pci,guest-cid=3 \

          ${pkgs.qemu}/bin/qemu-system-${args.qemuArch} \
            -m 1G \
            -smp 1 \
            -nographic \
            -no-reboot \
            -append "$KERNEL_CMDLINE" \
            -initrd $INITRD_DIR/initrd \
            -nic user,model=virtio-net-pci \
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
