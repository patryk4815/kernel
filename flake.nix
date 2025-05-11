{
  description = "foo";

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
      # Self contained packages for: Debian, RHEL-like (yum, rpm), Alpine, Arch packages
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      run_qemu =
        system: systemGuest: qemuArgs:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          initrd = self.packages.${system}.rootfs.${systemGuest};
          kernel = self.packages.${system}.kernel.${systemGuest};
          qemuArch = kernel.stdenv.hostPlatform.qemuArch;
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

          ${pkgs.qemu}/bin/qemu-system-${qemuArch} \
            -m 1G \
            -smp 1 \
            -nographic \
            -no-reboot \
            -append "$KERNEL_CMDLINE" \
            -initrd $INITRD_DIR/initrd \
            -device vhost-vsock-pci,guest-cid=3 \
            -nic user,model=virtio-net-pci \
            ${toString qemuArgs}
        '';
    in
    {
      packages.aarch64-linux.kernel = {
        i686-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.gnu32.callPackage ./kernel.nix { };
        x86_64-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.gnu64.callPackage ./kernel.nix { };
        riscv64-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.riscv64.callPackage ./kernel.nix { };
        armv7l-linux =
          nixpkgs.legacyPackages.aarch64-linux.pkgsCross.armv7l-hf-multiplatform.callPackage ./kernel.nix
            { };
        aarch64-linux =
          nixpkgs.legacyPackages.aarch64-linux.pkgsCross.aarch64-multiplatform.callPackage ./kernel.nix
            { };
        s390x-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.s390x.callPackage ./kernel.nix { };
        ppc64le-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.powernv.callPackage ./kernel.nix { };
        loongarch64-linux =
          nixpkgs.legacyPackages.aarch64-linux.pkgsCross.loongarch64-linux.callPackage ./kernel.nix
            { };
      };
      packages.aarch64-linux.rootfs = {
        i686-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.gnu32.callPackage ./rootfs.nix { };
        x86_64-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.gnu64.callPackage ./rootfs.nix { };
        riscv64-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.riscv64.callPackage ./rootfs.nix { };
        armv7l-linux =
          nixpkgs.legacyPackages.aarch64-linux.pkgsCross.armv7l-hf-multiplatform.callPackage ./rootfs.nix
            { };
        aarch64-linux =
          nixpkgs.legacyPackages.aarch64-linux.pkgsCross.aarch64-multiplatform.callPackage ./rootfs.nix
            { };
        s390x-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.s390x.callPackage ./rootfs.nix { };
        ppc64le-linux = nixpkgs.legacyPackages.aarch64-linux.pkgsCross.powernv.callPackage ./rootfs.nix { };
        loongarch64-linux =
          nixpkgs.legacyPackages.aarch64-linux.pkgsCross.loongarch64-linux.callPackage ./rootfs.nix
            { };
      };

      packages.aarch64-linux.vm = {
        i686-linux = run_qemu "aarch64-linux" "i686-linux" [
          "-machine pc"
          "-kernel $KERNEL_DIR/bzImage"
          "-append \"console=ttyS0 $KERNEL_CMDLINE\""
        ];
        x86_64-linux = run_qemu "aarch64-linux" "x86_64-linux" [
          "-machine pc"
          "-kernel $KERNEL_DIR/bzImage"
          "-append \"console=ttyS0 $KERNEL_CMDLINE\""
        ];
        riscv64-linux = run_qemu "aarch64-linux" "riscv64-linux" [
          "-machine virt"
          "-kernel $KERNEL_DIR/Image"
        ];
        armv7l-linux = run_qemu "aarch64-linux" "armv7l-linux" [
#          "-machine versatilepb"
#          "-m 256M"
#          "-dtb $KERNEL_DIR/dts/arm/versatile-pb.dtb"
#          "-machine orangepi-pc"
#          "-smp 4"
#          "-dtb $KERNEL_DIR/dts/allwinner/sun8i-h3-orangepi-pc.dtb"
          "-machine virt"
          "-cpu cortex-a7"
          "-kernel $KERNEL_DIR/zImage"
        ];
        aarch64-linux = run_qemu "aarch64-linux" "aarch64-linux" [
          "-machine virt"
          "-cpu cortex-a57"
          "-kernel $KERNEL_DIR/Image"
        ];
        s390x-linux = run_qemu "aarch64-linux" "s390x-linux" [
          "-machine s390-ccw-virtio"
          "-kernel $KERNEL_DIR/bzImage"
        ];
        ppc64le-linux = run_qemu "aarch64-linux" "ppc64le-linux" [
          "-machine powernv"
          "-kernel $KERNEL_DIR/vmlinux"
        ];
        loongarch64-linux = run_qemu "aarch64-linux" "loongarch64-linux" [
          "-machine virt"
          "-cpu la464"
          "-kernel $KERNEL_DIR/vmlinux"
        ];
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
