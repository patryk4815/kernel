#!/usr/bin/env python3
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys


def log(msg):
    print(msg, file=sys.stderr)


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
cache_dir = os.path.join(base_cache_dir, "patryk4815-kernel", hash_value)

if refresh and os.path.exists(cache_dir):
    shutil.rmtree(cache_dir)

os.makedirs(cache_dir, exist_ok=True)

dst_layers_dir = os.path.join(cache_dir, "image.tar")
dst_erofs_file = os.path.join(cache_dir, "image.erofs")
dst_erofs_file_tmp = dst_erofs_file + ".tmp"
dst_config = os.path.join(cache_dir, "config.json")

if os.path.exists(dst_erofs_file):
    print(dst_erofs_file)
    sys.exit(0)

log("[INFO] Downloading image...")
subprocess.run(
    [
        "skopeo",
        "copy",
        "--insecure-policy",
        "--override-os", os_name,
        "--override-arch", arch,
        "--dest-decompress",
        f"docker://{image}",
        f"dir:{dst_layers_dir}",
    ],
    check=True,
    stdout=2,
    # stdout=subprocess.DEVNULL,
)

manifest_path = os.path.join(dst_layers_dir, "manifest.json")
with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = json.load(f)

config_path = os.path.join(dst_layers_dir, manifest.get("config", {}).get("digest").split(":", maxsplit=1)[1])

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
        stdout=2,
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

log(f"[INFO] Final squashfs file: {dst_erofs_file}")
print(dst_erofs_file)
