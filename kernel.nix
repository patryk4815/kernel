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
}:
stdenv.mkDerivation (finalAttrs: {
  name = "linux";
  version = "6.14.6";

  src = fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${finalAttrs.version}.tar.xz";
    hash = "sha256-IYF/GZjiIw+B9+T2Bfpv3LBA4U+ifZnCfdsWznSXl6k=";
  };

  buildInputs = [ ];

  nativeBuildInputs =
    [
      flex
      bison
      bc
      perl
      pkg-config
      python3Minimal
      elfutils
      openssl
    ]
    ++ lib.optionals stdenv.targetPlatform.isAarch32 [
      hexdump
      zstd
    ]
    ++ lib.optionals stdenv.targetPlatform.isMips32 [
      ubootTools
    ];
  strictDeps = true;
  dontStrip = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  env = {
    ARCH = "${stdenv.hostPlatform.linuxArch}";
    CROSS_COMPILE = "${stdenv.cc.targetPrefix}";
  };

  preBuild = let
    defconfig = if stdenv.hostPlatform.isMips32 then "malta_defconfig" else "defconfig";
  in ''
    buildFlagsArray+=("-j$NIX_BUILD_CORES")
    make ${defconfig}
    patchShebangs scripts/config
    scripts/config --enable CONFIG_FS_POSIX_ACL
    scripts/config --enable CONFIG_FUSE_FS
    scripts/config --enable CONFIG_VIRTIO_FS
    scripts/config --enable CONFIG_VIRTIO_VSOCKETS
    scripts/config --enable CONFIG_VIRTIO_BLK
    scripts/config --enable CONFIG_VIRTIO_NET
    scripts/config --enable CONFIG_VIRTIO_PCI
    scripts/config --enable CONFIG_VIRTIO_MEM
    scripts/config --enable CONFIG_VIRTIO_MMIO
    scripts/config --enable CONFIG_VIRTIO_IOMMU
    scripts/config --enable CONFIG_VSOCKETS
    scripts/config --enable CONFIG_VHOST_NET
    scripts/config --enable CONFIG_NET_9P
    scripts/config --enable CONFIG_NET_9P_VIRTIO
    scripts/config --enable CONFIG_9P_FS
    scripts/config --enable CONFIG_9P_FS_POSIX_ACL
    sed -i 's/=m$/=n/' .config
  '' + lib.optionalString stdenv.hostPlatform.isMips32 ''
    scripts/config --enable CONFIG_USER_NS
    scripts/config --enable CONFIG_CGROUPS
  '' + lib.optionalString stdenv.hostPlatform.isBigEndian ''
    scripts/config --enable CONFIG_CPU_BIG_ENDIAN
    scripts/config --disable CONFIG_CPU_LITTLE_ENDIAN
  '';

  installFlags = [
    "INSTALL_PATH=$(out)"
    "INSTALL_MOD_PATH=$(out)"
  ];

  preInstall = ''
    installFlagsArray+=("-j$NIX_BUILD_CORES")
  '';

  postInstall = ''
    cp vmlinux $out/
    cp .config $out/
    cp arch/*/boot/Image $out/ || true
    cp arch/*/boot/bzImage $out/ || true
    cp arch/*/boot/zImage $out/ || true
    cp -rf arch/*/boot/dts/ $out/ || true
  '';
})
