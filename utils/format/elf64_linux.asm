; utils/format/elf64_linux.asm
; [AI_HINT: Generate minimal ELF64 executable for Linux x86-64]
; Code Honesty: Direct ELF64 binary generation, no hidden abstraction

seer.format.elf64_write:
    ; Input:
    ;   rdi = output filename (null-terminated string)
    ;   rsi = code buffer pointer
    ;   rdx = code size
    ; Output:
    ;   rax = 0 (success) or error code

    push rbp
    mov rbp, rsp
    sub rsp, 256        ; Local space for ELF header + program header

    ; Save inputs
    push rdi            ; [rbp-264] filename
    push rsi            ; [rbp-272] code buffer
    push rdx            ; [rbp-280] code size

    ; Calculate sizes
    mov r12, rdx        ; r12 = code size
    mov r13, 0x78       ; r13 = 120 = ELF header (64) + Program header (56)
    mov r14, r13
    add r14, r12        ; r14 = total file size

    ; Build ELF64 Header (64 bytes) on stack
    lea rdi, [rbp-64]

    ; ELF Magic + Class + Data + Version
    mov byte [rdi+0], 0x7F
    mov byte [rdi+1], 'E'
    mov byte [rdi+2], 'L'
    mov byte [rdi+3], 'F'
    mov byte [rdi+4], 2         ; ELFCLASS64
    mov byte [rdi+5], 1         ; ELFDATA2LSB (little endian)
    mov byte [rdi+6], 1         ; EV_CURRENT
    mov byte [rdi+7], 0         ; OSABI (SYSV)

    ; Padding (8 bytes)
    mov qword [rdi+8], 0

    ; e_type (ET_EXEC = 2)
    mov word [rdi+16], 2

    ; e_machine (EM_X86_64 = 62)
    mov word [rdi+18], 62

    ; e_version
    mov dword [rdi+20], 1

    ; e_entry (0x400000 + header size = 0x400078)
    mov rax, 0x400078
    mov qword [rdi+24], rax

    ; e_phoff (program header offset = 64)
    mov qword [rdi+32], 64

    ; e_shoff (no section headers = 0)
    mov qword [rdi+40], 0

    ; e_flags
    mov dword [rdi+48], 0

    ; e_ehsize (ELF header size = 64)
    mov word [rdi+52], 64

    ; e_phentsize (program header entry size = 56)
    mov word [rdi+54], 56

    ; e_phnum (number of program headers = 1)
    mov word [rdi+56], 1

    ; e_shentsize (section header size = 0)
    mov word [rdi+58], 0

    ; e_shnum (number of sections = 0)
    mov word [rdi+60], 0

    ; e_shstrndx
    mov word [rdi+62], 0

    ; Build Program Header (56 bytes) on stack
    lea rdi, [rbp-120]

    ; p_type (PT_LOAD = 1)
    mov dword [rdi+0], 1

    ; p_flags (PF_X | PF_R = 5)
    mov dword [rdi+4], 5

    ; p_offset (0)
    mov qword [rdi+8], 0

    ; p_vaddr (0x400000)
    mov qword [rdi+16], 0x400000

    ; p_paddr (0x400000)
    mov qword [rdi+24], 0x400000

    ; p_filesz (total file size)
    mov qword [rdi+32], r14

    ; p_memsz (total file size)
    mov qword [rdi+40], r14

    ; p_align (0x1000)
    mov qword [rdi+48], 0x1000

    ; Open output file (create, truncate, write-only)
    mov rdi, [rbp-264]  ; filename
    mov rsi, 0x241      ; O_CREAT | O_TRUNC | O_WRONLY (0x40 | 0x200 | 0x1)
    mov rdx, 0x1A4      ; permissions 0644 (rw-r--r--)
    mov rax, 2          ; sys_open
    syscall

    cmp rax, 0
    jl .error
    mov r15, rax        ; r15 = fd

    ; Write ELF header (64 bytes)
    mov rdi, r15
    lea rsi, [rbp-64]
    mov rdx, 64
    mov rax, 1          ; sys_write
    syscall

    cmp rax, 64
    jne .error_close

    ; Write Program header (56 bytes)
    mov rdi, r15
    lea rsi, [rbp-120]
    mov rdx, 56
    mov rax, 1
    syscall

    cmp rax, 56
    jne .error_close

    ; Write code
    mov rdi, r15
    mov rsi, [rbp-272]  ; code buffer
    mov rdx, [rbp-280]  ; code size
    mov rax, 1
    syscall

    cmp rax, [rbp-280]
    jne .error_close

    ; Close file
    mov rdi, r15
    mov rax, 3          ; sys_close
    syscall

    ; Make executable (chmod +x)
    mov rdi, [rbp-264]  ; filename
    mov rsi, 0x1ED      ; permissions 0755 (rwxr-xr-x)
    mov rax, 90         ; sys_chmod
    syscall

    ; Success
    xor rax, rax
    jmp .done

.error_close:
    mov rdi, r15
    mov rax, 3
    syscall

.error:
    mov rax, -1

.done:
    add rsp, 256
    pop rbp
    ret
