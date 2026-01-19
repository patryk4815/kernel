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
          dockerPlatform = "linux/386";
          qemuArch = "i386";
          qemuArgs = [
            "-machine" "pc"
            "-kernel" "@KERNEL_DIR@/bzImage"
          ];
          kernelArgs = ["console=ttyS0"];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0"
          ];
        };
        "x86_64-linux" = {
          nixCross = "gnu64";
          dockerPlatform = "linux/amd64";
          qemuArch = "x86_64";
          qemuArgs = [
            "-machine" "pc"
            "-kernel" "@KERNEL_DIR@/bzImage"
          ];
          kernelArgs = ["console=ttyS0"];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0"
          ];
        };
        "armv7l-linux" = {
          nixCross = "armv7l-hf-multiplatform";
          dockerPlatform = "linux/arm";
          qemuArch = "arm";
          qemuArgs = [
            "-machine" "virt"
            "-cpu" "cortex-a7"
            "-kernel" "@KERNEL_DIR@/zImage"
          ];
          sharedDir = [
            "-fsdev" "local,id=test_dev,path=/tmp/shared,security_model=none,multidevs=remap"
            "-device" "virtio-9p-device,fsdev=test_dev,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-device,netdev=eth0"
          ];
        };
        "aarch64-linux" = {
          nixCross = "aarch64-multiplatform";
          dockerPlatform = "linux/arm64";
          qemuArch = "aarch64";
          qemuArgs = [
            "-machine" "virt,mte=on"
            "-cpu" "max"
            "-kernel" "@KERNEL_DIR@/Image"
          ];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0"
          ];
        };
        "riscv64-linux" = {
          nixCross = "riscv64";
          dockerPlatform = "linux/riscv64";
          qemuArch = "riscv64";
          qemuArgs = [
            "-machine" "virt"
            "-kernel" "@KERNEL_DIR@/Image"
          ];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-device,netdev=eth0"
          ];
        };
        "s390x-linux" = {
          nixCross = "s390x";
          dockerPlatform = "linux/s390x";
          qemuArch = "s390x";
          qemuArgs = [
            "-machine" "s390-ccw-virtio"
            "-kernel" "@KERNEL_DIR@/bzImage"
          ];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0"
          ];
        };
        "ppc64-linux" = {
          nixCross = "ppc64";
          dockerPlatform = "linux/ppc64";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine" "powernv"
            "-kernel" "@KERNEL_DIR@/vmlinux"
          ];
          sharedDir = [
            "-fsdev" "local,id=test_dev,path=@SHARED_DIR@,security_model=none,multidevs=remap"
            "-device" "virtio-9p-pci,fsdev=test_dev,mount_tag=shared,bus=pcie.1"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0,bus=pcie.0"
          ];
        };
        "ppc64le-linux" = {
          nixCross = "powernv";
          dockerPlatform = "linux/ppc64le";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine" "powernv"
            "-kernel" "@KERNEL_DIR@/zImage"
          ];
          sharedDir = [
            "-fsdev" "local,id=test_dev,path=@SHARED_DIR@,security_model=none,multidevs=remap"
            "-device" "virtio-9p-pci,fsdev=test_dev,mount_tag=shared,bus=pcie.1"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0,bus=pcie.0"
          ];
        };
        "loongarch64-linux" = {
          nixCross = "loongarch64-linux";
          dockerPlatform = "linux/loong64";
          qemuArch = "loongarch64";
          qemuArgs = [
            "-machine" "virt"
            "-cpu" "la464"
            "-kernel" "@KERNEL_DIR@/vmlinux"
          ];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0"
          ];
        };
        "mips-linux" = {
          nixCross = "mips-linux-gnu";
          dockerPlatform = "linux/mips";
          qemuArch = "mips";
          qemuArgs = [
            "-machine" "malta"
            "-kernel" "@KERNEL_DIR@/vmlinux"
          ];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0"
          ];
        };
        "mipsel-linux" = {
          nixCross = "mipsel-linux-gnu";
          dockerPlatform = "linux/mipsle";
          qemuArch = "mipsel";
          qemuArgs = [
            "-machine" "malta"
            "-kernel" "@KERNEL_DIR@/vmlinux"
          ];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0"
          ];
        };
        "mips64el-linux" = {
          nixCross = "mips64el-linux-gnuabi64";
          dockerPlatform = "linux/mips64le";
          qemuArch = "mips64el";
          qemuArgs = [
            "-machine" "loongson3-virt"
            "-cpu" "Loongson-3A4000"
            "-kernel" "@KERNEL_DIR@/vmlinux"
          ];
          kernelArgs = ["console=ttyS0"];
          sharedDir = [
            "-virtfs" "local,path=@SHARED_DIR@,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev" "user,id=eth0@PORT_FORWARD@"
            "-device" "virtio-net-pci,netdev=eth0"
          ];
        };
      };

      download_docker =
        pkgs:
        pkgs.runCommand "download_docker" {
          nativeBuildInputs = [
            pkgs.makeWrapper
          ];
          buildInputs = [
            pkgs.python3
          ];
        } ''
          mkdir -p $out/bin/
          cp ${./download_docker.py} $out/bin/download_docker
          patchShebangs $out/bin/download_docker
          wrapProgram $out/bin/download_docker \
            --set PATH ${
              pkgs.lib.makeBinPath [
                pkgs.skopeo
                pkgs.undocker
                pkgs.erofs-utils
              ]
            }
        '';

      run_qemu =
        system: cross:
        let
          args = vms.${cross};
          pkgs = nixpkgs.legacyPackages.${system};
          initrd = self.packages.${system}."initrd-${cross}";
          kernel = self.packages.${system}."kernel-${cross}";
          download_docker = self.packages.${system}.download_docker;
        in
        pkgs.runCommand "run" {
          nativeBuildInputs = [
            pkgs.makeWrapper
          ];
          buildInputs = [
            pkgs.python3
          ];
        } ''
          mkdir -p $out/bin/
          cp ${./run.py} $out/bin/run
          patchShebangs $out/bin/run
          wrapProgram $out/bin/run \
            --set PATH ${
              pkgs.lib.makeBinPath [
                pkgs.qemu
                pkgs.e2fsprogs
                download_docker
              ]
            } \
            --set KERNEL_DIR "${kernel}" \
            --set INITRD_DIR "${initrd}" \
            --set RUN_ARGS '${builtins.toJSON args}'
        '';

      kernelDrvs =
        system':
        let
          system = forceSystemLinux system';
        in
        (nixpkgs.lib.attrsets.mapAttrs' (archName: value: {
          name = "kernel-${archName}";
          value =
            nixpkgs.legacyPackages.${system}.pkgsCross.${vms.${archName}.nixCross}.callPackage ./kernel.nix
              {
                kernelConfig = vms.${archName}.kernelConfig or null;
              };
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
            download_docker = download_docker nixpkgs.legacyPackages.${system};
        }
        // (vmDrvs system)
        // (kernelDrvs system)
        // (initrdDrvs system)
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
