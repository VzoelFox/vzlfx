; Morph Native Loader (Bootstrapper)
; [AI_HINT: Membaca file sumber ke memori dan melakukan parsing token dasar]

format ELF64 executable 3
segment readable executable
entry start

start:
    ; Initialize Stack Frame for main
    pop rdi      ; argc (pop from stack)
    mov rsi, rsp ; argv (stack pointer now points to argv[0])

    call main

    ; Exit
    mov rax, 60
    xor rdi, rdi
    syscall

main:
    ; Input: rdi (argc), rsi (argv)
    push rbp
    mov rbp, rsp
    push r12
    push r13

    ; Save argc, argv to callee-saved registers
    mov r12, rdi        ; r12 = argc
    mov r13, rsi        ; r13 = argv

    ; Debug entry
    push rdi
    push rsi
    mov rdi, msg_debug_main
    call seer.print.text
    call seer.print.nl
    pop rsi
    pop rdi

    ; Parse arguments
    ; Format 1: ./loader input.fox           (argc=2, JIT mode)
    ; Format 2: ./loader -o output input.fox (argc=4, compile mode)

    ; Debug argc
    push rdi
    push rsi
    mov rdi, msg_debug_argc
    call seer.print.text
    mov rdi, r12
    call seer.print.int
    call seer.print.nl
    pop rsi
    pop rdi

    cmp r12, 4
    je .parse_compile_mode
    cmp r12, 2
    jge .parse_jit_mode

    ; Error: Usage
    mov rdi, msg_usage
    call seer.print.text
    call seer.print.nl
    jmp .exit_err

.parse_compile_mode:
    push rdi
    push rsi
    mov rdi, msg_debug_compile
    call seer.print.text
    call seer.print.nl
    pop rsi
    pop rdi

    ; Check if argv[1] == "-o"
    mov rdi, [r13+8]    ; argv[1]

    push rdi
    push rsi
    mov rdi, msg_debug_arg1
    call seer.print.text
    mov rdi, [r13+8]
    call seer.print.text
    call seer.print.nl
    pop rsi
    pop rdi

    lea rsi, [flag_output]

    push rdi
    push rsi
    mov rdi, msg_debug_before_strcmp
    call seer.print.text
    call seer.print.nl
    pop rsi
    pop rdi

    call seer.string.equals

    push rdi
    push rsi
    mov rdi, msg_debug_after_strcmp
    call seer.print.text
    call seer.print.nl
    pop rsi
    pop rdi

    cmp rax, 1
    jne .usage_error

    push rdi
    push rsi
    mov rdi, msg_debug_set_mode
    call seer.print.text
    call seer.print.nl
    pop rsi
    pop rdi

    ; Set compile mode
    mov byte [compile_only_mode], 1

    ; Save output filename (argv[2])
    mov rax, [r13+16]   ; argv[2]
    mov [output_filename], rax

    ; Input filename is argv[3]
    mov rbx, [r13+24]   ; argv[3]

    push rdi
    push rsi
    mov rdi, msg_debug_args_set
    call seer.print.text
    call seer.print.nl
    pop rsi
    pop rdi

    jmp .args_parsed

.parse_jit_mode:
    ; JIT mode - argv[1] is input filename
    mov rbx, [r13+8]    ; argv[1]

.args_parsed:
    ; rbx = input filename

    ; Cek apakah flag version?
    mov rdi, arg_version_short ; "-v"
    mov rsi, rbx
    call seer.string.equals
    cmp rax, 1
    je .print_version

    mov rdi, arg_version_long ; "--version"
    mov rsi, rbx
    call seer.string.equals
    cmp rax, 1
    je .print_version

    ; Print info loading
    mov rdi, msg_loading
    call seer.print.text
    mov rdi, rbx
    call seer.print.text
    call seer.print.nl

    ; --- 1. Open File ---
    ; sys.fs.open(filename, O_RDONLY, 0)
    mov rdi, rbx
    mov rsi, 0      ; O_RDONLY
    mov rdx, 0
    mov rax, 2      ; SYS_OPEN
    syscall

    cmp rax, 0
    jl .err_open

    mov r12, rax    ; Simpan FD di r12

    ; --- 2. Read File to Memory ---
    ; Alokasi Buffer (mmap)
    ; sys.mem.mmap(0, 1MB, PROT_READ|WRITE, MAP_PRIVATE|ANONYMOUS, -1, 0)
    ; PROT_READ|WRITE = 3, MAP_PRIVATE|ANONYMOUS = 0x22

    mov rdi, 0          ; addr = NULL
    mov rsi, 1048576    ; len = 1MB
    mov rdx, 3          ; prot = RW
    mov r10, 34         ; flags = MAP_PRIVATE | MAP_ANONYMOUS (0x22)
    mov r8, -1          ; fd = -1
    mov r9, 0           ; offset = 0
    mov rax, 9          ; SYS_MMAP
    syscall

    cmp rax, 0
    jle .err_mem

    mov r13, rax        ; Simpan Buffer Pointer di r13

    ; Read Content
    mov rdi, r12        ; fd
    mov rsi, r13        ; buffer
    mov rdx, 1048576    ; count
    mov rax, 0          ; SYS_READ
    syscall

    mov r14, rax        ; Simpan bytes read di r14

    ; Close File
    mov rdi, r12
    mov rax, 3          ; SYS_CLOSE
    syscall

    mov rdi, msg_read_bytes
    call seer.print.text
    mov rdi, r14
    call seer.print.int
    call seer.print.nl

    ; --- 3. Verify Magic Number (VZOELFOX) ---
    ; Header: [0-7] = "VZOELFOX"
    ; Cek panjang file minimal 8
    cmp r14, 8
    jl .err_format

    mov rsi, r13        ; Buffer Ptr
    mov rdi, magic_sig  ; "VZOELFOX"
    mov rdx, 8
    call seer.string.equals_len

    cmp rax, 1
    jne .err_magic

    ; Magic Valid - Skip Header
    add r13, 8
    sub r14, 8

    ; --- 4. Transfer to Runner ---
    ; Payload di r13, Size di r14
    mov rdi, r13
    mov rsi, r14
    call runner_start

    ; --- 5. Check if compile mode ---
    cmp byte [compile_only_mode], 1
    je .compile_output

    ; JIT mode - already executed
    mov rdi, msg_done
    call seer.print.text
    call seer.print.nl
    pop r13
    pop r12
    leave
    ret

.compile_output:
    ; Debug: print compile mode message
    push rbx
    mov rdi, msg_compiling
    call seer.print.text
    call seer.print.nl
    pop rbx

    ; Write compiled binary
    mov rdi, [output_filename]
    mov rsi, [generated_code_ptr]
    mov rdx, [generated_code_size]

    ; Debug: print code info
    push rdi
    push rsi
    push rdx
    mov rdi, msg_code_info
    call seer.print.text
    mov rdi, [rsp]     ; rdx = size
    call seer.print.int
    call seer.print.nl
    pop rdx
    pop rsi
    pop rdi

    call seer.format.elf64_write

    cmp rax, 0
    jne .err_write

    mov rdi, msg_output_written
    call seer.print.text
    mov rdi, [output_filename]
    call seer.print.text
    call seer.print.nl

    pop r13
    pop r12
    leave
    ret

.err_write:
    mov rdi, msg_err_write
    call seer.print.text
    call seer.print.nl
    jmp .exit_err

.usage_error:
    mov rdi, msg_usage
    call seer.print.text
    call seer.print.nl
    jmp .exit_err

    .err_open:
        mov rdi, msg_err_open
        call seer.print.text
        call seer.print.nl
        jmp .exit_err

    .err_mem:
        mov rdi, msg_err_mem
        call seer.print.text
        call seer.print.nl
        jmp .exit_err

    .err_format:
        mov rdi, msg_err_format
        call seer.print.text
        call seer.print.nl
        jmp .exit_err

    .err_magic:
        mov rdi, msg_err_magic
        call seer.print.text
        call seer.print.nl
        jmp .exit_err

    .print_version:
        mov rdi, msg_version
        call seer.print.text
        call seer.print.nl
        mov rdi, 0
        mov rax, 60
        syscall

    .exit_err:
        mov rdi, 1
        mov rax, 60
        syscall


; --- Includes (Code) ---
include '../seer/print/std.asm'
include '../utils/string/compare.asm'
include '../utils/string/utf.asm'
include '../utils/format/elf64_linux.asm'
include 'runner.asm'

segment readable writable
include '../Brainlib/brainlib.inc'
    msg_usage       db "Usage: loader <file.fox> OR loader -o <output> <input.fox>", 0
    msg_debug_main db "DEBUG: Entered main", 0
    msg_debug_argc db "DEBUG: argc = ", 0
    msg_debug_compile db "DEBUG: Parsing compile mode", 0
    msg_debug_arg1 db "DEBUG: argv[1] = ", 0
    msg_debug_before_strcmp db "DEBUG: Before strcmp", 0
    msg_debug_after_strcmp db "DEBUG: After strcmp", 0
    msg_debug_set_mode db "DEBUG: Setting compile mode", 0
    msg_debug_args_set db "DEBUG: Args set, rbx = input file", 0
    msg_loading     db "Loading: ", 0
    msg_read_bytes  db "Read bytes: ", 0
    msg_token_start db "Token: [", 0
    msg_token_end   db "]", 0
    msg_done        db "Loader finished.", 0
    msg_compiling   db "Compiling to binary...", 0
    msg_code_info   db "Generated code size: ", 0
    msg_output_written db "Output written: ", 0
    msg_err_open    db "Error: Cannot open file", 0
    msg_err_mem     db "Error: Memory allocation failed", 0
    msg_err_format  db "Error: File too short", 0
    msg_err_magic   db "Error: Invalid Magic Number. Expected VZOELFOX", 0
    msg_err_write   db "Error: Failed to write output file", 0

    flag_output     db "-o", 0

    output_filename dq 0

    ; Compile mode globals (used by runner.asm)
    compile_only_mode   db 0                    ; 0=execute, 1=compile_only
    generated_code_ptr  dq 0                    ; Pointer to generated code
    generated_code_size dq 0                    ; Size of generated code
    magic_sig       db "VZOELFOX", 0
    msg_version     db "MorphLoader v0.1.0", 0
    arg_version_short db "-v", 0
    arg_version_long  db "--version", 0
