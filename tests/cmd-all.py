#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.pwntools
import json
import shlex
from typing import List

from pwn import *
import sys
import subprocess

context.log_level = 'info'

if len(sys.argv) != 2:
    print("Usage: ./cmd-all.py <cmd>")
    sys.exit(1)

cmd = sys.argv[1]

def get_vms() -> List[str]:
    res = subprocess.run(
        ["nix", "flake", "show", "--json"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    data = json.loads(res.stdout)
    attributes = data["packages"]["x86_64-linux"].keys()
    return [
        attribute
        for attribute in attributes
        if attribute.startswith("vm-")
    ]

def run_vm(cmd: str, attribute: str):
    p = process(["nix", "run", f".#{attribute}", "--accept-flake-config"])
    try:
        p.recvuntil(b'~ #', timeout=120)
        p.sendline(b'echo START')
        p.sendline(cmd.encode())
        p.sendline(b'echo END')
        p.sendline(b'exit')

        output = p.recvuntil(b'END', timeout=60)
        sidx = output.find(b'START')
        eidx = output.find(b'END')
        return output[sidx:eidx]
    finally:
        p.kill()


for attribute in get_vms():
    output = run_vm(cmd, attribute)
    print("VM output:")
    print(output.decode())
