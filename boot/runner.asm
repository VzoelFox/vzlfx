; Morph Native Runner
; [AI_HINT: Engine eksekusi native yang melakukan JIT/Interpretasi instruksi]

runner_start:
    ; Input: rdi (pointer to payload), rsi (payload size)
    push rbp
    mov rbp, rsp

    ; Simpan argumen di stack (callee-saved r12, r13 aman untuk loop nanti)
    push rdi        ; Payload Ptr
    push rsi        ; Payload Size

    ; 1. Print Banner
    mov rdi, msg_runner_start
    call seer.print.text
    call seer.print.nl

    ; 2. Alokasi JIT Memory (RWX)
    ; sys_mmap(0, 65536, PROT_READ|WRITE|EXEC, MAP_PRIVATE|ANONYMOUS, -1, 0)
    ; PROT_READ=1, PROT_WRITE=2, PROT_EXEC=4 -> 7
    ; Ukuran 64KB
    mov rdi, 0
    mov rsi, 65536
    mov rdx, 7      ; RWX
    mov r10, 34     ; MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1
    mov r9, 0
    mov rax, 9      ; SYS_MMAP
    syscall

    cmp rax, 0
    jle .jit_fail

    mov rbx, rax    ; rbx = JIT Buffer Address

    ; Print JIT Address
    mov rdi, msg_jit_alloc
    call seer.print.text
    mov rdi, rbx
    call seer.print.hex
    call seer.print.nl

    ; 3. Info Payload
    mov rdi, msg_payload_info
    call seer.print.text

    ; Ambil size dari stack (tanpa pop)
    mov rdi, [rsp]
    call seer.print.int
    call seer.print.nl

    ; --- Main Execution Loop (Stub) ---
    ; Di sini nanti kita akan membaca token dari Payload (di [rsp+8])
    ; dan mengenerate kode ke JIT Buffer (di rbx)

    ; Untuk sekarang, selesai.

    pop rsi ; Restore Size
    pop rdi ; Restore Ptr

    leave
    ret

    .jit_fail:
        mov rdi, msg_jit_fail
        call seer.print.text
        call seer.print.nl
        mov rax, 60
        mov rdi, 1
        syscall

; Data local (Read-Only karena di segment executable)
msg_runner_start db "Runner: Control transferred to Native Runner.", 0
msg_jit_alloc    db "Runner: JIT Buffer allocated at ", 0
msg_jit_fail     db "Runner: FATAL - Failed to allocate executable memory.", 0
msg_payload_info db "Runner: Payload Size bytes: ", 0
