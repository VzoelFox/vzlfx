#!/bin/bash
# bootstrap.sh - Simulator Compiler/Runner untuk Native AI
# Mengubah .fox (dengan macro JSON) menjadi .asm (FASM/NASM syntax) lalu build & run.

SRC_FILE=$1
OUT_ASM="${SRC_FILE%.fox}.asm"
OUT_BIN="${SRC_FILE%.fox}"
SHIFT_ARGS=0

if [ -z "$SRC_FILE" ]; then
    echo "Usage: ./bootstrap.sh <source.fox> [args...]"
    exit 1
fi

# Detect if we are building the loader, we need to inject compare.fox too
EXTRA_LIBS=""
if [[ "$SRC_FILE" == *"loader.fox"* ]]; then
    EXTRA_LIBS="utils/string/compare.fox utils/string/utf.fox"
fi

echo "[Bootstrap] Compiling $SRC_FILE..."

python3 -c "
import sys
import re

def process_file(filepath):
    # Urutan file: Library Standard -> Helper -> User Code
    files = ['seer/print/std.fox', 'seer/tools/linter.fox']

    # Add extra libs if defined
    extra = '$EXTRA_LIBS'
    if extra:
        files.extend(extra.split())

    files.append(filepath)

    code_lines = []

    # 1. Read All Lines
    for fname in files:
        try:
            with open(fname, 'r') as f:
                code_lines.append(f'; --- Source {fname} ---')
                code_lines.extend(f.readlines())
        except FileNotFoundError:
            print(f'; Error: File {fname} not found')
            continue

    # 2. Process Lines & Extract Strings
    data_section = []
    text_section = []

    str_pattern = re.compile(r'\"([^\"]+)\"')
    str_counter = 0

    in_macro = False

    text_section.append('format ELF64 executable 3')
    text_section.append('segment readable executable')
    text_section.append('entry start')
    text_section.append('start:')

    # Main Entry Point Logic
    # Stack saat entry: [argc] [argv0] [argv1] ...
    # Kita perlu pass argc (rdi) dan argv (rsi) ke main
    text_section.append('    pop rdi')      # argc
    text_section.append('    mov rsi, rsp') # argv (ptr to stack top now)

    # Align stack if needed? (x64 ABI requires 16-byte align before call)
    # Entry stack is usually aligned, but after pop rdi it shifts by 8.
    # Simple check: (main doesn't use float usually, so it's fine for bootstrap)

    text_section.append('    call main')
    text_section.append('    mov rax, 60')
    text_section.append('    xor rdi, rdi')
    text_section.append('    syscall')

    # Add manual macros/constants
    text_section.append('ANSI_RED equ str_ansi_red')
    text_section.append('ANSI_GREEN equ str_ansi_green')
    text_section.append('ANSI_YELLOW equ str_ansi_yellow')
    text_section.append('ANSI_RESET equ str_ansi_reset')

    data_section.append('segment readable writable')
    data_section.append('str_ansi_red db 0x1b, \"[31m\", 0')
    data_section.append('str_ansi_green db 0x1b, \"[32m\", 0')
    data_section.append('str_ansi_yellow db 0x1b, \"[33m\", 0')
    data_section.append('str_ansi_reset db 0x1b, \"[0m\", 0')

    for line in code_lines:
        line = line.strip()
        if not line or line.startswith(';'):
            continue

        match = str_pattern.search(line)
        if match:
            content = match.group(1)
            label = f'str_{str_counter}'
            str_counter += 1
            data_section.append(f'{label} db \"{content}\", 0')
            line = line.replace(f'\"{content}\"', label)

        if line.startswith('fungsi '):
            func_name = line.split()[1]
            text_section.append(f'{func_name}:')
        elif line.startswith('tutup_fungsi'):
            pass
        elif 'kind=macro' in line:
            pass
        elif line.endswith('kind=macro action={'):
            name = line.split()[0]
            text_section.append(f'{name}:')
            in_macro = True
        elif line == '}':
            in_macro = False
            text_section.append('    ret')
        else:
            text_section.append(f'    {line}')

    for l in text_section:
        print(l)
    print('')
    for l in data_section:
        print(l)

process_file('$SRC_FILE')
" > "$OUT_ASM"

echo "[Bootstrap] Generated $OUT_ASM"

# Check for FASM
if command -v fasm &> /dev/null; then
    fasm "$OUT_ASM" "$OUT_BIN"
    if [ $? -eq 0 ]; then
        echo "[Bootstrap] Build Success."

        # Shift args to pass remaining to the binary
        shift # Skip source file arg

        echo "[Running] $OUT_BIN $@"
        echo "----------------------------------------"
        "./$OUT_BIN" "$@"
        echo "----------------------------------------"
    else
        echo "[Bootstrap] Build failed."
    fi
else
    echo "[Bootstrap] FASM not found. Please install FASM to run."
fi
