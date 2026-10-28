**Q28. Fungsi `SIReadLock` dalam pemeriksaan serialisasi**

Pada isolation level `SERIALIZABLE`, PostgreSQL memakai Serializable Snapshot Isolation (SSI). Ketika transaksi membaca sebuah baris atau rentang data, PostgreSQL dapat mencatat *predicate lock* yang terlihat di `pg_locks` sebagai `SIReadLock`. Lock ini mencatat bahwa transaksi telah membaca data tersebut; ia bukan row lock eksklusif biasa.

Saat transaksi lain menulis data yang cocok dengan pembacaan itu, PostgreSQL membangun informasi ketergantungan baca-tulis. Jika gabungan ketergantungan transaksi dapat menghasilkan hasil yang tidak mungkin terjadi pada eksekusi serial—seperti write skew pada Q27—PostgreSQL membatalkan salah satu transaksi dengan `SQLSTATE 40001`.

`SIReadLock` tidak menghalangi pembaca atau penulis lain. Karena itu, `SERIALIZABLE` bukan berarti setiap `SELECT` mengunci semua baris seperti `SELECT ... FOR UPDATE`.

| Aspek | `SELECT` pada `SERIALIZABLE` | `SELECT ... FOR UPDATE` |
| --- | --- | --- |
| Tujuan | Mendeteksi konflik serialisasi melalui SSI | Memperoleh row lock eksplisit untuk baris terpilih |
| Memblokir `UPDATE`/lock konflik? | Tidak | Ya, sampai transaksi selesai |
| Jika ada konflik | Salah satu transaksi dapat gagal dengan `40001` | Transaksi lain menunggu, atau gagal cepat dengan `NOWAIT` |
| Cakupan | Dapat berupa tuple, halaman, atau relasi/rentang predicate | Baris yang benar-benar dipilih |

PostgreSQL dapat menaikkan cakupan *predicate lock* dari tuple ke halaman atau relasi ketika diperlukan untuk efisiensi. Ini tetap mekanisme pencatatan konflik, bukan penguncian semua data untuk mencegah transaksi lain berjalan.
