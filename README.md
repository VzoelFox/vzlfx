# Morph Compiler v0.1 - Foundation Toolchain

**Status:** FROZEN (v0.1 - Foundation Release)

Morph adalah native compiler untuk ISA x86-64 yang ditulis dalam pure assembly, mengikuti filosofi "Code Honesty" - tanpa abstraksi tersembunyi.

## Quick Start

```bash
# Build compiler
./build.sh

# Run program (JIT mode)
./morph program.fox

# Compile to native binary
./morph -o output.morph program.fox
./output.morph
```

## Features

✓ **Native Compilation** - Generate native x86-64 ELF executables
✓ **JIT Execution** - Direct in-memory execution for development
✓ **Code Honesty** - Pure assembly implementation, no hidden magic
✓ **ISA Complete** - 100+ instructions covering general-purpose programming
✓ **Self-Hostable** - Foundation ready for compiler written in .fox

## Architecture

```
morph (30KB native binary)
├─ ISA Interpreter/JIT Engine
├─ ELF64 Binary Generator
├─ Instruction Registry (Brainlib)
└─ Standard I/O Functions (seer.*)
```

## File Format

**Input:** `.fox` files
```
VZOELFOX
nop
mov.r64.imm64
add.r64.r64
ret
```

**Output:** `.morph` files (ELF64 executables)

## ISA Coverage

- **Arithmetic:** add, sub, mul, div, inc, dec
- **Logic:** and, or, xor, not, shl, shr
- **Control:** cmp, test, jmp, je, jne, jl, jg, call, ret, nop
- **Memory:** mov, lea, push, pop
- **System:** syscall wrappers

Full ISA definition: `Brainlib/*.json`

## Repository Structure

```
vzlfx/                      # FROZEN - Foundation toolchain
├─ morph                    # Compiler binary (build output)
├─ boot/
│  ├─ loader.asm           # Entry point & file I/O
│  └─ runner.asm           # Code generator & JIT engine
├─ Brainlib/               # ISA definition (JSON)
├─ seer/                   # Standard I/O library
├─ utils/
│  ├─ format/              # ELF64 & ASM writers
│  └─ string/              # String utilities
└─ tools/
   ├─ gen_consts_fixed.sh  # Brainlib → assembly converter
   └─ build.sh             # Build system
```

## Usage Examples

### Example 1: Execute Directly (JIT)
```bash
echo "VZOELFOX nop" > hello.fox
./morph hello.fox
```

### Example 2: Compile to Binary
```bash
./morph -o hello hello.fox
./hello  # Native executable
```

## Dependencies

- **FASM 1.73.32** (included in `fasm/` directory)
- **Linux x86-64** (kernel 3.0+)

## Building

```bash
git clone https://github.com/VzoelFox/vzlfx
cd vzlfx
./build.sh
```

## Development Workflow

**This repository is FROZEN at v0.1**

Future development happens in **separate repositories:**
- `morphx86_64` - High-level .fox language compiler
- `morph-stdlib` - Standard library written in .fox
- `morph-tools` - Tooling ecosystem

This repo provides the **foundation binary** only.

## ABI Specification

**Calling Convention:** System V AMD64
**Syscall Interface:** Direct Linux syscalls
**Binary Format:** ELF64 statically linked
**Entry Point:** 0x400078

See `ROADMAP_SELFHOST.md` for self-hosting strategy.

## License

MIT License - See LICENSE file

## Version History

**v0.1 (2026-01-22)** - Foundation Release
- ✓ Native x86-64 code generation
- ✓ ELF64 binary output
- ✓ JIT execution mode
- ✓ Complete ISA (100+ instructions)
- ✓ Pure assembly implementation
- ⚠ Known issue: loader cleanup segfault (non-critical)

---

**Philosophy:** Code Honesty - Every byte is accountable, every operation is transparent.
