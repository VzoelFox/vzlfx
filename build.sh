#!/bin/bash
# build.sh - Pure Bash Build System

# 1. Generate Brainlib Constants
echo "[Build] Generating Brainlib constants..."
./tools/gen_consts.sh > Brainlib/brainlib.inc

# 2. Compile Loader
echo "[Build] Compiling Boot Loader..."
if command -v fasm &> /dev/null; then
    fasm boot/loader.asm loader
    if [ $? -eq 0 ]; then
        echo "[Build] Success: ./loader"
    else
        echo "[Build] Failed."
        exit 1
    fi
else
    echo "[Build] Error: FASM not found."
    exit 1
fi
