; Morph Seer Linter (Error Reporting)
; [AI_HINT: Menampilkan pesan error dengan konteks visual (warna, panah)]

seer.linter.print_error:
    ; Input:
    ;   rdi = Code ID (pointer string, misal "E001")
    ;   rsi = Filename (pointer string)
    ;   rdx = Line Number (integer)
    ;   rcx = Column Number (integer)
    ;   r8  = Snippet Line (pointer string)

    push rbp
    mov rbp, rsp

    ; Simpan argumen di stack karena kita akan pakai register untuk print
    push rdi    ; [rbp-8]  Code ID
    push rsi    ; [rbp-16] Filename
    push rdx    ; [rbp-24] Line Number
    push rcx    ; [rbp-32] Column Number
    push r8     ; [rbp-40] Snippet

    ; 1. Header Error (Merah)
    mov rdi, ANSI_RED
    call seer.print.text

    mov rdi, .msg_error_open
    call seer.print.text

    ; Code ID
    mov rdi, [rbp-8]
    call seer.print.text

    mov rdi, .msg_error_close
    call seer.print.text

    mov rdi, ANSI_RESET
    call seer.print.text
    call seer.print.nl

    ; 2. Lokasi File
    mov rdi, .msg_arrow
    call seer.print.text

    mov rdi, [rbp-16] ; Filename
    call seer.print.text

    mov rdi, .msg_colon
    call seer.print.text

    ; Print Line Number
    mov rdi, [rbp-24]
    call seer.print.int

    mov rdi, .msg_colon
    call seer.print.text

    ; Print Column Number
    mov rdi, [rbp-32]
    call seer.print.int

    call seer.print.nl

    ; 3. Snippet Code
    mov rdi, .msg_pipe_empty
    call seer.print.text
    call seer.print.nl

    mov rdi, .msg_pipe
    call seer.print.text

    mov rdi, [rbp-40]  ; Snippet
    call seer.print.text
    call seer.print.nl

    ; 4. Pointer Panah (Kuning)
    mov rdi, .msg_pipe
    call seer.print.text

    mov rdi, ANSI_YELLOW
    call seer.print.text

    ; Print Spaces (sebanyak rcx/column - 1)
    mov rcx, [rbp-32]
    cmp rcx, 1
    jle .done_spaces
    dec rcx ; adjust for 0/1 index logic, or usually column is 1-based? Assuming 1-based.
            ; If col 1, 0 spaces.

    .space_loop:
        push rcx    ; Save loop counter (syscall clobbers rcx)
        mov rdi, 32 ; Space
        call seer.print.char
        pop rcx     ; Restore loop counter
        loop .space_loop

    .done_spaces:
    mov rdi, .msg_pointer
    call seer.print.text

    mov rdi, ANSI_RESET
    call seer.print.text
    call seer.print.nl

    ; Restore Stack
    leave
    ret

    .msg_error_open  db "ERROR [", 0
    .msg_error_close db "]: ", 0
    .msg_arrow       db "  --> ", 0
    .msg_colon       db ":", 0
    .msg_pipe        db "   | ", 0
    .msg_pipe_empty  db "   |", 0
    .msg_pointer     db "^ Di sini", 0
