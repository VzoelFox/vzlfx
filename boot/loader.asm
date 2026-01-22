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

    ; Cek argc >= 2 (progname + filename)
    cmp rdi, 2
    jge .args_ok

    ; Error: Usage
    mov rdi, msg_usage
    call seer.print.text
    call seer.print.nl
    jmp .exit_err

    .args_ok:
    ; Ambil argv[1]
    ; rsi adalah pointer ke array pointer (char**)
    ; [rsi] = argv[0], [rsi+8] = argv[1]
    mov rbx, [rsi+8]    ; rbx = filename pointer

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

    mov rdi, msg_done
    call seer.print.text
    call seer.print.nl

    leave
    ret

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
include 'runner.asm'

segment readable writable
include '../Brainlib/brainlib.inc'
    msg_usage       db "Usage: loader <file.fox>", 0
    msg_loading     db "Loading: ", 0
    msg_read_bytes  db "Read bytes: ", 0
    msg_token_start db "Token: [", 0
    msg_token_end   db "]", 0
    msg_done        db "Loader finished.", 0
    msg_err_open    db "Error: Cannot open file", 0
    msg_err_mem     db "Error: Memory allocation failed", 0
    msg_err_format  db "Error: File too short", 0
    msg_err_magic   db "Error: Invalid Magic Number. Expected VZOELFOX", 0
    magic_sig       db "VZOELFOX", 0
    msg_version     db "MorphLoader v0.1.0", 0
    arg_version_short db "-v", 0
    arg_version_long  db "--version", 0
