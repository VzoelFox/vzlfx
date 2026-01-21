format ELF64 executable 3
segment readable executable
entry start
start:
    pop rdi
    mov rsi, rsp
    call main
    mov rax, 60
    xor rdi, rdi
    syscall
ANSI_RED equ str_ansi_red
ANSI_GREEN equ str_ansi_green
ANSI_YELLOW equ str_ansi_yellow
ANSI_RESET equ str_ansi_reset
    push rdx
    push rax
    mov rdx, rsi    ; Panjang ke RDX
    mov rsi, rdi    ; Buffer ke RSI
    mov rdi, 1      ; STDOUT ke RDI
    mov rax, 1      ; sys_write
    syscall
    pop rax
    pop rdx
    ret
    push rdi
    push rsi
    push rcx
    push rdx
    push rax
    mov rsi, rdi    ; Simpan pointer awal di RSI (untuk syscall nanti)
    xor rcx, rcx    ; Counter = 0
    .loop_len:
    cmp byte [rdi], 0   ; Cek null
    je .done_len
    inc rdi
    inc rcx
    jmp .loop_len
    .done_len:
    mov rdx, rcx    ; Panjang ke RDX
    mov rdi, 1      ; STDOUT ke RDI
    mov rax, 1      ; SYS_WRITE
    syscall
    pop rax
    pop rdx
    pop rcx
    pop rsi
    pop rdi
    ret
    push rdi
    push rsi
    push rdx
    push rax
    push 0x0A       ; Push 10 (newline)
    mov rsi, rsp    ; RSI menunjuk ke stack
    mov rdx, 1      ; Panjang 1 byte
    mov rdi, 1      ; STDOUT
    mov rax, 1      ; SYS_WRITE
    syscall
    pop rax         ; Bersihkan 0x0A dari stack (ke RAX sementara)
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret
    push rdi
    push rsi
    push rdx
    push rcx
    push rax
    push r8
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov r8, rsp     ; r8 menunjuk ke buffer start
    add r8, 20      ; Mulai dari belakang buffer
    mov byte [r8], 0 ; Null terminator (opsional, kita pakai length)
    mov rax, rdi    ; Nilai yang akan dibagi
    mov rcx, 10     ; Pembagi
    xor rsi, rsi    ; Counter digit
    cmp rax, 0
    jge .process_digit
    neg rax         ; Jadikan positif
    push rax
    push rdi
    push rsi
    push rdx
    mov rdi, str_0    ; TODO: Ini harus pointer ke string str_0, anggap compiler handle literal
    push 0x2D       ; '-'
    mov rsi, rsp
    mov rdx, 1
    mov rdi, 1
    mov rax, 1
    syscall
    pop rax         ; clean stack
    pop rdx
    pop rsi
    pop rdi
    pop rax
    .process_digit:
    xor rdx, rdx    ; Clear sisa bagi
    div rcx         ; rax / 10 -> rax=quotient, rdx=remainder
    add dl, '0'     ; Convert ke ASCII
    dec r8          ; Mundur pointer buffer
    mov [r8], dl    ; Simpan digit
    inc rsi         ; Tambah panjang
    test rax, rax   ; Cek jika habis
    jnz .process_digit
    mov rdx, rsi    ; Panjang
    mov rsi, r8     ; Pointer buffer (posisi terakhir)
    mov rdi, 1      ; Stdout
    mov rax, 1      ; Syscall Write
    syscall
    mov rsp, rbp    ; Restore stack lokal
    pop rbp
    pop r8
    pop rax
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret
    push rdi
    push rsi
    push rdx
    push rcx
    push rax
    push rbp
    mov rbp, rsp
    push 0x7830     ; str_1 (Little Endian: '0' low, 'x' high? No, '0'=0x30, 'x'=0x78)
    mov rsi, rsp
    mov rdx, 2
    mov rdi, 1
    mov rax, 1
    syscall
    pop rax         ; Clean str_2
    sub rsp, 16
    mov rsi, rsp    ; Pointer buffer
    add rsi, 16     ; Mulai dari ujung
    mov rax, [rbp+40] ; Ambil RDI asli (dari push rdi paling atas... wait offsetnya 40?
    mov rax, [rbp+40]
    mov rcx, 16     ; 16 digit hex
    .hex_loop:
    dec rsi
    mov rdx, rax
    and rdx, 0xF    ; Ambil 4 bit terakhir
    cmp dl, 9
    jg .hex_alpha
    add dl, '0'
    jmp .hex_store
    .hex_alpha:
    add dl, 'A'-10
    .hex_store:
    mov [rsi], dl
    shr rax, 4      ; Geser
    dec rcx
    jnz .hex_loop
    mov rdx, 16
    mov rdi, 1
    mov rax, 1
    syscall
    mov rsp, rbp
    pop rbp
    pop rax
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret
seer.linter.print_error:
    push rbp
    mov rbp, rsp
    push rdi    ; Code ID
    push rsi    ; Filename
    push rdx    ; Line Number
    push rcx    ; Column Number
    push r8     ; Snippet
    mov rdi, ANSI_RED
    call seer.print.text
    mov rdi, str_3
    call seer.print.text
    mov rdi, [rbp-8]
    call seer.print.text
    mov rdi, str_4
    call seer.print.text
    mov rdi, ANSI_RESET
    call seer.print.text
    call seer.print.nl
    mov rdi, str_5
    call seer.print.text
    mov rdi, [rbp-16] ; Filename
    call seer.print.text
    mov rdi, str_6
    call seer.print.text
    mov rdi, [rbp-24]
    call seer.print.int
    mov rdi, str_7
    call seer.print.text
    mov rdi, [rbp-32]
    call seer.print.int
    call seer.print.nl
    mov rdi, str_8
    call seer.print.text
    call seer.print.nl
    mov rdi, str_9
    call seer.print.text
    mov rdi, [rbp-40]  ; Snippet
    call seer.print.text
    call seer.print.nl
    mov rdi, str_10
    call seer.print.text
    mov rdi, ANSI_YELLOW
    call seer.print.text
    mov rdi, str_11
    call seer.print.text
    mov rdi, ANSI_RESET
    call seer.print.text
    call seer.print.nl
    leave
    ret
    push rdi
    push rsi
    push rbx
    push rcx
    .loop_cmp:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .diff
    cmp al, 0       ; End of string?
    je .same
    inc rdi
    inc rsi
    jmp .loop_cmp
    .diff:
    mov rax, 0
    jmp .done
    .same:
    mov rax, 1
    .done:
    pop rcx
    pop rbx
    pop rsi
    pop rdi
    ret
    push rdi
    push rsi
    push rbx
    push rcx
    push rdx
    mov rcx, rdx    ; Counter
    test rcx, rcx
    jz .same_len    ; Length 0 = same
    .loop_cmp_len:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .diff_len
    inc rdi
    inc rsi
    dec rcx
    jnz .loop_cmp_len
    .same_len:
    mov rax, 1
    jmp .done_len
    .diff_len:
    mov rax, 0
    .done_len:
    pop rdx
    pop rcx
    pop rbx
    pop rsi
    pop rdi
    ret
seer.string.utf8_decode:
    push rbx
    push rdx
    xor rax, rax
    mov al, [rdi]
    test al, 0x80
    jz .utf1
    mov bl, al
    and bl, 0xE0
    cmp bl, 0xC0
    je .utf2
    mov bl, al
    and bl, 0xF0
    cmp bl, 0xE0
    je .utf3
    mov bl, al
    and bl, 0xF8
    cmp bl, 0xF0
    je .utf4
    jmp .utf_err
    .utf1:
    mov rcx, 1
    jmp .done
    .utf2:
    mov rcx, 2
    and al, 0x1F    ; Ambil 5 bit lower
    shl eax, 6      ; Geser
    mov bl, [rdi+1] ; Byte 2
    and bl, 0xC0    ; Cek header 10xxxxxx
    cmp bl, 0x80
    jne .utf_err
    mov bl, [rdi+1]
    and bl, 0x3F    ; Ambil 6 bit
    or al, bl       ; Gabung
    jmp .done
    .utf3:
    mov rcx, 3
    and al, 0x0F    ; Ambil 4 bit
    shl eax, 12     ; Geser
    mov bl, [rdi+1]
    test bl, 0x80
    jz .utf_err
    and bl, 0x3F
    shl ebx, 6
    or eax, ebx
    mov bl, [rdi+2]
    test bl, 0x80
    jz .utf_err
    and bl, 0x3F
    or eax, ebx
    jmp .done
    .utf4:
    mov rcx, 4
    and al, 0x07    ; Ambil 3 bit
    shl eax, 18
    mov bl, [rdi+1]
    and bl, 0x3F
    shl ebx, 12
    or eax, ebx
    mov bl, [rdi+2]
    and bl, 0x3F
    shl ebx, 6
    or eax, ebx
    mov bl, [rdi+3]
    and bl, 0x3F
    or eax, ebx
    jmp .done
    .utf_err:
    mov rax, 0xFFFD ; Replacement Char
    mov rcx, 1
    .done:
    pop rdx
    pop rbx
    ret
seer.string.utf8_next:
    push rax
    push rcx
    call seer.string.utf8_decode
    add rdi, rcx
    pop rcx
    pop rax
    ret
main:
    push rbp
    mov rbp, rsp
    cmp rdi, 2
    jge .args_ok
    mov rdi, str_12
    call seer.print.text
    call seer.print.nl
    jmp .exit_err
    .args_ok:
    mov rbx, [rsi+8]    ; rbx = filename pointer
    mov rdi, str_13
    call seer.print.text
    mov rdi, rbx
    call seer.print.text
    call seer.print.nl
    mov rdi, rbx
    mov rsi, 0      ; O_RDONLY
    mov rdx, 0
    mov rax, 2      ; SYS_OPEN
    syscall
    cmp rax, 0
    jl .err_open
    mov r12, rax    ; Simpan FD di r12
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
    mov rdi, r12        ; fd
    mov rsi, r13        ; buffer
    mov rdx, 1048576    ; count
    mov rax, 0          ; SYS_READ
    syscall
    mov r14, rax        ; Simpan bytes read di r14
    mov rdi, r12
    mov rax, 3          ; SYS_CLOSE
    syscall
    mov rdi, str_14
    call seer.print.text
    mov rdi, r14
    call seer.print.int
    call seer.print.nl
    mov rsi, r13        ; Current ptr
    mov rcx, r14        ; Remaining bytes
    add rcx, rsi        ; End ptr
    .scan_loop:
    cmp rsi, rcx
    jge .scan_done
    mov al, [rsi]
    cmp al, 32
    je .skip_char
    cmp al, 9
    je .skip_char
    cmp al, 10
    je .skip_char
    mov rbx, rsi    ; Start Token
    .token_loop:
    inc rsi
    cmp rsi, rcx
    jge .token_end
    mov al, [rsi]
    cmp al, 32
    je .token_end
    cmp al, 9
    je .token_end
    cmp al, 10
    je .token_end
    jmp .token_loop
    .token_end:
    push rsi
    push rcx
    mov rdi, str_15
    call seer.print.text
    mov rdi, rbx    ; Start
    mov rdx, rsi
    sub rdx, rbx    ; Length
    call seer.print.raw
    mov rdi, str_16
    call seer.print.text
    call seer.print.nl
    pop rcx
    pop rsi
    jmp .scan_loop
    .skip_char:
    inc rsi
    jmp .scan_loop
    .scan_done:
    mov rdi, str_17
    call seer.print.text
    call seer.print.nl
    leave
    ret
    .err_open:
    mov rdi, str_18
    call seer.print.text
    call seer.print.nl
    jmp .exit_err
    .err_mem:
    mov rdi, str_19
    call seer.print.text
    call seer.print.nl
    jmp .exit_err
    .exit_err:
    mov rdi, 1
    mov rax, 60
    syscall

segment readable writable
str_ansi_red db 0x1b, "[31m", 0
str_ansi_green db 0x1b, "[32m", 0
str_ansi_yellow db 0x1b, "[33m", 0
str_ansi_reset db 0x1b, "[0m", 0
str_0 db "-", 0
str_1 db "0x", 0
str_2 db "0x", 0
str_3 db "ERROR [", 0
str_4 db "]: ", 0
str_5 db "  --> ", 0
str_6 db ":", 0
str_7 db ":", 0
str_8 db "   | ", 0
str_9 db "   | ", 0
str_10 db "   | ", 0
str_11 db "^ Di sini", 0
str_12 db "Usage: loader <file.fox>", 0
str_13 db "Loading: ", 0
str_14 db "Read bytes: ", 0
str_15 db "Token: [", 0
str_16 db "]", 0
str_17 db "Loader finished.", 0
str_18 db "Error: Cannot open file", 0
str_19 db "Error: Memory allocation failed", 0
