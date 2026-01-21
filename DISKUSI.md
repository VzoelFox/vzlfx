# Diskusi Pengembangan Bahasa Native AI

Halo! Sesuai instruksi, saya telah mengambil `Brainlib` dari repositori `morphx84_64`, memperluasnya dengan instruksi kernel, dan kini mulai membangun layer utilitas "Seer".

## Update Fase 6: Refactoring Struktur Direktori

Untuk menjaga kebersihan arsitektur, kita telah memisahkan antara fungsi utilitas umum dengan fungsi inti "Seer" (Output/Debug).

### Struktur Direktori Baru

1.  **`Brainlib/` (The Core ISA)**
    *   `*.json`: Definisi instruksi mesin (aritmatika, kernel, grafik, dll).
    *   *Dibekukan sebagai Ground Truth.*

2.  **`seer/` (The Vision Layer - Output/Debug)**
    *   `print/std.fox`: Wrapper syscall output standar (Text, Int, Hex).
    *   `emit/core.fox`: Utilitas code generation (emit byte/opcode).
    *   `tools/linter.fox`: Error reporting dengan warna dan pointer.
    *   `data/messages.json`: Database pesan error netral.

3.  **`utils/` (General Utilities)**
    *   `string/compare.fox`: Fungsi perbandingan string (strcmp manual).
    *   `string/utf.fox`: Decoder UTF-8 manual (1-4 byte support).

4.  **`boot/` (System Boot)**
    *   `loader.fox`: Native Loader yang menggunakan syscall `mmap` dan `read` untuk memuat file sumber dan melakukan tokenisasi awal tanpa Python.

5.  **`externlib/`**
    *   Wadah untuk library eksternal masa depan.

### Toolchain

*   **`bootstrap.sh`**: Script bash+python sementara yang berfungsi sebagai compiler. Ia menggabungkan file `.fox`, melakukan substitusi macro sederhana, dan mengekstrak string literal ke segmen data `.asm` sebelum dikompilasi oleh FASM.

Saya siap menunggu arahan Anda selanjutnya!
