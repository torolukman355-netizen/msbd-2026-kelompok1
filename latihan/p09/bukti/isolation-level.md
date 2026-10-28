Bukti Eksekusi Langkah 2 (Q6 - Q11)
Kendali Konkurensi dan Isolation Level

Q6: Non-repeatable read (READ COMMITTED)
Sesi A (BEGIN) membaca rekening 1, hasil: 1000000.
Sesi B (UPDATE tanpa BEGIN) mengubah rekening 1 menjadi 900000.
Sesi A (SELECT lagi) membaca rekening 1, hasil: 900000. 
Kesimpulan: Pada READ COMMITTED, pembacaan kedua dalam satu transaksi dapat berubah jika ada transaksi lain yang sudah COMMIT.

Q7: Perbandingan isolation (REPEATABLE READ)
Sesi A (BEGIN ISOLATION LEVEL REPEATABLE READ) membaca rekening 1, hasil: 1000000.
Sesi B (UPDATE) mengubah rekening 1 menjadi 800000.
Sesi A (SELECT lagi) membaca rekening 1, hasil: 1000000.
Kesimpulan: Pada REPEATABLE READ, transaksi mengunci snapshot data pada saat SELECT pertama, sehingga perubahan dari sesi lain tidak akan terlihat sampai transaksi ini COMMIT.

Q8: Phantom read
Tabel lab9.eksperimen dengan isi awal nilai (10, 20).
Pada READ COMMITTED: Sesi A menghitung nilai > 15 (hasil: 1). Sesi B memasukkan nilai 30. Sesi A menghitung lagi, hasilnya menjadi 2 baris. (Terjadi phantom read).
Pada REPEATABLE READ: Sesi A menghitung nilai > 15 (hasil: 2). Sesi B memasukkan nilai 40. Sesi A menghitung lagi, hasilnya tetap 2 baris.
Kesimpulan: PostgreSQL menggunakan MVCC yang secara ketat mencegah phantom read pada level REPEATABLE READ, tidak seperti database SQL standar lainnya yang masih memungkinkan phantom read di level ini.

Q9: Dirty read
Sesi A melakukan BEGIN dan mengubah saldo menjadi 50000 tanpa COMMIT.
Sesi B melakukan BEGIN ISOLATION LEVEL READ UNCOMMITTED dan membaca saldo. Hasilnya tetap nilai lama (1000000).
Kesimpulan: PostgreSQL secara internal tidak mengimplementasikan READ UNCOMMITTED. Jika diminta, PostgreSQL akan memperlakukannya sama persis seperti READ COMMITTED, sehingga Dirty Read tidak mungkin terjadi.

Q10: Lost update
Sesi A dan Sesi B membaca saldo awal rekening 2 (1000000).
Sesi A secara aplikasi menghitung saldo baru menjadi 900000, dan Sesi B menghitung saldo baru menjadi 950000.
Sesi A menjalankan UPDATE menjadi 900000.
Sesi B menjalankan UPDATE menjadi 950000 (Sesi B tertahan menunggu Sesi A).
Sesi A melakukan COMMIT. Sesi B otomatis lanjut dan menimpa baris tersebut, lalu COMMIT.
Hasil akhir saldo adalah 950000. Update dari Sesi A telah hilang (Lost Update).