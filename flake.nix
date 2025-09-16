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
            "-machine pc"
            "-kernel $KERNEL_DIR/bzImage"
            "-append \"console=ttyS0 $KERNEL_CMDLINE\""
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "x86_64-linux" = {
          nixCross = "gnu64";
          dockerPlatform = "linux/amd64";
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
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "armv7l-linux" = {
          nixCross = "armv7l-hf-multiplatform";
          dockerPlatform = "linux/arm";
          qemuArch = "arm";
          qemuArgs = [
            "-machine virt-2.9"
            "-cpu cortex-a7"
            "-kernel $KERNEL_DIR/zImage"
          ];
          sharedDir = [
            "-fsdev local,id=test_dev,path=/tmp/shared,security_model=none,multidevs=remap"
            "-device virtio-9p-device,fsdev=test_dev,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-device,netdev=eth0"
          ];
        };
        "aarch64-linux" = {
          nixCross = "aarch64-multiplatform";
          dockerPlatform = "linux/arm64";
          qemuArch = "aarch64";
          qemuArgs = [
            "-machine virt,mte=on"
            "-cpu max"
            "-kernel $KERNEL_DIR/Image"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "riscv64-linux" = {
          nixCross = "riscv64";
          dockerPlatform = "linux/riscv64";
          qemuArch = "riscv64";
          qemuArgs = [
            "-machine virt"
            "-kernel $KERNEL_DIR/Image"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-device,netdev=eth0"
          ];
        };
        "s390x-linux" = {
          nixCross = "s390x";
          dockerPlatform = "linux/s390x";
          qemuArch = "s390x";
          qemuArgs = [
            "-machine s390-ccw-virtio"
            "-kernel $KERNEL_DIR/bzImage"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "ppc64-linux" = {
          nixCross = "ppc64";
          dockerPlatform = "linux/ppc64";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine powernv"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          sharedDir = [
            "-fsdev local,id=test_dev,path=/tmp/shared,security_model=none,multidevs=remap"
            "-device virtio-9p-pci,fsdev=test_dev,mount_tag=shared,bus=pcie.1"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0,bus=pcie.0"
          ];
        };
        "ppc64le-linux" = {
          nixCross = "powernv";
          dockerPlatform = "linux/ppc64le";
          qemuArch = "ppc64";
          qemuArgs = [
            "-machine powernv"
            "-kernel $KERNEL_DIR/zImage"
          ];
          sharedDir = [
            "-fsdev local,id=test_dev,path=/tmp/shared,security_model=none,multidevs=remap"
            "-device virtio-9p-pci,fsdev=test_dev,mount_tag=shared,bus=pcie.1"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0,bus=pcie.0"
          ];
        };
        "loongarch64-linux" = {
          nixCross = "loongarch64-linux";
          dockerPlatform = "linux/loong64";
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
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "mips-linux" = {
          nixCross = "mips-linux-gnu";
          dockerPlatform = "linux/mips";
          qemuArch = "mips";
          qemuArgs = [
            "-machine malta"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "mipsel-linux" = {
          nixCross = "mipsel-linux-gnu";
          dockerPlatform = "linux/mipsle";
          qemuArch = "mipsel";
          qemuArgs = [
            "-machine malta"
            "-kernel $KERNEL_DIR/vmlinux"
          ];
          sharedDir = [
            "-virtfs local,path=$SHARED_DIR,security_model=none,mount_tag=shared"
          ];
          network = [
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
        "mips64el-linux" = {
          nixCross = "mips64el-linux-gnuabi64";
          dockerPlatform = "linux/mips64le";
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
            "-netdev user,id=eth0$PORT_FORWARD"
            "-device virtio-net-pci,netdev=eth0"
          ];
        };
      };

      download_docker =
        pkgs:
        pkgs.runCommand "download_docker" {
          nativeBuildInputs = [
            pkgs.makeWrapper
          ];
        } ''
          mkdir -p $out/bin/
          cp ${./download_docker.sh} $out/bin/download_docker.sh
          patchShebangs $out/bin/download_docker.sh
          wrapProgram $out/bin/download_docker.sh \
            --set PATH ${
              pkgs.lib.makeBinPath [
                pkgs.coreutils
                pkgs.findutils
                pkgs.gnugrep
                pkgs.gnused
                pkgs.skopeo
                pkgs.squashfs-tools-ng
                pkgs.undocker
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
        pkgs.writeShellScriptBin "run" ''
          KERNEL_DIR=${kernel}
          INITRD_DIR=${initrd}
          KERNEL_CMDLINE="panic=-1 oops=panic"
          SHARED_DIR=''${SHARED_DIR:-/tmp/shared}
          PORT_FORWARD=""
          GDB_PORT="1234"

          mkdir -p "$SHARED_DIR"

          # VSOCK (linux only):
          # -device vhost-vsock-pci,guest-cid=3

          show_help() {
              echo "Usage: $0 [options]"
              echo "Options:"
              echo "  --debug, -d       Enables debug gdbstubs"
              echo "  --nokaslr         Disable KASLR"
              echo "  -i                Docker image (default: none)"
              echo "  -g PORT           Set GDB port (default: $GDB_PORT)"
              echo "  -p H:G            Forward host port H to guest port G (Docker-style, can be repeated)"
              echo "  --help, -h        Displays this help message"
          }

          # Default values
          DEBUG=false
          NOKASLR=false
          QEMU_EXTRACMD=""
          DOCKER_IMAGE=""

          while [ $# -gt 0 ]; do
              case "$1" in
                  --debug|-d)
                      DEBUG=true
                      shift
                      ;;
                  --nokaslr)
                      NOKASLR=true
                      shift
                      ;;
                  -g)
                      GDB_PORT="$2"
                      shift 2
                      ;;
                  -i)
                      DOCKER_IMAGE="$2"
                      shift 2
                      ;;
                  -p)
                      hp="$2"
                      host="''${hp%%:*}"
                      guest="''${hp##*:}"
                      PORT_FORWARD="''${PORT_FORWARD},hostfwd=tcp::''${host}-:''${guest}"
                      shift 2
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
            echo "gdbserver is listening on port :$GDB_PORT. Please use the following VMLINUX file:"
            echo "$KERNEL_DIR/vmlinux.debug"
            echo
            echo

            if [ "$NOKASLR" = false ]; then
              echo "KASLR is enabled. To disable it, use the --nokaslr option."
              echo "Note: If KASLR is enabled, you will need to manually calculate the offset,"
              echo "because debug symbols from vmlinux will not work correctly."
            fi

            QEMU_EXTRACMD="-gdb tcp::$GDB_PORT -S"
          fi

          if [ "$NOKASLR" = true ]; then
            KERNEL_CMDLINE="$KERNEL_CMDLINE nokaslr"
          fi

          if [ -n "$DOCKER_IMAGE" ]; then
            QEMU_SQUASHFS=$(${download_docker}/bin/download_docker.sh ${args.dockerPlatform} $DOCKER_IMAGE)
            EXIT_CODE=$?
            if [ $EXIT_CODE -ne 0 ]; then
                echo "Error downloading Docker image: exit code $EXIT_CODE"
                exit $EXIT_CODE
            fi
            if [ -n "$QEMU_SQUASHFS" ]; then
                QEMU_EXTRACMD="$QEMU_EXTRACMD -drive file=$QEMU_SQUASHFS,format=raw,if=virtio"
            fi
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
