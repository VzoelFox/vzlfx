#!/bin/bash
# build.sh - Pure Bash Build System for Morph Compiler

# 1. Generate Brainlib Constants
echo "[Build] Generating Brainlib constants..."
./tools/gen_consts_fixed.sh > Brainlib/brainlib.inc

# 2. Compile Morph
echo "[Build] Compiling Morph Compiler..."
if [ -x "./fasm/fasm.x64" ]; then
    ./fasm/fasm.x64 boot/loader.asm morph
    if [ $? -eq 0 ]; then
        echo "[Build] Success: ./morph"
        echo "[Build] Binary size: $(du -h morph | cut -f1)"
    else
        echo "[Build] Failed."
        exit 1
    fi
else
    echo "[Build] Error: FASM not found. Please extract fasm-1.73.32.tgz"
    exit 1
fi
