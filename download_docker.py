#!/usr/bin/env python3
import atexit
import hashlib
import json
import os
import shutil
import subprocess
import sys


def log(msg):
    print(msg, file=sys.stderr)


def image_exists(image_str: str, os_name: str, arch: str) -> bool:
    try:
        subprocess.run(
            [
                "skopeo",
                "inspect",
                f"docker-daemon:{image_str}",
                "--override-os", os_name,
                "--override-arch", arch,
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except subprocess.CalledProcessError:
        return False


if len(sys.argv) < 2:
    log("[ERROR] Missing required argument: OS/ARCH (e.g. linux/amd64)")
    sys.exit(1)

platform = sys.argv[1]
image = sys.argv[2] if len(sys.argv) >= 3 else "ubuntu:20.04"
refresh = len(sys.argv) >= 4 and sys.argv[3] == "--refresh"

# Split os/arch (linux/amd64 → os=linux, arch=amd64)
if "/" not in platform:
    log("[ERROR] Invalid platform format, expected OS/ARCH")
    sys.exit(1)
os_name, arch = platform.split("/")

xdg_cache = os.environ.get("XDG_CACHE_HOME")
home = os.environ.get("HOME")
base_cache_dir = ''

if xdg_cache:
    base_cache_dir = xdg_cache
elif home:
    base_cache_dir = os.path.join(home, ".cache")
else:
    log("[ERROR] Neither XDG_CACHE_HOME nor HOME is set — cannot determine cache directory.")
    sys.exit(1)

hash_input = f"{os_name}-{arch}-{image}".encode("utf-8")
hash_value = hashlib.sha256(hash_input).hexdigest()
cache_dir = os.path.join(base_cache_dir, "patryk4815-kernel", "images", hash_value)

if refresh and os.path.exists(cache_dir):
    shutil.rmtree(cache_dir)

os.makedirs(cache_dir, exist_ok=True)

# Cleanup cache_dir on failure
cleanup_needed = True
def cleanup_on_exit():
    if cleanup_needed and os.path.exists(cache_dir):
        shutil.rmtree(cache_dir)
atexit.register(cleanup_on_exit)

dst_layers_dir = os.path.join(cache_dir, "image.tar")
dst_erofs_file = os.path.join(cache_dir, "image.erofs")
dst_erofs_file_tmp = dst_erofs_file + ".tmp"
dst_config = os.path.join(cache_dir, "config.json")

if os.path.exists(dst_erofs_file):
    cleanup_needed = False
    print(dst_erofs_file)
    sys.exit(0)

log("[INFO] Downloading image...")
is_local_image = image_exists(image, os_name, arch)
subprocess.run(
    [
        "skopeo",
        "copy",
        "--insecure-policy",
        "--override-os", os_name,
        "--override-arch", arch,
        "--dest-decompress",
        f"docker-daemon:{image}" if is_local_image else f"docker://{image}",
        f"dir:{dst_layers_dir}",
    ],
    check=True,
    stdout=sys.stderr,
    # stdout=subprocess.DEVNULL,
)

manifest_path = os.path.join(dst_layers_dir, "manifest.json")
with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = json.load(f)

config_path = os.path.join(dst_layers_dir, manifest.get("config", {}).get("digest").split(":", maxsplit=1)[1])

# Verify we downloaded the correct platform
with open(config_path, "r", encoding="utf-8") as f:
    config = json.load(f)
    downloaded_os = config.get("os", "")
    downloaded_arch = config.get("architecture", "")

    if is_local_image:
        log(f"[INFO] Downloaded LOCAL image: {downloaded_os}/{downloaded_arch}")
    else:
        log(f"[INFO] Downloaded REMOTE image: {downloaded_os}/{downloaded_arch}")

    if downloaded_os != os_name or downloaded_arch != arch:
        log(f"[ERROR] Platform mismatch! Expected {os_name}/{arch}, got {downloaded_os}/{downloaded_arch}")
        sys.exit(1)

layers = []
for layer in manifest.get("layers", []):
    hash_typ, digest = layer["digest"].split(':', maxsplit=1)
    layer_path_tar = os.path.join(dst_layers_dir, digest)
    layer_path_erofs = layer_path_tar + ".erofs"

    log(f"[INFO] Converting to layer {digest} to erofs...")
    subprocess.run(
        [
            "mkfs.erofs",
            "--tar=f",
            "--aufs",
            "-Enoinline_data",
            layer_path_erofs,
            layer_path_tar
        ],
        check=True,
        stdout=sys.stderr,
        # stdout=subprocess.DEVNULL,
    )
    layers.append(layer_path_erofs)
    os.remove(layer_path_tar)

log("[INFO] Merging layers to erofs...")
subprocess.run(
    [
        "mkfs.erofs",
        "--aufs",
        "--ovlfs-strip=1",
        dst_erofs_file_tmp,
        *layers
    ],
    check=True,
    stdout=2,
    # stdout=subprocess.DEVNULL,
)

CHUNK_SIZE = 1024 * 1024
with open(dst_erofs_file_tmp, "ab") as f:
    for layer in layers:
        with open(layer, "rb") as flar:
            while True:
                chunk = flar.read(CHUNK_SIZE)
                if not chunk:
                    break
                f.write(chunk)
        os.remove(layer)

shutil.move(config_path, dst_config)
shutil.rmtree(dst_layers_dir)
shutil.move(dst_erofs_file_tmp, dst_erofs_file)

cleanup_needed = False
log(f"[INFO] Final squashfs file: {dst_erofs_file}")
print(dst_erofs_file)
