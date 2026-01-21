# Diskusi Pengembangan Bahasa Native AI

Halo! Sesuai instruksi, saya telah mengambil `Brainlib` dari repositori `morphx84_64`, memperluasnya dengan instruksi kernel, dan kini mulai membangun layer utilitas "Seer".

## Update Fase 5: Standarisasi Ekstensi File

Untuk memperjelas struktur proyek dan memisahkan antara "Definisi Instruksi" dengan "Kode Program", kita telah menetapkan konvensi baru:

### Konvensi Ekstensi File

1.  **`.json` (Definisi ISA - Brainlib)**
    *   Digunakan untuk mendefinisikan instruksi mesin, opcode, operand, dan metadata AI Hint.
    *   Lokasi: `Brainlib/*.json`.
    *   Contoh:
        ```json
        { "mnemonic": "add.r64.r64", "encoding": {...}, "hint": "..." }
        ```

2.  **`.fox` (Source Code - Seer & Userland)**
    *   Digunakan untuk menulis logika program, wrapper, dan utilitas.
    *   Lokasi: `seer/**/*.fox` dan kode user nanti.
    *   Gaya Penulisan: Eksplisit dengan penutup blok yang jelas (mirip referensi `parser.fox`).
    *   Contoh Struktur:
        ```asm
        fungsi nama_fungsi
            ; ... instruksi ...
            jika_sama
                ; ... blok ...
            tutup_jika
            loop
                ; ... blok ...
            tutup_loop
            ret
        tutup_fungsi
        ```

### Filosofi "Seer" (Sang Pelihat)

`seer` bukan library standar biasa yang penuh abstraksi ("magic"). Sebaliknya, `seer` adalah kumpulan wrapper transparan yang menjembatani instruksi dasar dengan kebutuhan fungsional.

**Prinsip Utama: "Apa yang dijalankan = Apa yang ditulis"**
-   Tidak ada fungsi `printf` yang melakukan formatting kompleks di balik layar.
-   Tidak ada alokasi memori implisit yang menyebabkan *heisenbug*.
-   Kode bersifat eksplisit dan jujur.

### Struktur Direktori

1.  **`Brainlib/` (The Core)**
    *   Berisi definisi instruksi dasar x86-64 dan macro syscall kernel dalam format **JSON**.
    *   Dibekukan sebagai *Ground Truth*.

2.  **`seer/` (The Utility Layer)**
    *   **`seer/print/std.fox`**: Wrapper output standar.
        *   `seer.print.text`: Mencetak string dengan menghitung panjang secara manual (loop) dan memanggil syscall `write`. Transparan.
        *   `seer.print.raw`: Mencetak buffer byte mentah.
        *   `seer.print.nl`: Mencetak newline.
    *   **`seer/emit/core.fox`**: Utilitas code generation.
        *   Menyediakan instruksi untuk menulis byte/opcode ke buffer memori (`emit.byte`, `emit.op.ret`, dll).
        *   Ini adalah cikal bakal untuk *self-hosted parser/compiler*.

Saya siap menunggu arahan Anda selanjutnya untuk mewujudkan visi Native AI ini!
