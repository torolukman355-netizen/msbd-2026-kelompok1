# Q21 — Migrasi Berversi dan Rollback

## Migration 0041

- Expand: membuat tabel `harga_film` dengan constraint `EXCLUDE` untuk mencegah overlap range per film dan wilayah.
- Down: menghapus tabel `lab4.harga_film`.

## Migration 0042

- Expand: menambahkan trigger `film_dual_write` agar perubahan `rental_rate` bersamaan tercermin pada `harga_film`.
- Down: menghapus trigger dan fungsi sinkronisasi.

## Migration 0043

- Migrate: melakukan backfill data lama ke tabel `harga_film` dalam potongan 1000 film.
- Down: menghapus data yang dibuat pada backfill wilayah `ID`.

## Migration 0044

- Migrate: menjalankan verifikasi bahwa setiap film sudah punya harga `ID`.
- Down: no-op, karena ini hanya query validasi.

## Migration 0045

- Contract: membuat view fasad `lab4.film_lama` untuk menjaga kompatibilitas aplikasi lama.
- Down: menghapus view fasad.

## Migration 0046

- Contract: menghapus kolom `rental_rate` dari tabel `lab4.film`.
- Down: menambahkan kembali kolom `rental_rate` dengan tipe `numeric(4,2)`, tetapi nilai historis lama tidak dapat dipulihkan otomatis.

## Catatan rollback

Migration 0046 tidak dapat di-rollback secara penuh karena data lama sudah dihapus dari bentuk lama. Oleh karena itu, urutan yang benar adalah: verifikasi nol, view fasad stabil, lalu drop kolom saja setelah semua pembaca lama sudah aman.