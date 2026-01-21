; Morph Seer UTF-8 & Unicode Support
; [AI_HINT: Penanganan teks multi-byte penuh untuk menggantikan ketergantungan Python]

seer.string.utf8_decode:
    ; Input: rdi (pointer ke byte stream)
    ; Output:
    ;   rax = Unicode Code Point (32-bit integer)
    ;   rcx = Byte length (1-4)
    ;   Jika invalid, rax = 0xFFFD (Replacement Character), rcx = 1

    push rbx
    push rdx

    xor rax, rax
    mov al, [rdi]

    ; 1 Byte (ASCII): 0xxxxxxx
    test al, 0x80
    jz .utf1

    ; 2 Bytes: 110xxxxx 10xxxxxx
    mov bl, al
    and bl, 0xE0
    cmp bl, 0xC0
    je .utf2

    ; 3 Bytes: 1110xxxx 10xxxxxx 10xxxxxx
    mov bl, al
    and bl, 0xF0
    cmp bl, 0xE0
    je .utf3

    ; 4 Bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    mov bl, al
    and bl, 0xF8
    cmp bl, 0xF0
    je .utf4

    ; Invalid Sequence
    jmp .utf_err

    .utf1:
        mov rcx, 1
        ; rax sudah berisi byte (0-127)
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

        ; Byte 2
        mov bl, [rdi+1]
        test bl, 0x80
        jz .utf_err
        and bl, 0x3F
        shl ebx, 6
        or eax, ebx

        ; Byte 3
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

        ; Byte 2
        mov bl, [rdi+1]
        and bl, 0x3F
        shl ebx, 12
        or eax, ebx

        ; Byte 3
        mov bl, [rdi+2]
        and bl, 0x3F
        shl ebx, 6
        or eax, ebx

        ; Byte 4
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
    ; Input: rdi (pointer string)
    ; Output: rdi (pointer ke karakter berikutnya)
    ; Memanggil decode untuk dapat panjang, lalu memajukan pointer

    push rax
    push rcx

    call seer.string.utf8_decode
    ; rcx berisi panjang byte
    add rdi, rcx

    pop rcx
    pop rax
    ret
