; Morph Seer String Comparison
; [AI_HINT: Primitif perbandingan string manual byte-per-byte]

seer.string.equals:
    ; [AI_HINT: Bandingkan dua string null-terminated]
    ; Input: rdi (str1), rsi (str2)
    ; Output: rax (1 jika sama, 0 jika beda)

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

seer.string.equals_len:
    ; [AI_HINT: Bandingkan string dengan panjang tertentu]
    ; Input: rdi (str1), rsi (str2), rdx (len)
    ; Output: rax (1 jika sama, 0 jika beda)

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
