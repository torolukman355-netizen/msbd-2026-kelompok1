# Latihan P09 — Transaksi dan Kendali Konkurensi

Eksperimen ini menguji ACID, isolation level, MVCC, row lock, deadlock,
`SERIALIZABLE`, dan retry pada skema **`lab9`**. Jangan mengubah tabel Pagila
di skema `public` maupun skema latihan lain.

## Struktur pengumpulan

```text
latihan/p09/
├── README.md
├── laporan.md
├── q00_setup.sql
├── q01_q32_transaksi.sql
└── bukti/
    ├── isolation-level.md
    ├── deadlock.md
    ├── serializable.md
    └── hasil-sesi.txt
```

Berkas `q01_q32_transaksi.sql` adalah **panduan yang dibaca dan disalin per
blok**, bukan skrip yang dijalankan sekaligus. Tanda `[A]`, `[B]`, dan `[O]`
masing-masing berarti Sesi A, Sesi B, dan sesi pengamat opsional. Urutan blok
tidak boleh ditukar.

## Prasyarat dan setup

Jalankan Docker dari akar repositori, lalu jalankan setup sekali:

```sh
docker compose up -d
docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 \
  -f /dev/stdin < latihan/p09/q00_setup.sql
```

`q00_setup.sql` mengembalikan seluruh data `lab9` ke kondisi awal dan
menampilkan versi PostgreSQL serta konfigurasi timeout. Salin keluaran itu ke
bagian **Kondisi uji** pada `laporan.md`.

Kemudian buka dua terminal interaktif dari akar repositori:

```sh
docker compose exec -it postgres psql -U msbd -d pagila
```

Di Sesi A dan Sesi B jalankan:

```sql
\set VERBOSITY verbose
SELECT pg_backend_pid();
```

PID kedua sesi harus berbeda. Simpan seluruh keluaran, termasuk `BEGIN`,
`UPDATE 1`, `COMMIT`, `ROLLBACK`, dan `ERROR`, di `bukti/hasil-sesi.txt`.
Pengaturan verbosity diperlukan agar SQLSTATE terlihat.

## Aturan pelaksanaan

- Untuk Q23 dan Q25, timeout hanya dipasang dengan `SET LOCAL` di transaksi
  percobaan; jangan mengubah timeout global server.
- Setelah galat di dalam transaksi, jalankan `ROLLBACK` sebelum eksperimen
  berikutnya. Perintah lanjutan pada transaksi yang gagal akan menghasilkan
  SQLSTATE `25P02`.
- Jalankan pemulihan yang ditulis di akhir setiap skenario, atau ulangi
  `q00_setup.sql` sebelum beralih ke skenario berikutnya.
- Galat yang memang diharapkan: `23514` (Q5), `55P03` (Q23/Q25), `40P01`
  (Q20), dan `40001` (Q27). Jangan menyamarkan galat tersebut.
- Q20 dan Q27 tidak menjamin sesi yang dibatalkan sama pada setiap eksekusi;
  catat sesi dan titik galat yang benar-benar terjadi.

## Verifikasi hasil

Isi tiga berkas Markdown dalam `bukti/` dengan urutan antar-sesi dan tempel
keluaran mentah ke `hasil-sesi.txt`. Placeholder sengaja tidak berisi keluaran
yang direkayasa: bukti harus berasal dari server PostgreSQL yang digunakan
kelompok. Setelah semua eksperimen selesai, perbarui `laporan.md` pada bagian
yang bertanda `[isi dari hasil eksekusi]`.

> Berkas per-soal lama di folder ini dipertahankan sebagai riwayat pekerjaan.
> Berkas yang digunakan untuk pengumpulan sesuai struktur di atas adalah
> `q00_setup.sql`, `q01_q32_transaksi.sql`, `laporan.md`, dan `bukti/`.
| cmd: perintah `psql` keluar sendiri setelah satu perintah | `-T` atau `<` masih terpakai; untuk latihan ini `psql` harus interaktif (`-it`) |
