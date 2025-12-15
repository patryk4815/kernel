#!/usr/bin/env python3

import argparse
import json
import os
import shutil
import subprocess
import sys

KERNEL_DIR = os.getenv('KERNEL_DIR')
INITRD_DIR = os.getenv('INITRD_DIR')
RUN_ARGS = json.loads(os.getenv('RUN_ARGS'))

QEMU_BINARY = f"qemu-system-{RUN_ARGS.get("qemuArch")}"
QEMU_ARGS = RUN_ARGS.get("qemuArgs")
QEMU_NETWORK = RUN_ARGS.get("network")
QEMU_SHARED_DIR = RUN_ARGS.get("sharedDir")

DEFAULT_DOCKER_PLATFORM = RUN_ARGS.get("dockerPlatform")
DEFAULT_KERNEL_CMDLINE = ["panic=-1", "oops=panic"] + RUN_ARGS.get("kernelArgs", [])
DEFAULT_GDB_PORT = "1234"


def run_command(cmd):
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def main():
    parser = argparse.ArgumentParser(
        prog="run",
        description=(
            "Run a QEMU virtual machine with optional GDB debugging, "
            "Docker image backing storage, port forwarding, and resource limits."
        )
    )
    parser.add_argument(
        "--debug", "-d",
        action="store_true",
        help="Enable GDB debugging (QEMU gdbstub with -gdb and -S)"
    )
    parser.add_argument(
        "--nokaslr",
        action="store_true",
        help="Disable kernel address space layout randomization (adds 'nokaslr' to the kernel command line)"
    )
    parser.add_argument(
        "--platform",
        metavar="PLAT",
        default=DEFAULT_DOCKER_PLATFORM,
        help="Docker image platform, e.g. linux/amd64 (default: target-kernel)"
    )
    parser.add_argument(
        "-i",
        metavar="IMAGE",
        dest="docker_image",
        help="Docker image to download and attach as a virtio drive"
    )
    parser.add_argument(
        "-g",
        metavar="PORT",
        dest="gdb_port",
        default=DEFAULT_GDB_PORT,
        help=f"GDB server port (default: {DEFAULT_GDB_PORT})"
    )
    parser.add_argument(
        "-p",
        metavar="H:G",
        action="append",
        dest="port_forwards",
        help="Forward host port H to guest port G (Docker-style, can be repeated)"
    )
    parser.add_argument(
        "-v",
        metavar="HOST:GUEST",
        action="append",
        dest="volumes",
        help="Bind-mount a host directory into the guest (Docker-style volume syntax)"
    )
    parser.add_argument(
        "--memory",
        metavar="MEM",
        default="2G",
        help="Memory limit for the VM (Docker-style, e.g. 512M, 2G; default: 2G)"
    )
    parser.add_argument(
        "--cpus",
        metavar="N",
        default="1",
        help="Number of virtual CPUs (Docker-style; default: 1)"
    )
    args = parser.parse_args()

    kernel_cmdline = DEFAULT_KERNEL_CMDLINE.copy()
    qemu_extra_cmd = []
    port_forward_opts = []

    if args.port_forwards:
        for hp in args.port_forwards:
            host, guest = hp.split(":", 1)
            port_forward_opts.append(
                f"hostfwd=tcp::{int(host)}-:{int(guest)}"
            )

    if args.debug:
        print(f"gdbserver is listening on port :{args.gdb_port}")
        print("Please use the following VMLINUX file:")
        print(f"{KERNEL_DIR}/vmlinux.debug\n")

        if not args.nokaslr:
            print("KASLR is enabled. To disable it, use the --nokaslr option.")
            print(
                "Note: If KASLR is enabled, you will need to manually calculate "
                "the offset, because debug symbols from vmlinux will not work correctly."
            )

        qemu_extra_cmd.extend(["-gdb", f"tcp::{args.gdb_port}", "-S"])

    # ==== KASLR ====
    if args.nokaslr:
        kernel_cmdline.append("nokaslr")

    # ==== DOCKER IMAGE ====
    if args.docker_image:
        cmd = [
            "download_docker",
            args.platform,
            args.docker_image,
        ]
        rc, stdout, stderr = run_command(cmd)
        if rc != 0:
            print(f"Error downloading Docker image: exit code {rc}", file=sys.stderr)
            if stderr:
                print(stderr, file=sys.stderr)
            sys.exit(rc)

        if stdout:
            qemu_extra_cmd.extend([
                "-drive",
                f"file={stdout},file.locking=off,format=raw,if=virtio,readonly=on"
            ])

    # ==== QEMU COMMAND ====
    qemu_cmd = [
        QEMU_BINARY,
        "-m", args.memory,
        "-smp", args.cpus,
        "-nographic",
        "-no-reboot",
        "-append", " ".join(kernel_cmdline),
        "-initrd", os.path.join(INITRD_DIR, "initrd"),
    ]

    # VSOCK (linux only):
    # -device vhost-vsock-pci,guest-cid=3

    for cmd in QEMU_NETWORK:
        cmd = cmd.replace("@PORT_FORWARD@", ",".join(port_forward_opts))
        qemu_cmd.append(cmd)

    for cmd in QEMU_ARGS:
        cmd = cmd.replace("@KERNEL_DIR@", KERNEL_DIR)
        qemu_cmd.append(cmd)

    # for cmd in QEMU_SHARED_DIR:
    #     cmd = cmd.replace("@SHARED_DIR@", KERNEL_DIR)
    #     qemu_cmd.append(cmd)

    qemu_cmd.extend(qemu_extra_cmd)

    qemu_path = shutil.which(qemu_cmd[0])
    os.execvp(qemu_path, qemu_cmd)


if __name__ == "__main__":
    main()
