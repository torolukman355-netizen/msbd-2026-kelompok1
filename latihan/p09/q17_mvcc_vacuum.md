## 1. Manfaat MVCC

MVCC (_Multi-Version Concurrency Control_) merupakan mekanisme PostgreSQL yang memungkinkan transaksi membaca versi data yang konsisten tanpa selalu menunggu transaksi lain yang sedang melakukan perubahan.

Manfaat MVCC meliputi:

1. **Meningkatkan konkurensi:** operasi baca dan tulis dapat berjalan bersamaan dengan lebih efisien.
2. **Menjaga konsistensi pembacaan:** transaksi membaca data sesuai snapshot yang berlaku.
3. **Mengurangi konflik:** pembaca biasa tidak selalu memerlukan kunci yang menghalangi penulis.
4. **Mendukung isolasi transaksi:** PostgreSQL mengatur versi baris yang dapat dilihat oleh setiap transaksi berdasarkan tingkat isolasinya.

## 2. Mengapa VACUUM Diperlukan?

Pada PostgreSQL, operasi `UPDATE` dan `DELETE` tidak selalu langsung menghapus versi baris lama dari penyimpanan. Versi tersebut mungkin masih diperlukan oleh transaksi yang sedang berjalan.

Setelah versi lama tidak lagi diperlukan, versi tersebut dapat menjadi _dead tuples_. PostgreSQL menggunakan proses `VACUUM` untuk membersihkan versi baris yang sudah tidak diperlukan agar ruangnya dapat digunakan kembali.

Manfaat `VACUUM` meliputi:

1. Membersihkan _dead tuples_.
2. Menyediakan ruang penyimpanan agar dapat digunakan kembali oleh PostgreSQL.
3. Membantu mengendalikan pembengkakan ukuran tabel.
4. Memelihara informasi visibilitas baris dan membantu mencegah masalah akibat transaksi ID yang terus bertambah.

Perintah `VACUUM` biasa tidak selalu mengembalikan ruang kosong ke sistem operasi. Ruang tersebut umumnya tersedia untuk digunakan kembali oleh PostgreSQL.

## 3. Pengujian Statistik Tabel

Jalankan SQL berikut untuk melihat perkiraan jumlah baris aktif dan _dead tuples_ pada tabel `lab9.rekening`.

```sql
SELECT
    schemaname,
    relname AS nama_tabel,
    n_live_tup AS perkiraan_baris_aktif,
    n_dead_tup AS perkiraan_dead_tuples,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'lab9'
  AND relname = 'rekening';
```

Untuk menjalankan pemeliharaan tabel secara manual, gunakan perintah berikut di luar blok transaksi eksplisit:

```sql
VACUUM (VERBOSE, ANALYZE) lab9.rekening;
```

Setelah itu, jalankan kembali query statistik untuk memeriksa hasil pemeliharaan. Statistik tersebut bersifat perkiraan sehingga tidak selalu langsung mencerminkan kondisi tabel secara akurat.
