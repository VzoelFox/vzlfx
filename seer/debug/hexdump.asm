; Morph Seer Debug (Memory Visualization)
; [AI_HINT: Visualisasi raw memory untuk debugging jujur]

seer.debug.hexdump:
    ; [AI_HINT: Cetak hexdump dari buffer memori]
    ; Input: rdi (pointer buffer), rsi (length)

    push rdi
    push rsi
    push rdx
    push rcx
    push rax
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp, rsp

    mov r12, rdi    ; r12 = Base Address
    mov r13, rsi    ; r13 = Total Length
    xor r14, r14    ; r14 = Current Offset (0 to Length)

    ; Buffer untuk ASCII (16 chars + null)
    sub rsp, 20
    mov r15, rsp    ; r15 = ASCII Buffer Ptr

    .line_loop:
        cmp r14, r13
        jge .done

        ; Print Address
        mov rdi, r12
        add rdi, r14
        call seer.print.hex ; Print Address 64-bit

        ; Separator ": "
        push 0x203A ; ": "
        mov rsi, rsp
        mov rdx, 2
        mov rdi, 1
        mov rax, 1
        syscall
        pop rax

        xor rbx, rbx ; rbx = Line Byte Counter (0-15)

        .byte_loop:
            ; Cek bounds
            mov rax, r14
            add rax, rbx
            cmp rax, r13
            jge .padding

            ; Load byte
            mov rdi, r12
            add rdi, rax
            movzx eax, byte [rdi]

            ; Save to ASCII buffer
            mov dl, al
            cmp dl, 32
            jl .dot
            cmp dl, 126
            jg .dot
            jmp .store_char
            .dot:
            mov dl, '.'
            .store_char:
            mov [r15+rbx], dl

            ; Print Hex Byte (Manual 2 chars)
            push rbx

            ; High Nybble
            mov rdx, rax
            shr rdx, 4
            and rdx, 0xF
            cmp dl, 9
            jg .hi_alpha
            add dl, '0'
            jmp .hi_print
            .hi_alpha:
            add dl, 'A'-10
            .hi_print:
            ; Print directly to stdout? too many syscalls.
            ; Buffer small string?
            ; Let's push to stack and print 3 chars "HH "

            mov rcx, rdx ; Save high char

            ; Low Nybble
            mov rdx, rax
            and rdx, 0xF
            cmp dl, 9
            jg .lo_alpha
            add dl, '0'
            jmp .lo_print
            .lo_alpha:
            add dl, 'A'-10
            .lo_print:
            ; rcx = high, rdx = low

            ; Stack: "XY " (Low, High, Space) -> Space=0x20
            ; Memory order: High, Low, Space
            ; Reg: Space(MSB)..High(LSB) ? No.
            ; We want memory: [High] [Low] [Space]
            ; Value: (0x20 << 16) | (Low << 8) | High
            shl rdx, 8
            or rcx, rdx
            or rcx, 0x200000 ; Space at 3rd byte

            push rcx ; 8 bytes, valid content in low 3 bytes
            mov rsi, rsp
            mov rdx, 3
            mov rdi, 1
            mov rax, 1
            syscall
            pop rcx

            pop rbx
            inc rbx
            cmp rbx, 16
            jl .byte_loop
            jmp .print_ascii

        .padding:
            ; Print 3 spaces per missing byte
            push rbx
            push 0x202020 ; "   "
            mov rsi, rsp
            mov rdx, 3
            mov rdi, 1
            mov rax, 1
            syscall
            pop rax

            ; Fill ASCII buffer with space (or dot?) -> Space
            mov byte [r15+rbx], ' '

            pop rbx
            inc rbx
            cmp rbx, 16
            jl .byte_loop

        .print_ascii:
            ; Separator " |"
            push 0x7C20 ; " |"
            mov rsi, rsp
            mov rdx, 2
            mov rdi, 1
            mov rax, 1
            syscall
            pop rax

            ; Print ASCII Buffer
            mov rsi, r15
            mov rdx, 16
            mov rdi, 1
            mov rax, 1
            syscall

            ; Separator "|"
            push 0x7C ; "|"
            mov rsi, rsp
            mov rdx, 1
            mov rdi, 1
            mov rax, 1
            syscall
            pop rax

            call seer.print.nl

            add r14, 16
            jmp .line_loop

    .done:
    mov rsp, rbp
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rax
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret
