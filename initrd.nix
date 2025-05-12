{
  lib,
  writeScript,
  makeInitrd,
  cacert,
  pkgsStatic,
  buildEnv,
  busybox,
  dhcpcd,
  socat,
}:
let
  rootfs = buildEnv {
    name = "rootfs-env";
    paths = map lib.getBin [
      busybox
      #      socat
      #      dhcpcd
    ];
    pathsToLink = [
      "/bin"
      "/sbin"
    ];
  };

  init = writeScript "init" ''
    #! /bin/ash -e

    export PATH=/bin:/sbin
    mkdir -p /proc /sys /dev
    mount -t proc none /proc
    mount -t sysfs none /sys
    mount -t devtmpfs devtmpfs /dev

    ln -s /proc/self/fd /dev/fd
    ln -s /proc/self/fd/0 /dev/stdin
    ln -s /proc/self/fd/1 /dev/stdout
    ln -s /proc/self/fd/2 /dev/stderr

    echo 1 > /proc/sys/vm/panic_on_oom

    mkdir -p /etc
    echo -n > /etc/fstab

    mkdir -p /dev/pts /dev/shm /tmp /run /var
    mount -t cgroup2 none /sys/fs/cgroup
    mount -t devpts none /dev/pts
    mount -t tmpfs -o "mode=1777" none /dev/shm
    mount -t tmpfs -o "mode=1777" none /var
    mount -t tmpfs -o "mode=1777" none /tmp
    mount -t tmpfs -o "mode=755" none /run
    ln -sfn /run /var/run

    ln -sf /proc/mounts /etc/mtab
    echo "127.0.0.1 localhost" > /etc/hosts
    echo "nameserver 127.0.0.1" > /etc/resolv.conf
    echo "root:x:0:0::/root:/bin/sh" > /etc/passwd

    mkdir -p /etc/ssl/certs
    ln -s ${cacert.out}/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-bundle.crt

    # shared dir
    mkdir /mnt
    # mount -t 9p -o trans=virtio shared /mnt
    # mount -t virtiofs shared /mnt

    ifconfig lo up
    # ifconfig eth0 up
    # dhcpcd eth0

    setsid cttyhack /bin/sh
  '';

  initrd = makeInitrd {
    makeUInitrd = false;
    compressor = "zstd";
    contents = [
      {
        object = init;
        symlink = "/init";
      }
      {
        object = rootfs + "/bin";
        symlink = "/bin";
      }
      {
        object = rootfs + "/sbin";
        symlink = "/sbin";
      }
    ];
  };
in
initrd
