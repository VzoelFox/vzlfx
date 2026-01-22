; Morph Native Runner
; [AI_HINT: Engine eksekusi native yang melakukan JIT/Interpretasi instruksi]

runner_start:
    ; Input: rdi (pointer to payload), rsi (payload size)
    push rbp
    mov rbp, rsp

    ; Simpan argumen di stack (callee-saved r12, r13 aman untuk loop nanti)
    push rdi        ; Payload Ptr (Local var at rbp-8)
    push rsi        ; Payload Size (Local var at rbp-16)

    ; 1. Print Banner
    mov rdi, msg_runner_start
    call seer.print.text
    call seer.print.nl

    ; 2. Alokasi JIT Memory (RWX)
    ; sys_mmap(0, 65536, PROT_READ|WRITE|EXEC, MAP_PRIVATE|ANONYMOUS, -1, 0)
    ; PROT_READ=1, PROT_WRITE=2, PROT_EXEC=4 -> 7
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

    mov rbx, rax    ; rbx = JIT Buffer Address (Current Write Ptr)
    mov r15, rax    ; r15 = JIT Start Address (To Call later)

    ; Print JIT Address
    mov rdi, msg_jit_alloc
    call seer.print.text
    mov rdi, rbx
    call seer.print.hex
    call seer.print.nl

    ; 3. Setup Tokenizer Loop
    ; r12 = Current Source Ptr
    ; r13 = End Source Ptr
    mov r12, [rbp-8]    ; Payload Ptr
    mov r13, r12
    add r13, [rbp-16]   ; End Ptr

    ; --- Main Compile Loop ---
    .compile_loop:
        cmp r12, r13
        jge .compile_done

        ; Get Next Token
        ; Output: rdi (Token Ptr), rsi (Token Len), r12 updated
        call runner_get_token

        cmp rsi, 0
        je .compile_loop ; Skip empty/whitespace

        ; Lookup Token in Registry
        ; Input: rdi (Token Ptr), rsi (Token Len)
        ; Output: rax (Registry Entry Ptr or 0)
        call runner_lookup_token

        cmp rax, 0
        je .unknown_instruction

        ; Found!
        ; rax points to: [Ptr Mnemonic] [Ptr Opcode] [Len Opcode] [Ptr Hint]

        ; Print Hint (Linter)
        push rax    ; Save Reg Ptr
        mov rdi, msg_hint_prefix
        call seer.print.text

        mov rdi, [rax+24] ; Hint Ptr
        call seer.print.text
        call seer.print.nl
        pop rax     ; Restore Reg Ptr

        ; Emit Opcode to JIT Buffer
        mov rsi, [rax+8]    ; Opcode Source Ptr
        mov rcx, [rax+16]   ; Opcode Len (Value from DQ)

        ; Copy bytes: [rsi] -> [rbx], len rcx
        ; Stack top has regs, but we use cld/rep movsb which uses rsi/rdi/rcx
        push rsi
        push rdi

        mov rdi, rbx        ; Dest (JIT)
        ; rsi is Src
        ; rcx is count
        cld
        rep movsb

        mov rbx, rdi        ; Update JIT Ptr

        pop rdi
        pop rsi

        jmp .compile_loop

    .unknown_instruction:
        mov rdi, msg_error_unknown
        call seer.print.text
        ; Print the token
        ; rdi/rsi from get_token are still valid? Yes, rdi points to payload buffer
        ; but we need to pass length to print.raw
        ; rdi is already token ptr, rsi is token len from get_token
        call seer.print.raw
        call seer.print.nl
        jmp .exit_fatal

    .compile_done:

    ; 4. Finalize JIT
    ; Add 'ret' (0xC3) to safely return to Runner
    mov byte [rbx], 0xC3
    inc rbx

    ; 5. Execute JIT
    mov rdi, msg_executing
    call seer.print.text
    call seer.print.nl

    call r15    ; Call Generated Code

    mov rdi, msg_finished
    call seer.print.text
    call seer.print.nl

    leave
    ret

    .jit_fail:
        mov rdi, msg_jit_fail
        call seer.print.text
        call seer.print.nl
        jmp .exit_fatal

    .exit_fatal:
        mov rax, 60
        mov rdi, 1
        syscall


; --- Helper: Get Token ---
; Scans for next whitespace-delimited word starting at r12
; Updates r12 to after the token
; Returns: rdi (Start Ptr), rsi (Length)
runner_get_token:
    ; Skip whitespace
    .skip_ws:
        cmp r12, r13
        jge .eof
        mov al, [r12]
        cmp al, 32 ; space
        je .is_ws
        cmp al, 9  ; tab
        je .is_ws
        cmp al, 10 ; newline
        je .is_ws
        jmp .found_start

        .is_ws:
        inc r12
        jmp .skip_ws

    .found_start:
    mov rdi, r12 ; Start Ptr

    ; Find end
    .find_end:
        cmp r12, r13
        jge .found_end
        mov al, [r12]
        cmp al, 32
        je .found_end
        cmp al, 9
        je .found_end
        cmp al, 10
        je .found_end
        inc r12
        jmp .find_end

    .found_end:
    mov rsi, r12
    sub rsi, rdi ; Length
    ret

    .eof:
    mov rsi, 0
    ret

; --- Helper: Lookup Token ---
; Input: rdi (Token Ptr), rsi (Token Len)
; Output: rax (Entry Ptr or 0)
runner_lookup_token:
    push rbx
    push rcx
    push rdx

    mov rbx, instruction_registry ; Start of table

    .lookup_loop:
        mov rdx, [rbx] ; Ptr to Mnemonic String
        cmp rdx, 0     ; Check terminator
        je .not_found

        ; Compare string (Token vs Mnemonic)
        ; seer.string.equals expects null-terminated in rdi/rsi
        ; But our Token is NOT null terminated (it's in buffer)
        ; Mnemonic IS null terminated.
        ; Use seer.string.equals_len?
        ; Input: rsi (buffer), rdi (string), rdx (len of buffer)

        push rdi
        push rsi
        push rbx ; Save table ptr

        mov rdx, rsi        ; Length of Token
        mov rsi, rdi        ; Token Ptr (Buffer)
        mov rdi, [rbx]      ; Mnemonic Ptr (Null-term)

        ; We need to check if Mnemonic length matches Token length
        ; AND content matches.
        ; seer.string.equals_len logic: checks if buffer [rsi..rsi+rdx] matches [rdi..]
        call seer.string.equals_len

        pop rbx
        pop rsi ; Restore Token Len
        pop rdi ; Restore Token Ptr

        cmp rax, 1
        je .found

        add rbx, 32 ; Next Entry (4 qwords = 32 bytes)
        jmp .lookup_loop

    .not_found:
        mov rax, 0
        pop rdx
        pop rcx
        pop rbx
        ret

    .found:
        mov rax, rbx ; Return Entry Ptr
        pop rdx
        pop rcx
        pop rbx
        ret

; Data local (Read-Only karena di segment executable)
msg_runner_start db "Runner: Control transferred to Native Runner.", 0
msg_jit_alloc    db "Runner: JIT Buffer allocated at ", 0
msg_jit_fail     db "Runner: FATAL - Failed to allocate executable memory.", 0
msg_hint_prefix  db "Linter: ", 0
msg_error_unknown db "Error: Unknown instruction: ", 0
msg_executing    db "Runner: Executing JIT Code...", 0
msg_finished     db "Runner: Execution Finished.", 0
