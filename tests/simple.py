#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.pwntools

from pwn import *
import sys

context.log_level = 'debug'

if len(sys.argv) != 2:
    print("Usage: ./simple.py <attribute>")
    sys.exit(1)

attribute = sys.argv[1]

p = process(["nix", "run", f".#{attribute}", "--accept-flake-config"])
p.recvuntil(b'~ #', timeout=120)
p.sendline(b'id; exit')

output = p.recvall(timeout=10)

# Sprawdź wynik
if b"uid=0(root) gid=0" in output:
    print("SUCCESS: Found expected output.")
    print("Received:")
    print(output[:30])
else:
    print("FAILURE: Expected output not found.")
    print("Received:")
    print(output)
    sys.exit(1)
