# Diskusi Pengembangan Bahasa Native AI

Halo! Sesuai instruksi, saya telah mengambil `Brainlib` dari repositori `morphx84_64`, memperluasnya dengan instruksi kernel, dan kini mulai membangun layer utilitas "Seer".

## Update Fase 4: Migrasi ke JSON & Visi `.brain`

Untuk meningkatkan interoperabilitas dan kemudahan parsing, definisi instruksi `Brainlib` telah dimigrasikan dari format teks `.vzoel` ke format terstruktur **JSON**.

### Struktur Data Baru (JSON)

Setiap file di `Brainlib/*.json` kini berisi array objek instruksi dengan skema berikut:

```json
[
  {
    "mnemonic": "add.r64.r64",
    "encoding": {
      "rex": "W",
      "opcode": "0x01",
      "modrm": "reg,reg"
    },
    "hint": "Tambah register dengan register (+)"
  }
]
```

Atau untuk macro kernel:

```json
[
  {
    "mnemonic": "sys.net.socket",
    "kind": "macro",
    "action": "mov rax, 41; syscall",
    "hint": "Syscall SOCKET..."
  }
]
```

### Visi Format `.brain`

Tujuan jangka panjang adalah menciptakan format biner/teks padat `.brain` yang lebih efisien daripada JSON, namun tetap fleksibel.

**Rencana Transisi:**
1.  **Tahap Bootstrap (Sekarang):** Gunakan JSON. Mudah dibaca manusia dan mudah diparsing oleh tool eksternal (Python/JS) saat kita membangun toolchain awal.
2.  **Tahap Native:** Saat parser `.fox` (self-hosted) sudah siap, ia akan membaca definisi JSON ini untuk memahami instruksi mesinnya sendiri.
3.  **Tahap Optimasi:** Parser `.fox` dapat mengonversi JSON ini menjadi format `.brain` (misal: serialisasi biner terkompresi) agar loading time compiler menjadi sangat cepat.

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
    *   **`seer/print/std.vzoel`**: Wrapper output standar.
        *   `seer.print.text`: Mencetak string dengan menghitung panjang secara manual (loop) dan memanggil syscall `write`. Transparan.
        *   `seer.print.raw`: Mencetak buffer byte mentah.
        *   `seer.print.nl`: Mencetak newline.
    *   **`seer/emit/core.vzoel`**: Utilitas code generation.
        *   Menyediakan instruksi untuk menulis byte/opcode ke buffer memori (`emit.byte`, `emit.op.ret`, dll).
        *   Ini adalah cikal bakal untuk *self-hosted parser/compiler*.
    *   *Catatan*: File `seer` masih menggunakan ekstensi `.vzoel` karena berisi *kode program* (implementasi), bukan definisi instruksi murni. Ke depan mungkin perlu distandarkan ekstensi untuk *source code* (misal `.fox` atau `.seer`).

Saya siap menunggu arahan Anda selanjutnya untuk mewujudkan visi Native AI ini!
