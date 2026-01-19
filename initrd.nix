{
  lib,
  stdenv,
  writeScript,
  makeInitrd,
  cacert,
  pkgsStatic,
  buildEnv,
  busybox,
}:
let
  rootfs = buildEnv {
    name = "rootfs-env";
    paths = map lib.getBin [
      busybox
    ];
    pathsToLink = [
      "/bin"
      "/sbin"
    ];
  };

  defaultReadonlyPartition = if stdenv.hostPlatform.isSparc then "/dev/sda" else "/dev/vda";
  defaultStoragePartition = if stdenv.hostPlatform.isSparc then "/dev/sdb" else "/dev/vdb";

  init = writeScript "init" ''
    #! /bin/ash -e

    export PATH=/bin:/sbin
    mkdir -p /proc /sys /dev
    mount -t proc none /proc
    mount -t sysfs none /sys
    mount -t debugfs none /sys/kernel/debug
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
    mount -t 9p -o trans=virtio shared /mnt || true
    # mount -t virtiofs shared /mnt

    ifconfig lo up
    udhcpc

    if [ -e ${defaultReadonlyPartition} ]; then
        exec setsid cttyhack /init2
    else
        if [ -e /bin/bash ]; then
            exec setsid cttyhack /bin/bash
        else
            exec setsid cttyhack /bin/sh
        fi
    fi
  '';

  init2 = writeScript "init2" ''
    #! /bin/ash -e

    export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

    mkdir -p /new_root
    mount -t tmpfs tmpfs /new_root
    mkdir -p /new_root/lower /new_root/upper/upper /new_root/upper/work /new_root/merged
    mount -t erofs ${defaultReadonlyPartition} /new_root/lower
    if [ -e ${defaultStoragePartition} ]; then
        mount -t ext4 ${defaultStoragePartition} /new_root/upper
        mkdir -p /new_root/upper/upper /new_root/upper/work
    fi

    mount -t overlay overlay -o lowerdir=/new_root/lower,upperdir=/new_root/upper/upper,workdir=/new_root/upper/work /new_root/merged
    mkdir -p /new_root/merged/proc /new_root/merged/dev /new_root/merged/sys /new_root/merged/run /new_root/merged/tmp /new_root/merged/mnt
    mount --move /proc /new_root/merged/proc
    mount --move /dev /new_root/merged/dev
    mount --move /sys /new_root/merged/sys
    mount --move /run /new_root/merged/run
    mount --move /tmp /new_root/merged/tmp
    mount --move /mnt /new_root/merged/mnt || true

    rm -f /new_root/merged/etc/resolv.conf
    cp -f /etc/resolv.conf /new_root/merged/etc/resolv.conf

    if [ -e /new_root/merged/bin/bash ]; then
        exec switch_root /new_root/merged /bin/bash
    else
        exec switch_root /new_root/merged /bin/sh
    fi
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
        object = init2;
        symlink = "/init2";
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
