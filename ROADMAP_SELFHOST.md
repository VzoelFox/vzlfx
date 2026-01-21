# Roadmap Self-Host & Code Honesty

Dokumen ini menjelaskan rencana transisi proyek menuju lingkungan pengembangan yang sepenuhnya mandiri (self-hosted) dan "jujur" (code honesty).

## Filosofi "Code Honesty"
"Code Honesty" berarti kode yang dieksekusi oleh mesin haruslah representasi langsung dari kode yang ditulis oleh programmer, tanpa lapisan abstraksi tersembunyi ("magic") yang dilakukan oleh alat bantu eksternal yang tidak bisa kita audit atau reproduksi secara native.

Sebelumnya, `bootstrap.sh` menggunakan Python untuk:
1.  Mengekstrak string literal secara regex dan memindahkannya ke segmen data.
2.  Menerjemahkan sintaks `fungsi`, `loop`, dan `jika` menjadi label Assembly.

Pendekatan ini menciptakan ketergantungan pada Python dan menyembunyikan kompleksitas manajemen memori string yang seharusnya ditangani oleh Compiler/Loader kita sendiri.

## Rencana Transisi

### Phase 1: Penghapusan Python & Adopsi FASM (Saat Ini)
Kita akan menghapus `bootstrap.sh` berbasis Python dan beralih ke toolchain sederhana berbasis **Bash Murni** dan **FASM (Flat Assembler)**.

1.  **Format Source Code:**
    *   File `.fox` (yang sebelumnya sintaks hibrida) akan dikonversi menjadi `.asm` (standar FASM x86-64).
    *   Kita tidak lagi menggunakan keyword `fungsi`, `loop`, atau `jika_sama`. Kita akan menulis label dan instruksi jump secara eksplisit.
    *   **String:** String literal tidak akan ditulis di tengah instruksi (contoh: `mov rdi, "Halo"`). String harus didefinisikan secara manual di section `.data` atau dibuat mekanismenya secara runtime.

2.  **Brainlib Integration:**
    *   Konstanta dan definisi sistem (seperti warna terminal, syscall) tetap berada di folder `Brainlib/` dalam format JSON.
    *   Script Bash (`gen_consts.sh`) akan mem-parsing JSON ini secara sederhana (menggunakan `grep`/`sed`/`awk`) menjadi file header Assembly (`brainlib.inc`) yang bisa di-include oleh FASM.

3.  **Build System:**
    *   `build.sh` (Bash) akan menggantikan `bootstrap.sh`. Tugasnya hanya menyiapkan include path dan memanggil `fasm`.

### Phase 2: Native Self-Hosting (Masa Depan)
Setelah codebase stabil dalam format Assembly:
1.  Kita akan mengembangkan **Native Parser** (sudah dimulai di `utils/json` dan `loader`) yang mampu membaca definisi `Brainlib` secara langsung.
2.  Kita akan membangun **Native Compiler** yang bisa membaca source code tingkat tinggi (pengganti `.fox` masa depan) dan menghasilkan machine code atau assembly tanpa bantuan Python.

## Struktur Direktori Baru
*   `tools/`: Script bantu (bash) untuk build dan generate konstanta.
*   `boot/`: Kode bootloader/loader (format .asm).
*   `utils/`: Pustaka native (format .asm).
*   `Brainlib/`: Definisi ISA dan konstanta (JSON).
