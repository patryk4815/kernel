{
  stdenv,
  lib,
  flex,
  bison,
  bc,
  perl,
  gcc,
  openssl,
  python3Minimal,
  pkg-config,
  fetchurl,
  buildPackages,
  elfutils,
  zstd,
  hexdump,
  ubootTools,
  kernelConfig ? null,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "linux";
  version = "6.16.3";

  src = fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${finalAttrs.version}.tar.xz";
    hash = "sha256-gEOboFXBL1Qav0S4/DybglqPQvwlzmdGLsflVsV5C4U=";
  };

  buildInputs = [ ];

  nativeBuildInputs = [
    flex
    bison
    bc
    perl
    pkg-config
    python3Minimal
    elfutils
    openssl
  ]
  ++ lib.optionals stdenv.targetPlatform.isLoongArch64 [
    hexdump
    zstd
  ]
  ++ lib.optionals stdenv.targetPlatform.isMips [
    ubootTools
  ];
  strictDeps = true;
  dontStrip = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  enableParallelBuilding = true;

  env = {
    ARCH = "${stdenv.hostPlatform.linuxArch}";
    CROSS_COMPILE = "${stdenv.cc.targetPrefix}";
  };

  preBuild =
    let
      defconfig =
        if stdenv.hostPlatform.isMips32 then
          "malta_defconfig"
        else if stdenv.hostPlatform.isMips64 then
          "loongson3_defconfig"
        else
          "defconfig";
    in
    ''
      make ${defconfig}
      patchShebangs scripts/config

      # Enable debug symbols
      scripts/config --disable CONFIG_DEBUG_INFO_REDUCED
      scripts/config --enable CONFIG_FRAME_POINTER
      scripts/config --enable CONFIG_DEBUG_KERNEL
      scripts/config --enable CONFIG_DEBUG_INFO
      scripts/config --enable CONFIG_DEBUG_INFO_DWARF5
      scripts/config --enable CONFIG_GDB_SCRIPTS

      # debug
      scripts/config --enable CONFIG_DEBUG_FS
      scripts/config --enable CONFIG_PTDUMP
      scripts/config --enable CONFIG_PTDUMP_DEBUGFS
      scripts/config --enable CONFIG_ANON_VMA_NAME
      scripts/config --enable CONFIG_IKCONFIG
      scripts/config --enable CONFIG_IKCONFIG_PROC
      scripts/config --enable CONFIG_IKHEADERS

      # Virtio
      scripts/config --enable CONFIG_FS_POSIX_ACL
      scripts/config --enable CONFIG_FUSE_FS
      scripts/config --enable CONFIG_BLOCK
      scripts/config --enable CONFIG_EROFS_FS
      scripts/config --enable CONFIG_VIRTIO_FS
      scripts/config --enable CONFIG_VIRTIO_VSOCKETS
      scripts/config --enable CONFIG_VIRTIO_BLK
      scripts/config --enable CONFIG_VIRTIO_NET
      scripts/config --enable CONFIG_VIRTIO_PCI
      scripts/config --enable CONFIG_VIRTIO_MEM
      scripts/config --enable CONFIG_VIRTIO_MMIO
      scripts/config --enable CONFIG_VIRTIO_IOMMU
      scripts/config --enable CONFIG_VIRTIO_CONSOLE
      scripts/config --enable CONFIG_VSOCKETS
      scripts/config --enable CONFIG_VHOST_NET
      scripts/config --enable CONFIG_NET_9P
      scripts/config --enable CONFIG_NET_9P_VIRTIO
      scripts/config --enable CONFIG_9P_FS
      scripts/config --enable CONFIG_9P_FS_POSIX_ACL

      # extra
      scripts/config --enable CONFIG_OVERLAY_FS
      scripts/config --enable CONFIG_SQUASHFS
      scripts/config --enable CONFIG_SQUASHFS_ZLIB

      sed -i 's/=m$/=n/' .config
    ''
    + lib.optionalString (stdenv.hostPlatform.isMips || stdenv.hostPlatform.isSparc) ''
      scripts/config --enable CONFIG_USER_NS
      scripts/config --enable CONFIG_CGROUPS
    ''
    + lib.optionalString stdenv.hostPlatform.isBigEndian ''
      scripts/config --enable CONFIG_CPU_BIG_ENDIAN
      scripts/config --disable CONFIG_CPU_LITTLE_ENDIAN
    ''
    + lib.optionalString stdenv.hostPlatform.isLittleEndian ''
      scripts/config --disable CONFIG_CPU_BIG_ENDIAN
      scripts/config --enable CONFIG_CPU_LITTLE_ENDIAN
    ''
    + lib.optionalString (kernelConfig != null) ''

    '';

  installPhase = ''
    make scripts_gdb

    mkdir -p $out/scripts/
    cp ./vmlinux-gdb.py $out/
    cp -rf ./scripts/gdb/ $out/scripts/

    cp vmlinux $out/vmlinux
    cp vmlinux $out/vmlinux.debug
    cp .config $out/
    cp System.map $out/

    cp arch/*/boot/Image $out/ || true
    cp arch/*/boot/bzImage $out/ || true
    cp arch/*/boot/zImage $out/ || true
    cp -rf arch/*/boot/dts/ $out/ || true

    ${stdenv.cc.targetPrefix}strip --strip-debug $out/vmlinux
  '';
})
