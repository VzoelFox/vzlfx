# Diskusi Pengembangan Bahasa Native AI

Halo! Sesuai instruksi, saya telah mengambil `Brainlib` dari repositori `morphx84_64` dan memperluasnya dengan definisi instruksi kernel.

## Update Fase 2: Kernel & Network Mapping

Saya telah menambahkan modul baru `Brainlib/kernel.vzoel` dan memperbarui `Brainlib/io.vzoel`.

### 1. Konsep Macro Instruction (`kernel.vzoel`)
Berbeda dengan instruksi aritmatika yang memetakan langsung ke opcode mesin (1-to-1), instruksi kernel (seperti Network) membutuhkan urutan instruksi (sekuensial). Oleh karena itu, saya memperkenalkan format `kind=macro`:

```asm
sys.net.socket      kind=macro action={mov rax, 41; syscall}  ; [AI_HINT: Syscall SOCKET...]
```

**Kenapa ini penting?**
-   **Native Understanding**: AI tidak perlu menghapal "angka ajaib" (41 = socket). AI cukup menggunakan `sys.net.socket` dan secara semantik paham itu adalah operasi pembuatan socket.
-   **Transparansi**: Di level assembly, instruksi ini tetap akan diterjemahkan menjadi kode native yang efisien (`mov` + `syscall`), tanpa overhead *runtime library* yang berat.

### 2. Cakupan Instruksi Kernel
Saya telah memetakan instruksi dasar untuk:
-   **File System**: `read`, `write`, `open`, `close`, `lseek`, dll.
-   **Network**: `socket`, `connect`, `bind`, `listen`, `accept`, `sendto`, `recvfrom`.
-   **Memory**: `mmap`, `brk` (dasar alokasi memori).
-   **Time**: `nanosleep`.

Sesuai arahan, manajemen proses (`fork`, `exec`) **di-skip** dulu.

### 3. Hardware I/O (`io.vzoel`)
Saya juga menambahkan instruksi `in` dan `out` (Port I/O) di `io.vzoel`. Meskipun jarang digunakan di aplikasi level user (Ring 3), ini vital jika tujuan akhirnya adalah "Native AI" yang mungkin berjalan di level kernel atau bare-metal.

## Rencana Selanjutnya

Dengan fondasi `Brainlib` yang kini mencakup komputasi (aritmatika/logika) dan interaksi sistem (kernel), kita memiliki basis yang kuat.

Pertanyaan untuk langkah berikutnya:
1.  **Struktur Data Native**: Bagaimana kita ingin mendefinisikan struktur data kompleks (seperti `sockaddr` untuk network) dalam format `.vzoel`? Apakah AI perlu tahu layout memori struct tersebut secara eksplisit?
2.  **Compiler Prototype**: Apakah sudah saatnya kita mencoba membuat parser sederhana untuk memvalidasi file `.vzoel` ini?

Saya siap menunggu arahan Anda selanjutnya!
